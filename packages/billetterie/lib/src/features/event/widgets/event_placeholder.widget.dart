import 'package:flutter/material.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/features/event/widgets/event_bottom_nav.widget.dart';

/// Placeholder pane used while event screens are built out.
class EventPlaceholderPane extends StatelessWidget {
  const EventPlaceholderPane({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.eventOf(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          28,
          24,
          28,
          BilletterieEventBottomNav.contentBottomPadding(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: brand.primarySoft.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(22),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 34, color: brand.primaryDark),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: brand.text,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: brand.muted,
                    height: 1.35,
                  ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: brand.primaryDark,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
