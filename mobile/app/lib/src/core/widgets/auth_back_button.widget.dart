import 'package:flutter/material.dart';

/// Top-left back control used across auth screens.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Icon(Icons.chevron_left, size: 28),
        ),
      ),
    );
  }
}
