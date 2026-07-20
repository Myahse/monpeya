import 'package:flutter/material.dart';



import 'package:peyapay/src/core/host/peyapay_host.bridge.dart';

import 'package:peyapay/src/core/qr/cached_qr_view.dart';

import 'package:peyapay/src/data/services/peyapay_crypto.service.dart';

import 'package:peyapay/src/data/services/peyapay_qr.service.dart';

import 'package:peyapay/src/data/services/peyapay_wallet_qr.cache.dart';



/// Compact wallet QR preview on the home header (sits on a dark gradient).

class PeyapayWalletQrThumb extends StatefulWidget {

  const PeyapayWalletQrThumb({

    super.key,

    required this.size,

    required this.sessionActive,

    this.onTap,
    this.lightOnDark = true,
    this.fillFactor = peyapayQrFillFactor,
  });

  final double size;
  final bool sessionActive;
  final Future<void> Function()? onTap;
  final bool lightOnDark;
  final double fillFactor;



  @override

  State<PeyapayWalletQrThumb> createState() => _PeyapayWalletQrThumbState();

}



class _PeyapayWalletQrThumbState extends State<PeyapayWalletQrThumb> {

  final PeyapayQrService _qrService = PeyapayQrService();

  final PeyapayWalletQrCache _cache = PeyapayWalletQrCache.instance;



  String? _qrContent;

  bool _loading = false;



  @override

  void initState() {

    super.initState();

    _syncQr();

  }



  @override

  void didUpdateWidget(covariant PeyapayWalletQrThumb oldWidget) {

    super.didUpdateWidget(oldWidget);

    if (oldWidget.sessionActive != widget.sessionActive) {

      _syncQr();

    }

  }



  Future<void> _syncQr() async {

    final phone = await PeyapayHostBridge.requireAuth.getPhone();

    final phoneDigits = normalizePeyapayPhone(phone ?? '');

    final cached = _cache.contentForPhone(phone);



    if (cached != null && mounted) {

      setState(() {

        _qrContent = cached;

        _loading = false;

      });

    }



    final shouldGenerate =

        phoneDigits.length == 10 && (widget.sessionActive || cached == null);

    if (!shouldGenerate) {

      if (mounted && !shouldGenerate && cached == null) {

        setState(() => _loading = false);

      }

      return;

    }



    if (mounted && _qrContent == null) {

      setState(() => _loading = true);

    }



    try {

      final clientState = PeyapayHostBridge.api?.clientState;

      final displayName = clientState?.nomClient?.trim();



      final result = await _qrService.generateWalletQr(

        clientCodeKey: phoneDigits,

        displayName: displayName?.isNotEmpty == true ? displayName! : phoneDigits,

      );



      _cache.save(phone: phoneDigits, qrContent: result.qrContent);



      if (!mounted) return;

      setState(() {

        _qrContent = result.qrContent;

        _loading = false;

      });

    } catch (_) {

      if (!mounted) return;

      setState(() => _loading = false);

    }

  }



  Color get _accent =>

      peyapayQrModuleColor(context, lightOnDark: widget.lightOnDark);



  @override

  Widget build(BuildContext context) {

    final child = SizedBox(

      width: widget.size,

      height: widget.size,

      child: _buildContent(),

    );



    if (widget.onTap == null) return child;



    return GestureDetector(

      behavior: HitTestBehavior.opaque,

      onTap: () => widget.onTap!(),

      child: child,

    );

  }



  Widget _buildContent() {

    if (_loading && _qrContent == null) {

      return Center(

        child: SizedBox(

          width: 22,

          height: 22,

          child: CircularProgressIndicator(

            strokeWidth: 2,

            color: _accent.withValues(alpha: 0.9),

          ),

        ),

      );

    }



    if (_qrContent != null) {

      return CachedQRFill(
        qrContent: _qrContent!,
        lightOnDark: widget.lightOnDark,
        fillFactor: widget.fillFactor,
      );

    }



    return _placeholderIcon();

  }



  Widget _placeholderIcon() {

    return Center(

      child: Icon(

        Icons.qr_code_2_rounded,

        color: _accent.withValues(alpha: 0.85),

        size: widget.size * 0.48,

      ),

    );

  }

}


