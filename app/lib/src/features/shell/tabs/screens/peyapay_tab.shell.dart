import 'package:flutter/material.dart';
import 'package:peyapay/peyapay.dart';

import 'package:app/src/features/shell/widgets/main_bottom_navigation_bar.widget.dart';

class PeyapayTabShell extends StatelessWidget {
  const PeyapayTabShell({
    super.key,
    required this.revealController,
  });

  final PeyapayHomeRevealController revealController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MainBottomNavigationBar.contentBottomPadding(context),
      ),
      child: PeyapayScreen(
        revealController: revealController,
      ),
    );
  }
}
