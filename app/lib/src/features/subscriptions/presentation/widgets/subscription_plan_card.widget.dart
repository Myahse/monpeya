import 'package:flutter/material.dart';

import 'package:app/src/core/api/models/mon_peya_subscription.models.dart';
import 'package:app/src/features/subscriptions/config/subscription_services.config.dart';

class SubscriptionPlanCard extends StatelessWidget {
  const SubscriptionPlanCard({
    super.key,
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
    final kindLabel = plan.isGrouped ? 'Pack groupé' : 'Individuel';
    final priceLabel =
        '${plan.price.toStringAsFixed(0)} ${plan.currency} / ${billingPeriodLabel(plan.billingPeriod)}';

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
                        color:
                            selected ? cs.primary : cs.onSecondaryContainer,
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
                            SubscriptionServices.moduleLabel(m),
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

  static String billingPeriodLabel(String period) {
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
