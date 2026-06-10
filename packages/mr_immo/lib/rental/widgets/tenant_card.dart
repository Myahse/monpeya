import 'package:flutter/material.dart';

import '../theme/rental_theme.dart';
import '../models/rental_tenant.dart';

/// 200×200 tenant card — mirrors RN `TenantCard.tsx`.
class RentalTenantCard extends StatelessWidget {
  const RentalTenantCard({
    super.key,
    required this.tenant,
    this.onTap,
  });

  final RentalTenant tenant;
  final VoidCallback? onTap;

  Color get _statusColor {
    switch (tenant.status.toLowerCase()) {
      case 'actif':
        return const Color(0xFF10B981);
      case 'inactif':
        return const Color(0xFFEF4444);
      case 'en_attente':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String get _statusLabel {
    switch (tenant.status.toLowerCase()) {
      case 'actif':
        return 'Actif';
      case 'inactif':
        return 'Inactif';
      case 'en_attente':
        return 'En attente';
      default:
        return tenant.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 200,
        margin: const EdgeInsets.only(right: RentalTheme.spacingLg),
        decoration: BoxDecoration(
          color: const Color(0xFFE1F5FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 100,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: tenant.photoUrl != null && tenant.photoUrl!.isNotEmpty
                        ? Image.network(
                            tenant.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _Avatar(initials: tenant.initials),
                          )
                        : _Avatar(initials: tenant.initials),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 8),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(Icons.info_outline, size: 20, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: const Color(0xFFF8F8F8),
                child: Padding(
                  padding: const EdgeInsets.all(RentalTheme.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: RentalTheme.textPrimary,
                        ),
                      ),
                      if (tenant.profession != null && tenant.profession!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          tenant.profession!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: RentalTheme.greenAccent,
                          ),
                        ),
                      ],
                      if (tenant.propertyName != null && tenant.propertyName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          tenant.propertyName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '📱 ${tenant.phone}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 9, color: RentalTheme.textSecondary),
                            ),
                          ),
                          if (tenant.monthlyIncome != null)
                            Text(
                              '${(tenant.monthlyIncome! / 1000).toStringAsFixed(0)}K',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: RentalTheme.greenAccent,
                              ),
                            ),
                        ],
                      ),
                    ],
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: RentalTheme.greenAccent,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
