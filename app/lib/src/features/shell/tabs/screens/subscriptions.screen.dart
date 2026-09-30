import 'package:flutter/material.dart';

import 'package:app/src/core/api/mon_peya_error.ui.dart';
import 'package:app/src/core/auth/module.auth.dart';
import 'package:app/src/core/modules/widgets/module.icon.dart';
import 'package:app/src/core/session/mon_peya.session.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/core/api/models/mon_peya_subscription.models.dart';
import 'package:app/src/core/api/mon_peya_api.exception.dart';
import 'package:app/src/features/shell/widgets/main_bottom_navigation_bar.widget.dart';
import 'package:app/src/features/subscriptions/config/subscription_services.config.dart';
import 'package:app/src/features/subscriptions/presentation/screens/service_abonnement.screen.dart';
import 'package:app/src/features/subscriptions/presentation/widgets/deplafonnement_prompt.dart';
import 'package:app/src/features/subscriptions/presentation/widgets/subscription_paywall.widget.dart';
import 'package:app/src/integration/adapters/mon_peya_backend.adapter.dart';

/// My Subs tab — theme-adaptive paywall for Mon Peya access.
class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  bool _loading = true;
  bool _loadFailed = false;
  bool _sessionActive = false;
  bool _subscribing = false;
  String _role = 'CLIENT';
  List<MonPeyaSubscription> _activeSubs = const [];
  List<MonPeyaPlan> _plans = const [];
  String? _selectedPlanCode;

  @override
  void initState() {
    super.initState();
    MonPeyaSession.instance.addListener(_onSessionChanged);
    _load();
  }

  @override
  void dispose() {
    MonPeyaSession.instance.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });

    final sessionActive = await ModuleAuth.hasActiveSessionOrToken();
    final role = sessionActive
        ? await AuthStore.serviceSubscriptionRole()
        : 'CLIENT';

    try {
      // Plans are public — guests can browse before connecting.
      final plans = await monPeyaListPlans(role: role);
      if (!mounted) return;
      final paywallPlans = _pickPaywallPlans(plans);

      var activeSubs = const <MonPeyaSubscription>[];
      if (sessionActive) {
        try {
          final subs = await monPeyaMySubscriptions(role: role);
          activeSubs = subs.where((s) => s.isActive).toList();
        } catch (_) {}
      }

      setState(() {
        _sessionActive = sessionActive;
        _role = role;
        _activeSubs = activeSubs;
        _plans = paywallPlans;
        _selectedPlanCode = paywallPlans
                .where((p) => p.isDefault)
                .firstOrNull
                ?.code ??
            paywallPlans
                .where((p) => p.billingPeriod.toUpperCase() == 'YEARLY')
                .firstOrNull
                ?.code ??
            paywallPlans.firstOrNull?.code;
        _loading = false;
      });
    } on MonPeyaApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sessionActive = sessionActive;
        _role = role;
        _loadFailed = true;
        _loading = false;
      });
      await showMonPeyaErrorDialog(context, e, onRetry: _load);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sessionActive = sessionActive;
        _role = role;
        _loadFailed = true;
        _loading = false;
      });
      await showMonPeyaErrorDialog(context, e, onRetry: _load);
    }
  }

  /// Prefer grouped YEARLY+MONTHLY; else any YEARLY+MONTHLY; else first plans.
  static List<MonPeyaPlan> _pickPaywallPlans(List<MonPeyaPlan> all) {
    final grouped = all.where((p) => p.isGrouped).toList();
    final pool = grouped.isNotEmpty ? grouped : all;
    final yearly = pool
        .where((p) => p.billingPeriod.toUpperCase() == 'YEARLY')
        .firstOrNull;
    final monthly = pool
        .where((p) => p.billingPeriod.toUpperCase() == 'MONTHLY')
        .firstOrNull;
    if (yearly != null && monthly != null) return [yearly, monthly];
    if (pool.isEmpty) return const [];
    return pool.take(2).toList();
  }

  Future<void> _subscribe() async {
    if (!_sessionActive) {
      final ok = await ModuleAuth.ensureRegistered(context);
      if (!ok || !mounted) return;
      await _load();
      if (!_sessionActive || !mounted) return;
    }

    final code = _selectedPlanCode;
    if (code == null || _subscribing) return;

    final canSubscribe = await ensureDeplafonneOrAsk(context, role: _role);
    if (!canSubscribe || !mounted) return;

    final plan = _plans.where((p) => p.code == code).firstOrNull;
    final moduleCode =
        plan?.moduleCodes.length == 1 ? plan!.moduleCodes.first : null;

    if (moduleCode == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Choisissez un service ci-dessous pour vous abonner '
            '(Billetterie, Immo, Leadway…).',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _openServicesSheet();
      return;
    }

    setState(() => _subscribing = true);
    try {
      final sub = await monPeyaSubscribe(
        planCode: code,
        moduleCode: moduleCode,
        role: _role,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sub.planName != null
                ? 'Abonnement actif : ${sub.planName}'
                : 'Abonnement activé',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _load();
    } on MonPeyaApiException catch (e) {
      if (!mounted) return;
      final msg = monPeyaUserMessage(e).toLowerCase();
      if (msg.contains('déplafonn') || msg.contains('deplafonn')) {
        await ensureDeplafonneOrAsk(context, role: _role);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(monPeyaUserMessage(e)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _subscribing = false);
    }
  }

  Future<void> _openServicesSheet() async {
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.62,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (_, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Services individuels',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Parcourez les modules — connexion requise seulement pour souscrire.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                for (final service in SubscriptionServices.catalog) ...[
                  _ServiceSheetTile(
                    service: service,
                    isActive: _activeSubs.any(
                      (s) =>
                          s.moduleCode?.toLowerCase() ==
                          service.moduleCode.toLowerCase(),
                    ),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      if (!mounted) return;
                      final role = _sessionActive
                          ? await AuthStore.serviceSubscriptionRole()
                          : 'CLIENT';
                      if (!mounted) return;
                      final changed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (_) => ServiceAbonnementScreen(
                            moduleCode: service.moduleCode,
                            role: role,
                            serviceTitle: service.title,
                          ),
                        ),
                      );
                      if (changed == true) _load();
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        );
      },
    );
  }

  String get _ctaLabel => _subscribing ? 'Souscription…' : 'S’abonner';

  VoidCallback? get _ctaAction {
    if (_subscribing) return null;
    if (_sessionActive && _selectedPlanCode == null) return null;
    return _subscribe;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final navBottom = MainBottomNavigationBar.contentBottomPadding(context);

    if (_loadFailed && !_loading) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(32, 32, 32, navBottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Abonnements indisponibles',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Impossible de charger les formules pour le moment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _load,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SubscriptionPaywall(
      loading: _loading,
      showBackButton: false,
      bottomInset: navBottom,
      plans: _plans,
      selectedPlanCode: _selectedPlanCode,
      onSelectPlan: (code) => setState(() => _selectedPlanCode = code),
      onSubscribe: _ctaAction,
      subscribeLabel: _ctaLabel,
      subscribeEnabled: _ctaAction != null,
      onMaybeLater: _openServicesSheet,
      maybeLaterLabel: 'Services individuels',
      headline: 'Abonnez-vous',
      subtitle: 'Accès illimité.\nTous vos services Mon Peya.',
      footnote:
          'Billetterie, Immo, Leadway et plus — un abonnement pour tout débloquer.',
      activeBanner: _activeSubs.isEmpty
          ? null
          : _PaywallNotice(
              text: _activeSubs.length == 1
                  ? 'Actif : ${_activeSubs.first.planName ?? _activeSubs.first.planCode ?? 'Abonnement'}'
                  : '${_activeSubs.length} abonnements actifs',
            ),
    );
  }
}

class _PaywallNotice extends StatelessWidget {
  const _PaywallNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.primaryContainer.withValues(alpha: 0.55);
    final fg = cs.onPrimaryContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: fg,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }
}

class _ServiceSheetTile extends StatelessWidget {
  const _ServiceSheetTile({
    required this.service,
    required this.isActive,
    required this.onTap,
  });

  final SubscriptionServiceEntry service;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? cs.primary.withValues(alpha: 0.55)
                  : cs.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                alignment: Alignment.center,
                child: ModuleIcon(
                  iconKey: service.iconKey,
                  moduleKey: service.moduleKey,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.subtitle,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                isActive ? 'Actif' : 'Voir',
                style: TextStyle(
                  color: isActive ? cs.primary : cs.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
