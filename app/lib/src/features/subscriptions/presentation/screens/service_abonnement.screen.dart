import 'package:flutter/material.dart';

import 'package:billetterie/billetterie.dart';

import 'package:app/src/core/api/models/mon_peya_subscription.models.dart';
import 'package:app/src/core/api/mon_peya_api.exception.dart';
import 'package:app/src/core/api/mon_peya_error.ui.dart';
import 'package:app/src/core/auth/module.auth.dart';
import 'package:app/src/features/subscriptions/config/subscription_services.config.dart';
import 'package:app/src/features/subscriptions/presentation/widgets/deplafonnement_prompt.dart';
import 'package:app/src/features/subscriptions/presentation/widgets/subscription_paywall.widget.dart';
import 'package:app/src/integration/adapters/mon_peya_backend.adapter.dart';

/// Choose a Mon Peya service plan and subscribe.
class ServiceAbonnementScreen extends StatefulWidget {
  const ServiceAbonnementScreen({
    super.key,
    this.moduleCode = 'billetterie',
    this.role = 'CLIENT',
    this.serviceTitle = 'Billetterie',
  });

  final String moduleCode;
  final String role;
  final String serviceTitle;

  static const routeName = '/service-abonnement';

  @override
  State<ServiceAbonnementScreen> createState() =>
      _ServiceAbonnementScreenState();
}

class _ServiceAbonnementScreenState extends State<ServiceAbonnementScreen> {
  bool _loading = true;
  bool _subscribing = false;
  bool _loadFailed = false;
  List<MonPeyaPlan> _plans = const [];
  String? _selectedPlanCode;
  MonPeyaSubscription? _active;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final sessionActive = await ModuleAuth.hasActiveSessionOrToken();
      final plans = await monPeyaListPlans(
        moduleCode: widget.moduleCode,
        role: widget.role,
      );
      final singlePlans = plans.where((p) => p.isSingle).toList();

      List<MonPeyaSubscription> mine = const [];
      if (sessionActive) {
        try {
          mine = await monPeyaMySubscriptions(
            moduleCode: widget.moduleCode,
            role: widget.role,
          );
        } catch (_) {}
      }

      if (!mounted) return;
      final active = mine.where((s) => s.isActive).firstOrNull;
      setState(() {
        _plans = singlePlans;
        _active = active;
        _selectedPlanCode = active?.planCode ??
            singlePlans.where((p) => p.isDefault).firstOrNull?.code ??
            singlePlans.firstOrNull?.code;
        _loadFailed = false;
        _loading = false;
      });
    } on MonPeyaApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _loading = false;
      });
      await showMonPeyaErrorDialog(context, e, onRetry: _load);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _loading = false;
      });
      await showMonPeyaErrorDialog(context, e, onRetry: _load);
    }
  }

  Future<void> _subscribe() async {
    final code = _selectedPlanCode;
    if (code == null || _subscribing) return;

    final ok = await ModuleAuth.ensureRegistered(context);
    if (!ok || !mounted) return;

    final canSubscribe =
        await ensureDeplafonneOrAsk(context, role: widget.role);
    if (!canSubscribe || !mounted) return;

    setState(() => _subscribing = true);
    try {
      final sub = await monPeyaSubscribe(
        planCode: code,
        moduleCode: widget.moduleCode,
        role: widget.role,
      );
      if (widget.moduleCode == 'billetterie') {
        try {
          final store = TransportProfileStore();
          await store.requestClientSubscribe();
          await store.activateClient();
        } catch (_) {}
      }
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
      Navigator.of(context).pop(true);
    } on MonPeyaApiException catch (e) {
      if (!mounted) return;
      final msg = monPeyaUserMessage(e).toLowerCase();
      if (msg.contains('déplafonn') || msg.contains('deplafonn')) {
        await ensureDeplafonneOrAsk(context, role: widget.role);
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

  @override
  Widget build(BuildContext context) {
    if (_loadFailed && !_loading) {
      final cs = Theme.of(context).colorScheme;
      return Scaffold(
        backgroundColor: cs.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
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
                  'Formules indisponibles',
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
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(
                    'Retour',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final moduleLabel = SubscriptionServices.moduleLabel(widget.moduleCode);
    final cs = Theme.of(context).colorScheme;

    return SubscriptionPaywall(
      loading: _loading,
      plans: _plans,
      selectedPlanCode: _selectedPlanCode,
      onSelectPlan: (code) => setState(() => _selectedPlanCode = code),
      onSubscribe: (_selectedPlanCode == null || _subscribing) ? null : _subscribe,
      onMaybeLater: () => Navigator.of(context).maybePop(),
      subscribeLabel: _subscribing ? 'Souscription…' : 'S’abonner',
      subscribeEnabled: _selectedPlanCode != null && !_subscribing,
      headline: 'Abonnez-vous',
      subtitle:
          'Accès illimité à ${widget.serviceTitle}.\nNouveau contenu, chaque jour.',
      footnote:
          'Accédez à $moduleLabel sans limite — tarif Mon Peya indépendant des achats dans le service.',
      activeBanner: _active == null
          ? null
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Text(
                'Actif : ${_active!.planName ?? _active!.planCode ?? 'Abonnement'}'
                '${_active!.endAt != null ? ' · jusqu’au ${_active!.endAt}' : ''}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
    );
  }
}
