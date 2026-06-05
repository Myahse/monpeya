import 'package:flutter/material.dart';

import '../widgets/peyapay_slide_panel.dart';
import 'peyapay_cie_sodeci_payment_screen.dart';
import 'peyapay_source_of_funds_screen.dart';

/// Payments & services — Flutter port of RN `PaymentsServices.tsx`.
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
  late final AnimationController _assuranceSlide;

  PeyapayBillServiceType? _billService;
  bool _showAssurance = false;

  @override
  void initState() {
    super.initState();
    _entranceFade = AnimationController(vsync: this, duration: const Duration(milliseconds: 300), value: 0);
    _entranceSlide = AnimationController(vsync: this, duration: const Duration(milliseconds: 300), value: 1);
    _billSlide = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _assuranceSlide = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

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
    _assuranceSlide.dispose();
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

  Future<void> _openAssurance() async {
    setState(() => _showAssurance = true);
    await _assuranceSlide.forward(from: 0);
  }

  Future<void> _closeAssurance() async {
    await _assuranceSlide.reverse();
    if (!mounted) return;
    setState(() => _showAssurance = false);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final titleSize = w < 375 ? 20.0 : 22.0;
    final nameSize = w < 375 ? 12.0 : w < 414 ? 13.0 : 14.0;

    final listVisible = _billService == null && !_showAssurance;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _back,
                        icon: const Icon(Icons.chevron_left, size: 24, color: Colors.black),
                      ),
                      Expanded(
                        child: Text(
                          'Payments & services',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w900, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Choose and pay your bills.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF666666)),
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
                              Container(height: 0.5, color: const Color(0xFFE0E0E0)),
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListView(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.only(bottom: 20),
                                  children: [
                                    _ServiceRow(
                                      name: 'CIE',
                                      nameSize: nameSize,
                                      leading: _CieLogo(),
                                      onTap: () => _openBill(PeyapayBillServiceType.cie),
                                    ),
                                    _separator(),
                                    _ServiceRow(
                                      name: 'Facture SODECI',
                                      nameSize: nameSize,
                                      leading: const _SodeciLogo(),
                                      onTap: () => _openBill(PeyapayBillServiceType.sodeci),
                                    ),
                                    _separator(),
                                    _ServiceRow(
                                      name: 'Assurance',
                                      nameSize: nameSize,
                                      leading: const _EmptyServiceIcon(),
                                      onTap: _openAssurance,
                                    ),
                                    _separator(),
                                    _ServiceRow(
                                      name: 'Domiciliation',
                                      nameSize: nameSize,
                                      leading: const _EmptyServiceIcon(),
                                      onTap: () => debugPrint('Domiciliation pressed'),
                                    ),
                                    _separator(),
                                    _ServiceRow(
                                      name: 'Autres services',
                                      nameSize: nameSize,
                                      leading: const _EmptyServiceIcon(),
                                      onTap: () => debugPrint('Autres services pressed'),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(height: 0.5, color: const Color(0xFFE0E0E0)),
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
            if (_showAssurance)
              PeyapaySlidePanel(
                animation: _assuranceSlide,
                child: PeyapaySourceOfFundsScreen(
                  onClose: _closeAssurance,
                  embeddedInPaymentServices: true,
                  onDepositComplete: () {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Paiement assurance enregistré')),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _separator() {
    return Container(
      height: 3,
      margin: const EdgeInsets.only(left: 56, top: 2, bottom: 2),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.name,
    required this.nameSize,
    required this.leading,
    required this.onTap,
  });

  final String name;
  final double nameSize;
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
                  style: TextStyle(fontSize: nameSize, fontWeight: FontWeight.w900, color: Colors.black),
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
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 40,
      child: Image.asset(
        'assets/logo/logo_partenaires.png',
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
