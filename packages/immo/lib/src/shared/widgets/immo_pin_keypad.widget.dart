import 'dart:math';

import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';

/// Mon Peya's PIN pad: digits shuffled on every opening, delete on the last row
/// (long press clears).
class ImmoPinKeypad extends StatefulWidget {
  const ImmoPinKeypad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    required this.onClear,
    this.enabled = true,
    this.random,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onClear;
  final bool enabled;

  /// Tests only: a seeded shuffle.
  final Random? random;

  @override
  State<ImmoPinKeypad> createState() => _ImmoPinKeypadState();
}

class _ImmoPinKeypadState extends State<ImmoPinKeypad> {
  late final List<String> _digits = [for (var i = 0; i < 10; i++) '$i']..shuffle(widget.random ?? Random());

  static const _keyWidth = 76.0;
  static const _keyHeight = 58.0;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final color = widget.enabled ? b.text : b.muted;

    Widget key(String digit) => InkWell(
          onTap: widget.enabled ? () => widget.onDigit(digit) : null,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: _keyWidth,
            height: _keyHeight,
            child: Center(
              child: Text(digit, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            ),
          ),
        );

    Widget row(List<Widget> keys) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: keys),
        );

    return Column(
      children: [
        for (var r = 0; r < 3; r++) row([for (var c = 0; c < 3; c++) key(_digits[r * 3 + c])]),
        row([
          const SizedBox(width: _keyWidth, height: _keyHeight),
          key(_digits[9]),
          GestureDetector(
            onTap: widget.enabled ? widget.onDelete : null,
            onLongPress: widget.enabled ? widget.onClear : null,
            child: SizedBox(
              width: _keyWidth,
              height: _keyHeight,
              child: Center(
                child: Icon(Icons.backspace_outlined, color: color, size: 24, semanticLabel: 'Effacer'),
              ),
            ),
          ),
        ]),
      ],
    );
  }
}
