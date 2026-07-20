import 'package:flutter/material.dart';

import 'package:billetterie/billetterie.dart';

import 'package:app/src/core/api/models/mon_peya_subscription.models.dart';
import 'package:app/src/core/api/mon_peya_api.exception.dart';
import 'package:app/src/core/auth/module.auth.dart';
import 'package:app/src/integration/adapters/mon_peya_backend.adapter.dart';

/// Choose a Mon Peya service plan (single vs grouped) and subscribe.
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
  bool _requestingDeplaf = false;
  String? _error;
  List<MonPeyaPlan> _plans = const [];
  String? _selectedPlanCode;
  MonPeyaSubscription? _active;
  bool _isDeplafonne = true;
  MonPeyaSubscriptionRequest? _openDeplafRequest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _needsDeplafonnement =>
      widget.role.toUpperCase() == 'CLIENT' && !_isDeplafonne;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ok = await ModuleAuth.ensureRegistered(context);
      if (!ok || !mounted) return;

      final plans = await monPeyaListPlans(
        moduleCode: widget.moduleCode,
        role: widget.role,
      );
      List<MonPeyaSubscription> mine = const [];
      try {
        mine = await monPeyaMySubscriptions(
          moduleCode: widget.moduleCode,
          role: widget.role,
        );
      } catch (_) {}

      var isDeplafonne = true;
      MonPeyaSubscriptionRequest? openDeplaf;
      try {
        final me = await monPeyaMe();
        isDeplafonne = me.isDeplafonne == true;
      } catch (_) {}
      if (!isDeplafonne) {
        try {
          final reqs = await monPeyaMySubscriptionRequests();
          openDeplaf = reqs
              .where((r) => r.isDeplafonnement && r.isOpen)
              .firstOrNull;
        } catch (_) {}
      }

      if (!mounted) return;
      final active = mine.where((s) => s.isActive).firstOrNull;
      setState(() {
        _plans = plans;
        _active = active;
        _isDeplafonne = isDeplafonne;
        _openDeplafRequest = openDeplaf;
        _selectedPlanCode = active?.planCode ??
            plans.where((p) => p.isDefault).firstOrNull?.code ??
            plans.firstOrNull?.code;
        _loading = false;
      });
    } on MonPeyaApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _requestDeplafonnement() async {
    if (_requestingDeplaf) return;
    setState(() => _requestingDeplaf = true);
    try {
      final req = await monPeyaRequestDeplafonnement();
      if (!mounted) return;
      setState(() => _openDeplafRequest = req);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Demande de déplafonnement envoyée. Vous pourrez vous abonner après validation.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on MonPeyaApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _requestingDeplaf = false);
    }
  }

  Future<void> _subscribe() async {
    final code = _selectedPlanCode;
    if (code == null || _subscribing) return;
    if (_needsDeplafonnement) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Compte non déplafonné — envoyez d’abord une demande de déplafonnement.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _subscribing = true);
    try {
      final sub = await monPeyaSubscribe(
        planCode: code,
        moduleCode: widget.moduleCode,
        role: widget.role,
      );
      // Keep local billetterie client flag in sync for offline fallback.
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
      final msg = e.message.toLowerCase();
      if (msg.contains('déplafonn') || msg.contains('deplafonn')) {
        setState(() => _isDeplafonne = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Demander',
              onPressed: _requestDeplafonnement,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _subscribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          'Abonnement ${widget.serviceTitle}',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        children: [
                          Text(
                            'Choisissez votre formule d’accès au service',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ce tarif est l’abonnement Mon Peya (accès au module). '
                            'Il est indépendant du prix des billets dans Billetterie.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Individuel = Billetterie seule. '
                            'Groupé = Billetterie + Immo (prêt pour plus tard).',
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                          if (_active != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cs.outlineVariant),
                              ),
                              child: Text(
                                'Actif : ${_active!.planName ?? _active!.planCode ?? 'Abonnement'}'
                                '${_active!.endAt != null ? ' · jusqu’au ${_active!.endAt}' : ''}',
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                          ],
                          if (_needsDeplafonnement) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cs.tertiaryContainer.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cs.outlineVariant),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _openDeplafRequest != null
                                        ? 'Demande de déplafonnement en cours'
                                        : 'Compte non déplafonné',
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _openDeplafRequest != null
                                        ? 'Statut : ${_openDeplafRequest!.status}. '
                                            'Vous pourrez vous abonner après validation.'
                                        : 'Avant de souscrire, une demande de déplafonnement '
                                            'doit être validée (lié à Peya).',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (_plans.isEmpty)
                            Text(
                              'Aucune formule disponible pour le moment.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            )
                          else
                            ..._plans.map((plan) {
                              final selected = plan.code == _selectedPlanCode;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _PlanCard(
                                  plan: plan,
                                  selected: selected,
                                  onTap: () => setState(
                                    () => _selectedPlanCode = plan.code,
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          border: Border(
                            top: BorderSide(
                              color: cs.outlineVariant.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        child: FilledButton(
                          onPressed: _needsDeplafonnement
                              ? (_openDeplafRequest != null ||
                                      _requestingDeplaf
                                  ? null
                                  : _requestDeplafonnement)
                              : (_selectedPlanCode == null || _subscribing
                                  ? null
                                  : _subscribe),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            _needsDeplafonnement
                                ? (_requestingDeplaf
                                    ? 'Envoi…'
                                    : _openDeplafRequest != null
                                        ? 'Demande en cours…'
                                        : 'Demander le déplafonnement')
                                : (_subscribing
                                    ? 'Souscription…'
                                    : 'S’abonner'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final MonPeyaPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final kindLabel = plan.isGrouped ? 'Groupé' : 'Individuel';
    final priceLabel =
        '${plan.price.toStringAsFixed(0)} ${plan.currency} / ${_periodLabel(plan.billingPeriod)}';

    return Material(
      color: selected
          ? cs.primaryContainer.withValues(alpha: 0.55)
          : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primary.withValues(alpha: 0.14)
                          : cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      kindLabel,
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected ? cs.primary : cs.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? cs.primary : cs.outline,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                plan.name,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              if (plan.description != null &&
                  plan.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  plan.description!,
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                priceLabel,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
              if (plan.moduleCodes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: plan.moduleCodes
                      .map(
                        (m) => Chip(
                          label: Text(
                            m,
                            style: TextStyle(color: cs.onSecondaryContainer),
                          ),
                          backgroundColor: cs.secondaryContainer,
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _periodLabel(String period) {
    switch (period.toUpperCase()) {
      case 'YEARLY':
        return 'an';
      case 'ONCE':
        return 'une fois';
      case 'NONE':
        return '—';
      default:
        return 'mois';
    }
  }
}
