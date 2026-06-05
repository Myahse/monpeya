import 'package:flutter/material.dart';

class PeyapayLoadingGate extends StatelessWidget {
  const PeyapayLoadingGate({super.key, required this.textColor});
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 10),
            Text(
              'Chargement…',
              style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

class PeyapayBlockedGate extends StatelessWidget {
  const PeyapayBlockedGate({
    super.key,
    required this.titleColor,
    required this.bodyColor,
    required this.buttonBg,
    required this.onPressLogin,
  });

  final Color titleColor;
  final Color bodyColor;
  final Color buttonBg;
  final VoidCallback onPressLogin;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Connexion requise',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: titleColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Connectez-vous pour accéder à Peyapay.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: bodyColor),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: buttonBg,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: onPressLogin,
                  child: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

