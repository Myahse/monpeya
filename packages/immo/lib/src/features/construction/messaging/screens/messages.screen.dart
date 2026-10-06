import 'package:flutter/material.dart';

import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImmoTabPage(
      title: 'Messages',
      subtitle: 'Fournisseurs, équipes et chantiers',
      children: [
        ImmoEmptyState(
          icon: Icons.forum_outlined,
          title: 'Aucune conversation',
          message: 'Vos échanges avec les fournisseurs et les chefs de chantier apparaîtront ici.',
        ),
      ],
    );
  }
}
