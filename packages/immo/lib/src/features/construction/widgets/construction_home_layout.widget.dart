import 'package:flutter/material.dart';

import 'package:immo/src/features/construction/navigation/construction.tab.dart';
import 'package:immo/src/shared/auth/scopes/immo_module_session.scope.dart';
import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';
import 'package:immo/src/shared/widgets/immo_sheet.widget.dart';

/// Construction home — Location layout (accent header + sheet) in orange,
/// with the role switch on the header.
class ConstructionHomeLayout extends StatelessWidget {
  const ConstructionHomeLayout({
    super.key,
    required this.role,
    this.onRoleChanged,
    required this.stats,
    required this.actions,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final ConstructionRole role;
  /// Null in a single-role app: no role picker on the header.
  final ValueChanged<ConstructionRole>? onRoleChanged;
  final List<ImmoStat> stats;
  final List<ImmoAction> actions;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final session = ImmoModuleSessionScope.of(context);
    final name = (session.displayName ?? '').trim();

    return ImmoHeaderPage(
      eyebrow: 'Mr Immo Construction',
      title: name.isEmpty ? 'Bonjour' : 'Bonjour, $name',
      subtitle: switch (role) {
        ConstructionRole.supplier => 'Vos commandes et livraisons',
        ConstructionRole.chefSite => 'Vos chantiers en un coup d’œil',
        ConstructionRole.superviseur => 'Les demandes des chantiers à valider',
        ConstructionRole.moyensGeneraux => 'Les achats à passer auprès des fournisseurs',
      },
      trailing: const Icon(Icons.construction_rounded,
          color: Colors.white, size: 30),
      // Four roles no longer fit a segmented switch: a picker on the header instead
      headerExtra: onRoleChanged == null ? null : _RolePicker(role: role, onChanged: onRoleChanged!),
      body: ListView(
        key: ValueKey(role),
        padding: EdgeInsets.fromLTRB(
          ImmoSpacing.lg,
          ImmoSpacing.lg,
          ImmoSpacing.lg,
          ImmoPillNavBar.contentBottomPadding(context),
        ),
        children: ImmoStagger.wrap([
          ImmoStatRow(stats: stats),
          const SizedBox(height: ImmoSpacing.lg),
          const ImmoSectionTitle('Actions rapides'),
          ImmoActionGrid(actions: actions),
          const SizedBox(height: ImmoSpacing.lg),
          const ImmoSectionTitle('Activité récente'),
          ImmoEmptyState(
            icon: Icons.history_rounded,
            title: emptyTitle,
            message: emptyMessage,
          ),
        ]),
      ),
    );
  }
}

/// "Rôle : Superviseur" on the accent header; opens the list of roles.
class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.role, required this.onChanged});

  final ConstructionRole role;
  final ValueChanged<ConstructionRole> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showImmoSheet<ConstructionRole>(
      context,
      title: 'Voir en tant que',
      builder: (ctx) {
        final b = ImmoBrand.rentalOf(ctx);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in ConstructionRole.values)
              ImmoListTile(
                icon: r.icon,
                title: r.label,
                trailing: Icon(
                  r == role ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: r == role ? b.primary : b.muted,
                ),
                onTap: () => Navigator.pop(ctx, r),
              ),
          ],
        );
      },
    );
    if (picked != null && picked != role) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _pick(context),
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(role.icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Rôle : ${role.label}',
                    style: TextStyle(
                      fontFamily: ImmoBrand.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(Icons.expand_more_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
