import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import 'peyapay_transfer_screen.dart';

class PeyapayTransferContactsScreen extends StatefulWidget {
  const PeyapayTransferContactsScreen({super.key});

  @override
  State<PeyapayTransferContactsScreen> createState() => _PeyapayTransferContactsScreenState();
}

class _PeyapayTransferContactsScreenState extends State<PeyapayTransferContactsScreen> {
  final _searchCtrl = TextEditingController();
  bool _loading = true;
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

  Future<void> _openQr() async {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? cs.surface : const Color(0xFFFFFFFF);
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);
    final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280);
    final border = isDark ? cs.outlineVariant : const Color(0xFFE5E7EB);

    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_scanner_rounded, size: 42, color: ink),
              const SizedBox(height: 10),
              Text('Scanner un QR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink)),
              const SizedBox(height: 6),
              Text(
                'Le scanner QR sera branché ici.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF006D56),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openManualContact() async {
    final res = await Navigator.of(context, rootNavigator: true).push<({String name, String phone})>(
      MaterialPageRoute<({String name, String phone})>(
        builder: (_) => const _PeyapayManualRecipientScreen(),
      ),
    );

    if (!mounted || res == null) return;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => PeyapayTransferScreen(
          recipientName: res.name,
          recipientPhone: res.phone,
        ),
      ),
    );
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _permissionDenied = false;
      _error = null;
    });

    try {
      final ok = await FlutterContacts.requestPermission(readonly: true);
      if (!ok) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _permissionDenied = true;
        });
        return;
      }

      final raw = await FlutterContacts.getContacts(withProperties: true);
      final rows = <({String name, String phone})>[];

      for (final c in raw) {
        final name = (c.displayName).trim();
        if (name.isEmpty) continue;
        if (c.phones.isEmpty) continue;

        // Prefer the first phone number.
        final phone = (c.phones.first.number).trim();
        if (phone.isEmpty) continue;

        rows.add((name: name, phone: phone));
      }

      rows.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _contacts = rows;
        _loading = false;
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
    final filtered = q.isEmpty
        ? _contacts
        : _contacts
            .where((c) => c.name.toLowerCase().contains(q) || c.phone.toLowerCase().contains(q))
            .toList(growable: false);

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
                  Text('Transfert', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink)),
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
                      onPressed: _openQr,
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
                      onPressed: _openManualContact,
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: const Text('Nouveau', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: ink))
                  : _permissionDenied
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
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final c = filtered[i];
                                return InkWell(
                                  onTap: () {
                                    Navigator.of(context, rootNavigator: true).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => PeyapayTransferScreen(
                                          recipientName: c.name,
                                          recipientPhone: c.phone,
                                        ),
                                      ),
                                    );
                                  },
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
                                            c.name.isNotEmpty ? c.name.trim().substring(0, 1).toUpperCase() : '?',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: ink),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(c.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: ink)),
                                              const SizedBox(height: 4),
                                              Text(c.phone, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted)),
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
                    onPressed: !canGo ? null : () => Navigator.of(context).pop((name: name, phone: phone)),
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

