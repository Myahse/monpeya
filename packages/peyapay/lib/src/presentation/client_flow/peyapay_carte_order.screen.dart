import 'package:flutter/material.dart';

import 'package:peyapay/src/core/host/peyapay_host.bridge.dart';
import 'package:peyapay/src/core/utils/formatters.util.dart';
import 'package:peyapay/src/data/models/peyapay_api.exception.dart';
import 'package:peyapay/src/data/models/peyapay_carte.models.dart';
import 'package:peyapay/src/data/services/peyapay_carte_api.service.dart';

/// City + commune picker then card order via Mon Peya `/v1/carte/buy`.
class PeyapayCarteOrderScreen extends StatefulWidget {
  const PeyapayCarteOrderScreen({
    super.key,
    required this.montantCarte,
    this.onOrdered,
  });

  final int montantCarte;
  final VoidCallback? onOrdered;

  @override
  State<PeyapayCarteOrderScreen> createState() => _PeyapayCarteOrderScreenState();
}

class _PeyapayCarteOrderScreenState extends State<PeyapayCarteOrderScreen> {
  final _api = PeyapayHostBridge.carteApi ?? PeyapayCarteApiService();

  List<PeyapayCarteLocation> _villes = const [];
  List<PeyapayCarteLocation> _communes = const [];
  PeyapayCarteLocation? _ville;
  PeyapayCarteLocation? _commune;

  bool _loadingRef = true;
  bool _loadingCommunes = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVilles();
  }

  Future<void> _loadVilles() async {
    setState(() {
      _loadingRef = true;
      _error = null;
    });
    try {
      final villes = await _api.villes();
      if (!mounted) return;
      setState(() {
        _villes = villes;
        _loadingRef = false;
      });
    } on PeyapayApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loadingRef = false;
      });
    }
  }

  Future<void> _loadCommunes(int idWVille) async {
    setState(() {
      _loadingCommunes = true;
      _commune = null;
      _communes = const [];
      _error = null;
    });
    try {
      final communes = await _api.communes(idWVille: idWVille);
      if (!mounted) return;
      setState(() {
        _communes = communes;
        _loadingCommunes = false;
      });
    } on PeyapayApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loadingCommunes = false;
      });
    }
  }

  Future<void> _submit() async {
    final ville = _ville;
    final commune = _commune;
    if (ville == null || commune == null) {
      setState(() => _error = 'Choisissez une ville et une commune.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await _api.buy(
        idwVilleLivrer: ville.id,
        idwCommuneLivrer: commune.id,
      );

      if (!mounted) return;

      if (result.hasError) {
        if (result.code == '2000') {
          setState(() {
            _submitting = false;
            _error = result.message ??
                'KYC incomplet. Complétez votre profil puis réessayez.';
          });
          return;
        }
        setState(() {
          _submitting = false;
          _error = result.message ?? 'Commande impossible';
        });
        return;
      }

      widget.onOrdered?.call();
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.item?.message ?? 'Commande enregistrée — en attente de validation.',
          ),
        ),
      );
    } on PeyapayApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commander ma carte'),
      ),
      body: _loadingRef
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006D56),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prix de la carte',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${formatFrMoneySigned(widget.montantCarte)} XOF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Livraison',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<PeyapayCarteLocation>(
                  initialValue: _ville,
                  decoration: const InputDecoration(
                    labelText: 'Ville',
                    border: OutlineInputBorder(),
                  ),
                  items: _villes
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v.label),
                        ),
                      )
                      .toList(),
                  onChanged: _submitting
                      ? null
                      : (value) {
                          setState(() => _ville = value);
                          if (value != null) _loadCommunes(value.id);
                        },
                ),
                const SizedBox(height: 12),
                if (_loadingCommunes)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  DropdownButtonFormField<PeyapayCarteLocation>(
                    initialValue: _commune,
                    decoration: const InputDecoration(
                      labelText: 'Commune',
                      border: OutlineInputBorder(),
                    ),
                    items: _communes
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.label),
                          ),
                        )
                        .toList(),
                    onChanged: _submitting || _ville == null
                        ? null
                        : (value) => setState(() => _commune = value),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmer la commande'),
                ),
              ],
            ),
    );
  }
}
