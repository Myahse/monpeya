import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/features/transport/models/transport_profile.model.dart';
import 'package:billetterie/src/features/transport/services/transport_profile.store.dart';

/// Profile-only flow: become conductor (merchant/partner) or request partner status.
class TransportConductorUpgradeScreen extends StatefulWidget {
  const TransportConductorUpgradeScreen({super.key, required this.initial});

  final TransportProfileState initial;

  @override
  State<TransportConductorUpgradeScreen> createState() =>
      _TransportConductorUpgradeScreenState();
}

class _TransportConductorUpgradeScreenState
    extends State<TransportConductorUpgradeScreen> {
  final _store = TransportProfileStore();

  late TransportProfileState _state;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _state = widget.initial;
  }

  bool get _canSubscribeAsConductor => _state.isPartnerOrMerchant;

  Future<void> _submitMerchantSubscribe() async {
    setState(() => _submitting = true);
    try {
      final next = await _store.requestConductorSubscribe();
      if (!mounted) return;
      Navigator.of(context).pop(next);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _requestPartner() async {
    setState(() => _submitting = true);
    try {
      final next = await _store.requestPartner();
      if (!mounted) return;
      Navigator.of(context).pop(next);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _debugActivatePartner() async {
    final next = await _store.activatePartner();
    if (!mounted) return;
    setState(() => _state = next);
  }

  Future<void> _debugActivateConductor() async {
    final next = await _store.activateConductor();
    if (!mounted) return;
    Navigator.of(context).pop(next);
  }

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: brand.bg,
      appBar: AppBar(
        backgroundColor: brand.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: brand.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Devenir conducteur',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: brand.text,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (_state.canUseAsConductor) ...[
            _InfoBlock(
              brand: brand,
              title: 'Espace conducteur actif',
              body:
                  'Vous pouvez publier des billets et basculer en mode conducteur depuis le profil.',
            ),
          ] else if (_state.hasConductorRequestPending) ...[
            _InfoBlock(
              brand: brand,
              title: 'Demande en cours',
              body: _state.requestNote ??
                  'Votre abonnement conducteur est en attente de validation.',
            ),
          ] else if (_canSubscribeAsConductor) ...[
            Text(
              _state.peyapayMerchant
                  ? 'Vous êtes marchand PeyaPay. Abonnez-vous au module conducteur pour publier des billets.'
                  : 'Votre statut partenaire est actif. Abonnez-vous au module conducteur pour publier des billets.',
              style: textTheme.bodyMedium?.copyWith(
                color: brand.muted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submitting ? null : _submitMerchantSubscribe,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.subscriptions_outlined),
              label: Text(
                _submitting ? 'Envoi…' : 'S’abonner comme conducteur',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: brand.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _debugActivateConductor,
                child: const Text('Debug: activer conducteur'),
              ),
            ],
          ] else if (_state.hasPartnerRequestPending) ...[
            _InfoBlock(
              brand: brand,
              title: 'Demande partenaire en cours',
              body: _state.requestNote ??
                  'Votre demande pour devenir partenaire est en attente de validation.',
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _debugActivatePartner,
                child: const Text('Debug: activer partenaire'),
              ),
            ],
          ] else ...[
            Text(
              'Pour devenir conducteur, vous devez d’abord être partenaire PeyaPay. '
              'Envoyez une demande ; les pièces d’identité se gèrent dans Documents.',
              style: textTheme.bodyMedium?.copyWith(
                color: brand.muted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submitting ? null : _requestPartner,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.handshake_outlined),
              label: Text(
                _submitting
                    ? 'Envoi…'
                    : 'Demander à devenir partenaire',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: brand.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.brand,
    required this.title,
    required this.body,
  });

  final BilletterieBrand brand;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brand.ticketBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: brand.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: textTheme.bodyMedium?.copyWith(
              color: brand.muted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
