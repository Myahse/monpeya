import 'package:flutter/material.dart';

import '../peya_pay_assets.dart';

/// Visa / Mastercard badge — RN `SuccessModal` + `AddMoney` card row.
enum PeyapayCardBrandBadgeSize { modal, row }

class PeyapayCardBrandBadge extends StatelessWidget {
  const PeyapayCardBrandBadge({
    super.key,
    required this.cardType,
    this.size = PeyapayCardBrandBadgeSize.modal,
    this.logoOpacity = 1,
    this.recognized = true,
  });

  final String cardType;
  final PeyapayCardBrandBadgeSize size;
  final double logoOpacity;
  final bool recognized;

  @override
  Widget build(BuildContext context) {
    if (!recognized) {
      final r = size == PeyapayCardBrandBadgeSize.modal ? 40.0 : 22.0;
      return CircleAvatar(
        radius: r,
        backgroundColor: Colors.red,
        child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: r),
      );
    }

    if (size == PeyapayCardBrandBadgeSize.modal) {
      return _ModalBadge(cardType: cardType, logoOpacity: logoOpacity);
    }
    return _RowBadge(cardType: cardType);
  }
}

class _ModalBadge extends StatelessWidget {
  const _ModalBadge({required this.cardType, required this.logoOpacity});

  final String cardType;
  final double logoOpacity;

  @override
  Widget build(BuildContext context) {
    if (cardType == 'VISA') {
      return Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(color: Color(0xFF1A1F71), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Opacity(
          opacity: logoOpacity,
          child: Image.asset(
      'assets/logo/cards/visabluebg.png',
      package: PeyaPayAssets.package,
            width: 60,
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Image.asset(
      'assets/logo/cards/visa.png',
      package: PeyaPayAssets.package,
              width: 60,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    if (cardType == 'MASTERCARD') {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFDDDDDD)),
        ),
        alignment: Alignment.center,
        child: Opacity(
          opacity: logoOpacity,
          child: Image.asset(
      'assets/logo/cards/Mastercard.png',
      package: PeyaPayAssets.package,
            width: 50,
            height: 30,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 40,
      backgroundColor: const Color(0xFF1A1F71),
      child: Opacity(
        opacity: logoOpacity,
        child: Text(cardType, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _RowBadge extends StatelessWidget {
  const _RowBadge({required this.cardType});

  final String cardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: _brandImage(height: 28),
    );
  }

  Widget _brandImage({required double height}) {
    if (cardType == 'VISA') {
      return Image.asset(
      'assets/logo/cards/visa.png',
      package: PeyaPayAssets.package,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Text('VISA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
      );
    }
    if (cardType == 'MASTERCARD') {
      return Image.asset(
      'assets/logo/cards/Mastercard.png',
      package: PeyaPayAssets.package,
        height: height * 0.75,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Text('MC', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
      );
    }
    return Text(cardType, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11));
  }
}
