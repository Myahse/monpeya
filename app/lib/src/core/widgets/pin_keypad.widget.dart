import 'dart:math';

import 'package:flutter/material.dart';

List<List<String>> generateKeypad3Rows() {
  final digits = List<String>.generate(10, (i) => '$i');
  digits.shuffle(Random());
  return [
    [digits[0], digits[1], digits[2]],
    [digits[3], digits[4], digits[5]],
    [digits[6], digits[7], digits[8]],
    [digits[9]],
  ];
}

class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.keypad,
    required this.onKeyPress,
    required this.onDelete,
    required this.onLongDelete,
    this.textColor = const Color(0xFF111827),
    this.showBiometric = false,
    this.onBiometric,
    this.biometricEnabled = true,
  });

  final List<List<String>> keypad;
  final ValueChanged<String> onKeyPress;
  final VoidCallback onDelete;
  final VoidCallback onLongDelete;
  final Color textColor;
  final bool showBiometric;
  final VoidCallback? onBiometric;
  final bool biometricEnabled;

  static const _keyWidth = 74.0;
  static const _keyHeight = 56.0;
  static const _keyFontSize = 22.0;

  @override
  Widget build(BuildContext context) {
    Widget keyBtn(String label) {
      return InkWell(
        onTap: () => onKeyPress(label),
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: _keyWidth,
          height: _keyHeight,
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontSize: _keyFontSize, fontWeight: FontWeight.w800, color: textColor),
            ),
          ),
        ),
      );
    }

    Widget delBtn() {
      return GestureDetector(
        onTap: onDelete,
        onLongPress: onLongDelete,
        child: SizedBox(
          width: _keyWidth,
          height: _keyHeight,
          child: Center(
            child: Icon(Icons.backspace_outlined, color: textColor),
          ),
        ),
      );
    }

    Widget bioBtn() {
      return InkWell(
        onTap: biometricEnabled ? onBiometric : null,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: _keyWidth,
          height: _keyHeight,
          child: Center(
            child: Icon(
              Icons.fingerprint,
              color: biometricEnabled ? const Color(0xFF006D56) : textColor.withValues(alpha: 0.35),
              size: 26,
            ),
          ),
        ),
      );
    }

    Widget lastRowLeading() {
      if (showBiometric && onBiometric != null) {
        return bioBtn();
      }
      return const SizedBox(width: _keyWidth, height: _keyHeight);
    }

    return Column(
      children: [
        for (var r = 0; r < 3; r++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                keyBtn(keypad[r][0]),
                keyBtn(keypad[r][1]),
                keyBtn(keypad[r][2]),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              lastRowLeading(),
              keyBtn(keypad[3][0]),
              delBtn(),
            ],
          ),
        ),
      ],
    );
  }
}
