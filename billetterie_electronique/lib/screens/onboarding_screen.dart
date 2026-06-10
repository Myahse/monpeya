import 'package:flutter/material.dart';

import '../billetterie_brand.dart';

class BilletterieOnboardingScreen extends StatefulWidget {
  const BilletterieOnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<BilletterieOnboardingScreen> createState() => _BilletterieOnboardingScreenState();
}

class _BilletterieOnboardingScreenState extends State<BilletterieOnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  static const _steps = [
    ('Billetterie', 'Billets électroniques intégrés à Mon Peya Pay.', true),
    ('Événements', 'Concerts, conférences, festivals — achetez en quelques gestes.', false),
    ('Tickets Cars', 'Créez des tickets génériques avec QR code.', false),
    ('Paiement Peya', 'Payez via votre wallet Mon Peya en toute sécurité.', false),
  ];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _next() {
    if (_index >= _steps.length - 1) {
      widget.onComplete();
      return;
    }
    setState(() => _index += 1);
    _page.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BilletterieBrand.onboardingBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final step = _steps[i];
                  return Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (step.$3)
                          const Icon(Icons.confirmation_number, size: 72, color: Colors.white)
                        else
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                          ),
                        const SizedBox(height: 28),
                        Text(
                          step.$1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          step.$2,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 16, height: 1.4),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _steps.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: i == _index ? 1 : 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: BilletterieBrand.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(_index >= _steps.length - 1 ? 'Commencer' : 'Continuer'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
