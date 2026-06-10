import 'dart:math';

import 'package:flutter/material.dart';

List<List<String>> generateKeypad3Rows() {
  final digits = List<String>.generate(10, (i) => '$i');
  digits.shuffle(Random());
  // 3 rows of 3 + a last row with blank, one digit, and delete handled separately.
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
  });

  final List<List<String>> keypad;
  final ValueChanged<String> onKeyPress;
  final VoidCallback onDelete;
  final VoidCallback onLongDelete;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    Widget keyBtn(String label) {
      return InkWell(
        onTap: () => onKeyPress(label),
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 74,
          height: 56,
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor),
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
          width: 74,
          height: 56,
          child: Center(
            child: Icon(Icons.backspace_outlined, color: textColor),
          ),
        ),
      );
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
              const SizedBox(width: 74, height: 56),
              keyBtn(keypad[3][0]),
              delBtn(),
            ],
          ),
        ),
      ],
    );
  }
}

