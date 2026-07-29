import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';

enum BilletterieTab { home, tickets, profile }

/// Bottom bar.
///
/// Client: Home | Mes tickets (QR) | Profil
/// Business: Accueil | Scanner (QR) | Profil
class BilletterieBottomNav extends StatelessWidget {
  const BilletterieBottomNav({
    super.key,
    required this.current,
    required this.onChanged,
    this.businessMode = false,
  });

  final BilletterieTab current;
  final ValueChanged<BilletterieTab> onChanged;
  final bool businessMode;

  /// Grey strip height (labels).
  static const barHeight = 64.0;

  /// QR circle diameter.
  static const fabSize = 92.0;

  /// How far the circle sits inside the grey bar (lower = higher above the bar).
  static const fabIntoBar = 16.0;

  /// Part of the circle that floats above the grey bar.
  static double get fabOverflow => fabSize - fabIntoBar;

  /// Full layout height used for hit-testing (circle + bar).
  static double layoutHeight(BuildContext context) {
    return fabOverflow + barHeight + MediaQuery.paddingOf(context).bottom;
  }

  /// Extra list padding so content clears the floating QR.
  static double contentBottomPadding(BuildContext context) {
    return fabOverflow + 12;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final brand = BilletterieBrand.of(context);
    final centerSelected = current == BilletterieTab.tickets;
    final totalHeight = fabOverflow + barHeight + bottomInset;
    final homeLabel = businessMode ? 'Accueil' : 'Home';
    final centerLabel = businessMode ? 'Scanner' : 'Mes tickets';

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: fabOverflow,
            child: Row(
              children: [
                const Expanded(child: IgnorePointer(child: SizedBox.expand())),
                SizedBox(width: fabSize),
                const Expanded(child: IgnorePointer(child: SizedBox.expand())),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight + bottomInset,
            child: ColoredBox(
              color: brand.navBar,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Row(
                  children: [
                    Expanded(
                      child: _NavLabel(
                        label: homeLabel,
                        selected: current == BilletterieTab.home,
                        onTap: () => onChanged(BilletterieTab.home),
                      ),
                    ),
                    Expanded(
                      child: _NavLabel(
                        label: centerLabel,
                        selected: centerSelected,
                        onTap: () => onChanged(BilletterieTab.tickets),
                      ),
                    ),
                    Expanded(
                      child: _NavLabel(
                        label: 'Profil',
                        selected: current == BilletterieTab.profile,
                        onTap: () => onChanged(BilletterieTab.profile),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + (barHeight - fabIntoBar),
            child: Center(
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: centerSelected ? 3 : 1,
                shadowColor: Colors.black26,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onChanged(BilletterieTab.tickets),
                  child: Container(
                    width: fabSize,
                    height: fabSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            centerSelected ? brand.primaryDark : brand.text,
                        width: centerSelected ? 2.2 : 1.4,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: businessMode
                        ? Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 44,
                            color: centerSelected
                                ? brand.primaryDark
                                : BilletterieBrand.qrInk,
                          )
                        : QrImageView(
                            data: 'billetterie://mes-tickets',
                            version: QrVersions.auto,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: BilletterieBrand.qrInk,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: BilletterieBrand.qrInk,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavLabel extends StatelessWidget {
  const _NavLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: BilletterieBrand.of(context).text,
              ),
        ),
      ),
    );
  }
}
