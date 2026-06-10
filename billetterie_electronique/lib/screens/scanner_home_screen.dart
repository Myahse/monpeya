import 'package:flutter/material.dart';

import '../billetterie_brand.dart';

class ScannerHomeScreen extends StatelessWidget {
  const ScannerHomeScreen({super.key, required this.onResetPurpose});

  final VoidCallback onResetPurpose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BilletterieBrand.bg,
      appBar: AppBar(
        title: const Text('Contrôle d\'accès'),
        backgroundColor: BilletterieBrand.bg,
        foregroundColor: BilletterieBrand.text,
        elevation: 0,
        actions: [
          TextButton(onPressed: onResetPurpose, child: const Text('Profil')),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: BilletterieBrand.primarySoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.qr_code_scanner, size: 40, color: BilletterieBrand.primaryDark),
              ),
              const SizedBox(height: 20),
              const Text(
                'Contrôle d\'accès',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: BilletterieBrand.text),
              ),
              const SizedBox(height: 12),
              const Text(
                'Le scan des billets et la validation à l\'entrée seront disponibles ici. Utilisez ce mode lorsque vous contrôlez les accès pour un organisateur.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: BilletterieBrand.muted, height: 22 / 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
