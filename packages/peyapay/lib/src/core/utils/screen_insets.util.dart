import 'package:flutter/material.dart';


const peyapayTopExtra = 20.0;

double peyapayStatusBarTop(BuildContext context) =>
    MediaQuery.viewPaddingOf(context).top + peyapayTopExtra;


class PeyapayStatusBarSpacer extends StatelessWidget {
  const PeyapayStatusBarSpacer({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(height: peyapayStatusBarTop(context));
}


class FixedStatusBarOffset extends StatelessWidget {
  const FixedStatusBarOffset({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: peyapayStatusBarTop(context)),
        Expanded(child: child),
      ],
    );
  }
}
