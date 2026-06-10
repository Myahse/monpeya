import 'package:flutter/material.dart';

import '../../../shared/auth/immo_module_session_scope.dart';
import '../../widgets/construction_home_layout.dart';

class ChefSiteHomeScreen extends StatelessWidget {
  const ChefSiteHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final phone = ImmoModuleSessionScope.of(context).phone ?? '';
    return ConstructionHomeLayout(
      userName: phone,
      roleLabel: 'Site Manager Dashboard',
      stats: const [
        ConstructionStat(label: 'Active Sites', value: '0', color: Color(0xFFFF9401)),
        ConstructionStat(label: 'Pending Requests', value: '0', color: Color(0xFF10B981)),
        ConstructionStat(label: 'Team Members', value: '0', color: Color(0xFF3B82F6)),
      ],
      quickActions: const [
        ConstructionQuickAction(title: 'Sites', emoji: '🏗️', description: 'Manage construction sites'),
        ConstructionQuickAction(title: 'Team', emoji: '👥', description: 'View team members'),
        ConstructionQuickAction(title: 'Requests', emoji: '📋', description: 'Material requests'),
        ConstructionQuickAction(title: 'Reports', emoji: '📊', description: 'View reports'),
      ],
    );
  }
}
