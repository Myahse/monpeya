import 'package:flutter/material.dart';

import 'package:app/src/core/api/models/mon_peya_subscription.models.dart';
import 'package:app/src/core/api/mon_peya_api.exception.dart';
import 'package:app/src/core/api/mon_peya_error.ui.dart';
import 'package:app/src/core/auth/module.auth.dart';
import 'package:app/src/features/subscriptions/presentation/widgets/deplafonnement_prompt.dart';
import 'package:app/src/features/subscriptions/presentation/widgets/subscription_paywall.widget.dart';
import 'package:app/src/integration/adapters/mon_peya_backend.adapter.dart';

/// Subscribe to a grouped Mon Peya plan.
class PackageAbonnementScreen extends StatefulWidget {
  const PackageAbonnementScreen({
    super.key,
    this.role = 'CLIENT',
    this.initialPlanCode,
  });

  final String role;
  final String? initialPlanCode;

  static const routeName = '/package-abonnement';

  @override
  State<PackageAbonnementScreen> createState() =>
      _PackageAbonnementScreenState();
}

class _PackageAbonnementScreenState extends State<PackageAbonnementScreen> {
  bool _loading = true;
  bool _loadFailed = false;
  bool _subscribing = false;
  List<MonPeyaPlan> _plans = const [];
  String? _selectedPlanCode;

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
      final allPlans = await monPeyaListPlans(role: widget.role);
      final grouped = allPlans.where((p) => p.isGrouped).toList();

      if (!mounted) return;
      setState(() {
        _plans = grouped;
        _selectedPlanCode = widget.initialPlanCode ??
            grouped.where((p) => p.isDefault).firstOrNull?.code ??
            grouped.firstOrNull?.code;
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

    final plan = _plans.where((p) => p.code == code).firstOrNull;
    final moduleCode =
        plan?.moduleCodes.length == 1 ? plan!.moduleCodes.first : null;

    setState(() => _subscribing = true);
    try {
      final sub = await monPeyaSubscribe(
        planCode: code,
        moduleCode: moduleCode,
        role: widget.role,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sub.planName != null
                ? 'Pack actif : ${sub.planName}'
                : 'Abonnement groupé activé',
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
                  'Packs indisponibles',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Impossible de charger les formules groupées.',
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
      subtitle: 'Accès illimité.\nTous vos services Mon Peya.',
      footnote:
          'Un seul abonnement pour plusieurs modules — Billetterie, Immo, Leadway et plus.',
    );
  }
}
