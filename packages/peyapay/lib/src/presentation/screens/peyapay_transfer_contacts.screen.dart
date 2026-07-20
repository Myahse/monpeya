import 'package:flutter/material.dart';

import 'package:peyapay/src/core/utils/peyapay_device_contacts.util.dart';
import 'package:peyapay/src/core/utils/peyapay_transfer.util.dart';
import 'package:peyapay/src/data/models/peyapay_scanned_qr.model.dart';
import 'package:peyapay/src/data/services/peyapay_crypto.service.dart';
import 'package:peyapay/src/presentation/screens/peyapay_qr_scan.screen.dart';
import 'package:peyapay/src/presentation/screens/peyapay_transfer.screen.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_draggable_bottom_sheet.widget.dart';

class PeyapayTransferContactsScreen extends StatefulWidget {
  const PeyapayTransferContactsScreen({super.key});

  @override
  State<PeyapayTransferContactsScreen> createState() => _PeyapayTransferContactsScreenState();
}

class _PeyapayTransferContactsScreenState extends State<PeyapayTransferContactsScreen> {
  final _searchCtrl = TextEditingController();
  bool _loading = false;
  bool _verifying = false;
  bool _permissionDenied = false;
  String? _error;
  List<({String name, String phone})> _contacts = const [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  List<({String name, String phone})> _visibleContacts(String query) {
    if (query.isEmpty) return _contacts;
    return _contacts
        .where(
          (c) =>
              c.name.toLowerCase().contains(query) ||
              c.phone.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  Future<void> _showNotPeyaPayModal({
    required String name,
    required String phone,
  }) {
    final displayName = name.trim().isEmpty ? phone : name.trim();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final ink = isDark ? cs.onSurface : const Color(0xFF111827);
        final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280);

        return PeyapayDraggableBottomSheet(
          onDismiss: () => Navigator.of(ctx).maybePop(),
          heightFactor: 0.42,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF006D56).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 32,
                    color: Color(0xFF006D56),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pas de compte PeyaPay',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ink),
              ),
              const SizedBox(height: 8),
              Text(
                '$displayName ($phone) n’a pas encore de compte PeyaPay. '
                'Vous ne pouvez transférer qu’à un numéro enregistré.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: muted, height: 1.35),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF006D56),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.of(ctx).maybePop(),
                  child: const Text('Compris', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openTransferIfWallet({
    required String name,
    required String phone,
    String? recipientClientCode,
    String? recipientUserType,
  }) async {
    if (_verifying) return;

    // Close search/manual keyboard before verifying or opening amount screen.
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    final digits = normalizePeyapayPhone(phone);
    if (digits.length != 10) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro invalide (10 chiffres attendus)')),
      );
      return;
    }

    setState(() => _verifying = true);
    try {
      final isWallet = await peyapayIsWalletPhone(digits);
      if (!mounted) return;
      if (!isWallet) {
        await _showNotPeyaPayModal(name: name, phone: digits);
        return;
      }

      // Let the IME finish closing so it does not carry over onto the amount screen.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;

      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => PeyapayTransferScreen(
            recipientName: name,
            recipientPhone: digits,
            recipientClientCode: recipientClientCode,
            recipientUserType: recipientUserType,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _openQr() async {
    final scanned = await Navigator.of(context, rootNavigator: true).push<PeyapayScannedQrData>(
      MaterialPageRoute<PeyapayScannedQrData>(
        builder: (_) => const PeyapayQrScanScreen(),
      ),
    );

    if (!mounted || scanned == null) return;

    await _openTransferIfWallet(
      name: scanned.recipientLabel,
      phone: scanned.clientCodeKey,
      recipientClientCode: scanned.clientCodeKey,
      recipientUserType: scanned.userTypeKey,
    );
  }

  Future<void> _openManualContact() async {
    final res = await Navigator.of(context, rootNavigator: true).push<({String name, String phone})>(
      MaterialPageRoute<({String name, String phone})>(
        builder: (_) => const _PeyapayManualRecipientScreen(),
      ),
    );

    if (!mounted || res == null) return;
    await _openTransferIfWallet(name: res.name, phone: res.phone);
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _permissionDenied = false;
      _error = null;
    });

    try {
      final deviceContacts = await peyapayReadDeviceContacts();
      if (!mounted) return;

      if (deviceContacts.isEmpty) {
        setState(() {
          _contacts = const [];
          _loading = false;
          _permissionDenied = true;
        });
        return;
      }

      setState(() {
        _contacts = deviceContacts;
        _loading = false;
        _permissionDenied = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? cs.surface : const Color(0xFFFFFFFF);
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);
    final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280);
    final border = isDark ? cs.outlineVariant : const Color(0xFFE5E7EB);

    final q = _searchCtrl.text.trim().toLowerCase();
    final visibleContacts = _visibleContacts(q);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Icon(Icons.chevron_left_rounded, size: 26, color: ink),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Transfert',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Actualiser les contacts',
                        onPressed: _loading || _verifying ? null : _loadContacts,
                        icon: Icon(Icons.refresh_rounded, color: ink),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? cs.surfaceContainerHighest : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 20, color: muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink),
                            decoration: InputDecoration(
                              hintText: 'Rechercher un contact',
                              hintStyle: TextStyle(color: muted),
                              border: InputBorder.none,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            foregroundColor: ink,
                          ),
                          onPressed: _verifying ? null : _openQr,
                          icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                          label: const Text('Scanner QR', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF006D56),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _verifying ? null : _openManualContact,
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                          label: const Text('Nouveau', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _permissionDenied
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.contacts_outlined, size: 44, color: muted),
                              const SizedBox(height: 12),
                              Text(
                                'Autorisez l’accès aux contacts',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: ink),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Pour choisir un destinataire, nous avons besoin de vos contacts.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: FilledButton(
                                  onPressed: _loadContacts,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF006D56),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text('Autoriser', style: TextStyle(fontWeight: FontWeight.w900)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _error != null
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, size: 44, color: muted),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Impossible de charger les contacts',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: ink),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _error!,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: muted),
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: OutlinedButton(
                                      onPressed: _loadContacts,
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: border),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: Text('Réessayer', style: TextStyle(fontWeight: FontWeight.w900, color: ink)),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _loading && visibleContacts.isEmpty
                              ? Center(child: CircularProgressIndicator(color: muted))
                              : visibleContacts.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.people_outline, size: 44, color: muted),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Aucun contact',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: ink),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            q.isEmpty
                                                ? 'Votre carnet d’adresses est vide.'
                                                : 'Aucun contact ne correspond à votre recherche.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                      itemCount: visibleContacts.length,
                                      itemBuilder: (context, i) {
                                        final contact = visibleContacts[i];
                                        return InkWell(
                                          onTap: _verifying
                                              ? null
                                              : () => _openTransferIfWallet(
                                                    name: contact.name,
                                                    phone: contact.phone,
                                                  ),
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 10),
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: bg,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: border),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 42,
                                                  height: 42,
                                                  decoration: BoxDecoration(
                                                    color: isDark ? cs.surfaceContainerHighest : const Color(0xFFF3F4F6),
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    contact.name.isNotEmpty
                                                        ? contact.name.trim().substring(0, 1).toUpperCase()
                                                        : '?',
                                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: ink),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        contact.name,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w900,
                                                          color: ink,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        contact.phone,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w700,
                                                          color: muted,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(Icons.chevron_right, color: muted),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                ),
              ],
            ),
          ),
          if (_verifying)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.25),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF006D56)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PeyapayManualRecipientScreen extends StatefulWidget {
  const _PeyapayManualRecipientScreen();

  @override
  State<_PeyapayManualRecipientScreen> createState() => _PeyapayManualRecipientScreenState();
}

class _PeyapayManualRecipientScreenState extends State<_PeyapayManualRecipientScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? cs.surface : const Color(0xFFFFFFFF);
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);
    final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280);
    final border = isDark ? cs.outlineVariant : const Color(0xFFE5E7EB);

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final canGo = name.isNotEmpty && phone.isNotEmpty;

    void submit() async {
      if (!canGo) return;
      FocusManager.instance.primaryFocus?.unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!context.mounted) return;
      Navigator.of(context).pop((name: name, phone: phone));
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.chevron_left_rounded, size: 26, color: ink),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('Nouveau', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink),
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      labelStyle: TextStyle(color: muted, fontWeight: FontWeight.w700),
                      filled: true,
                      fillColor: isDark ? cs.surfaceContainerHighest : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF006D56))),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink),
                    decoration: InputDecoration(
                      labelText: 'Téléphone',
                      labelStyle: TextStyle(color: muted, fontWeight: FontWeight.w700),
                      filled: true,
                      fillColor: isDark ? cs.surfaceContainerHighest : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF006D56))),
                    ),
                    onSubmitted: (_) => submit(),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: canGo ? const Color(0xFF006D56) : const Color(0xFFB9D8CF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: !canGo ? null : submit,
                    child: const Text('Continuer', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
