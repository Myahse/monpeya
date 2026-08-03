import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:immo/src/core/constants/immo.brand.dart';

/// Read-only personal info — name + contact, styled like [RentalProfileScreen].
class PersonalInformationScreen extends StatelessWidget {
  const PersonalInformationScreen({
    super.key,
    this.displayName,
    this.phone,
  });

  final String? displayName;
  final String? phone;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    if (parts.isEmpty) return 'M';
    final list = parts.toList();
    if (list.length == 1) {
      final s = list.first;
      return s.length >= 2 ? s.substring(0, 2).toUpperCase() : s[0].toUpperCase();
    }
    return ('${list.first[0]}${list.last[0]}').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final textTheme = Theme.of(context).textTheme;
    final name = (displayName?.trim().isNotEmpty == true)
        ? displayName!.trim()
        : (phone?.trim().isNotEmpty == true ? phone!.trim() : 'Utilisateur');
    final contact = phone?.trim().isNotEmpty == true ? phone!.trim() : '—';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: b.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: b.bg,
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + 8,
            20,
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(Icons.arrow_back_rounded, color: b.text),
                ),
                Expanded(
                  child: Text(
                    'Informations personnelles',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: b.text,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: b.primaryDark.withValues(alpha: 0.12),
                child: Text(
                  _initials(name),
                  style: TextStyle(
                    color: b.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              name,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: b.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Compte Mon Peya',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: b.muted),
            ),
            const SizedBox(height: 24),
            _InfoGroup(
              items: [
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Nom',
                  value: name,
                ),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Contact',
                  value: contact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoGroup extends StatelessWidget {
  const _InfoGroup({required this.items});

  final List<_InfoRow> items;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Container(
      decoration: BoxDecoration(
        color: b.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: b.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: b.border),
            items[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return ListTile(
      leading: Icon(icon, color: b.primaryDark),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: b.muted,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          color: b.text,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}
