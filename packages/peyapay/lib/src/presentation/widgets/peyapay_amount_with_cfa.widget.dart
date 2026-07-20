import 'package:flutter/material.dart';

import 'package:peyapay/src/core/utils/formatters.util.dart';

/// Amount with [CFA] rendered as a superscript-style currency suffix.
class PeyapayAmountWithCfa extends StatelessWidget {
  const PeyapayAmountWithCfa({
    super.key,
    required this.amount,
    this.color,
    this.mainFontSize = 28,
    this.currencyFontSize = 13,
    this.fontWeight = FontWeight.w900,
    this.showSign = false,
    this.isCredit,
    this.textAlign = TextAlign.center,
  });

  final int amount;
  final Color? color;
  final double mainFontSize;
  final double currencyFontSize;
  final FontWeight fontWeight;
  final bool showSign;
  final bool? isCredit;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? Theme.of(context).colorScheme.onSurface;
    final sign = showSign && isCredit != null ? (isCredit! ? '+' : '-') : '';
    final value = '$sign${formatFrMoneySigned(amount.abs())}';

    return Text.rich(
      TextSpan(
        text: value,
        style: TextStyle(fontSize: mainFontSize, fontWeight: fontWeight, color: ink, height: 1.1),
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Padding(
              padding: EdgeInsets.only(left: mainFontSize * 0.12, bottom: mainFontSize * 0.42),
              child: Text(
                'CFA',
                style: TextStyle(fontSize: currencyFontSize, fontWeight: fontWeight, color: ink, height: 1),
              ),
            ),
          ),
        ],
      ),
      textAlign: textAlign,
    );
  }
}
