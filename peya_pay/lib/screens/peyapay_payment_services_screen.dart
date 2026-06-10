import 'package:flutter/material.dart';

import '../peya_pay_assets.dart';
import '../widgets/peyapay_slide_panel.dart';
import '../utils/screen_insets.dart';
import 'peyapay_cie_sodeci_payment_screen.dart';

/// Paiements et services — Flutter port of RN `PaymentsServices.tsx`.
class PeyapayPaymentServicesScreen extends StatefulWidget {
  const PeyapayPaymentServicesScreen({super.key, this.onClose});

  /// When set, back uses this instead of [Navigator.pop] (inline dashboard overlay).
  final VoidCallback? onClose;

  @override
  State<PeyapayPaymentServicesScreen> createState() => _PeyapayPaymentServicesScreenState();
}

class _PeyapayPaymentServicesScreenState extends State<PeyapayPaymentServicesScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceFade;
  late final AnimationController _entranceSlide;
  late final AnimationController _billSlide;

  PeyapayBillServiceType? _billService;

  @override
  void initState() {
    super.initState();
    _entranceFade = AnimationController(vsync: this, duration: const Duration(milliseconds: 300), value: 0);
    _entranceSlide = AnimationController(vsync: this, duration: const Duration(milliseconds: 300), value: 1);
    _billSlide = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceFade.forward();
      _entranceSlide.forward();
    });
  }

  @override
  void dispose() {
    _entranceFade.dispose();
    _entranceSlide.dispose();
    _billSlide.dispose();
    super.dispose();
  }

  void _back() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _openBill(PeyapayBillServiceType type) async {
    setState(() => _billService = type);
    await _billSlide.forward(from: 0);
  }

  Future<void> _closeBill() async {
    await _billSlide.reverse();
    if (!mounted) return;
    setState(() => _billService = null);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? cs.surface : const Color(0xFFFFFFFF);
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);
    final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF666666);
    final border = isDark ? cs.outlineVariant : const Color(0xFFE0E0E0);

    final topPad = peyapayStatusBarTop(context);
    final w = MediaQuery.sizeOf(context).width;
    final titleSize = w < 375 ? 20.0 : 22.0;
    final nameSize = w < 375 ? 12.0 : w < 414 ? 13.0 : 14.0;

    final listVisible = _billService == null;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(8, topPad + 8, 16, 0),
                child: Row(
                    children: [
                      IconButton(
                        onPressed: _back,
                        icon: Icon(Icons.chevron_left, size: 24, color: ink),
                      ),
                      Expanded(
                        child: Text(
                          'Paiements et services',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w900, color: ink),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Choisissez et payez vos factures.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: muted),
                  ),
                ),
                if (listVisible)
                  Expanded(
                    child: FadeTransition(
                      opacity: _entranceFade,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
                          CurvedAnimation(parent: _entranceSlide, curve: Curves.easeOut),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              Container(height: 0.5, color: border),
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListView(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.only(bottom: 20),
                                  children: [
                                    _ServiceRow(
                                      name: 'CIE',
                                      nameSize: nameSize,
                                      ink: ink,
                                      leading: const _CieLogo(),
                                      onTap: () => _openBill(PeyapayBillServiceType.cie),
                                    ),
                                    _separator(border),
                                    _ServiceRow(
                                      name: 'Facture SODECI',
                                      nameSize: nameSize,
                                      ink: ink,
                                      leading: const _SodeciLogo(),
                                      onTap: () => _openBill(PeyapayBillServiceType.sodeci),
                                    ),
                                    _separator(border),
                                    _ServiceRow(
                                      name: 'Domiciliation',
                                      nameSize: nameSize,
                                      ink: ink,
                                      leading: const _EmptyServiceIcon(),
                                      onTap: () => debugPrint('Domiciliation pressed'),
                                    ),
                                    _separator(border),
                                    _ServiceRow(
                                      name: 'Autres services',
                                      nameSize: nameSize,
                                      ink: ink,
                                      leading: const _EmptyServiceIcon(),
                                      onTap: () => debugPrint('Autres services pressed'),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(height: 0.5, color: border),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (_billService != null)
              PeyapaySlidePanel(
                animation: _billSlide,
                child: PeyapayCieSodeciPaymentScreen(
                  serviceType: _billService!,
                  onClose: _closeBill,
                ),
              ),
          ],
        ),
    );
  }

  Widget _separator(Color border) {
    return Container(
      height: 3,
      margin: const EdgeInsets.only(left: 56, top: 2, bottom: 2),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: border, width: 0.5),
          bottom: BorderSide(color: border, width: 0.5),
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.name,
    required this.nameSize,
    required this.ink,
    required this.leading,
    required this.onTap,
  });

  final String name;
  final double nameSize;
  final Color ink;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(fontSize: nameSize, fontWeight: FontWeight.w900, color: ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CieLogo extends StatelessWidget {
  const _CieLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 40,
      child: Image.asset(
        'assets/logo/logo_partenaires.png',
        package: PeyaPayAssets.package,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox(width: 40, height: 40),
      ),
    );
  }
}

class _SodeciLogo extends StatelessWidget {
  const _SodeciLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 40,
      child: Transform.scale(
        scale: 1.8,
        child: Image.asset(
          'assets/logo/logo_sodeci.png',
          package: PeyaPayAssets.package,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox(width: 40, height: 40),
        ),
      ),
    );
  }
}

class _EmptyServiceIcon extends StatelessWidget {
  const _EmptyServiceIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 40, height: 40);
  }
}
