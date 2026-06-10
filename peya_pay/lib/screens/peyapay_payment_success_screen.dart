import 'package:flutter/material.dart';

import '../utils/formatters.dart';

class PeyapayPaymentSuccessScreen extends StatelessWidget {
  const PeyapayPaymentSuccessScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.merchantName,
    this.merchantIcon,
    this.merchantColor,
  });

  final String title;
  final String subtitle;
  final int amount;
  final String merchantName;
  final IconData? merchantIcon;
  final Color? merchantColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? cs.surface : const Color(0xFFFFFFFF);
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);
    final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280);
    final border = isDark ? cs.outlineVariant : const Color(0xFFE5E7EB);
    const green = Color(0xFF006D56);

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
                    onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.close_rounded, size: 24, color: ink),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('Succès', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.check_rounded, color: green, size: 36),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          if (merchantIcon != null) ...[
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: (merchantColor ?? green).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Icon(merchantIcon, color: merchantColor ?? green, size: 22),
                            ),
                            const SizedBox(height: 10),
                          ],
                          _kv('Marchand', merchantName, ink, muted),
                          const SizedBox(height: 10),
                          _kv('Montant', '${formatFrMoneySigned(amount)} XOF', ink, muted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: const Text('Terminer', style: TextStyle(fontWeight: FontWeight.w900)),
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

Widget _kv(String k, String v, Color ink, Color muted) {
  return Row(
    children: [
      Expanded(child: Text(k, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: muted))),
      const SizedBox(width: 12),
      Flexible(child: Text(v, textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: ink))),
    ],
  );
}

