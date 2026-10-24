import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';

/// The look of every SegmentedButton in Construction: brand fill on the chosen
/// segment, bordered and bold. Pair it with `showSelectedIcon: false`.
ButtonStyle constructionSegmentStyle(ImmoRentalPalette b) => SegmentedButton.styleFrom(
      foregroundColor: b.text,
      selectedForegroundColor: Colors.white,
      selectedBackgroundColor: b.primary,
      side: BorderSide(color: b.border),
      textStyle: TextStyle(fontFamily: ImmoBrand.fontFamily, fontWeight: FontWeight.w700),
    );
