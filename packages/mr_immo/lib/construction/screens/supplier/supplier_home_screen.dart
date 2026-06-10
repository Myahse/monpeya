import 'package:flutter/material.dart';

import '../../../shared/auth/immo_module_session_scope.dart';
import '../../widgets/construction_home_layout.dart';

class SupplierHomeScreen extends StatelessWidget {
  const SupplierHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final phone = ImmoModuleSessionScope.of(context).phone ?? '';
    return ConstructionHomeLayout(
      userName: phone,
      roleLabel: 'Supplier Dashboard',
      stats: const [
        ConstructionStat(label: 'Active Orders', value: '0', color: Color(0xFFFF9401)),
        ConstructionStat(label: 'Pending Deliveries', value: '0', color: Color(0xFF10B981)),
        ConstructionStat(label: 'This Month', value: '0 CFA', color: Color(0xFF3B82F6)),
      ],
      quickActions: const [
        ConstructionQuickAction(title: 'New Order', emoji: '📦', description: 'Create a new order'),
        ConstructionQuickAction(title: 'Deliveries', emoji: '🚚', description: 'Manage deliveries'),
        ConstructionQuickAction(title: 'Inventory', emoji: '📊', description: 'Check inventory'),
        ConstructionQuickAction(title: 'Payments', emoji: '💰', description: 'View payments'),
      ],
    );
  }
}
