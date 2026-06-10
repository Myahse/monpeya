import 'package:flutter/material.dart';

const shellTopExtra = 16.0;

double statusBarTop(BuildContext context) => MediaQuery.viewPaddingOf(context).top;

double shellContentTop(BuildContext context) => statusBarTop(context) + shellTopExtra;

/// Initial top inset inside a scroll view — scrolls away so content can pass under the status bar.
EdgeInsets shellScrollPadding(
  BuildContext context, {
  double horizontal = 16,
  double top = 12,
  double bottom = 24,
}) {
  return EdgeInsets.fromLTRB(horizontal, shellContentTop(context) + top, horizontal, bottom);
}
