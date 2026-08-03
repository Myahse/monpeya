import 'package:flutter/material.dart';

import 'package:app/src/core/assets/constants/asset.paths.dart';
import 'package:app/src/core/auth/auth.navigation.dart';
import 'package:app/src/core/routing/routes.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/core/widgets/pin_keypad.widget.dart';
import 'package:app/src/features/auth/presentation/login_pin/screens/login_pin.screen.dart';
import 'package:app/src/features/auth/presentation/registration_flow/screens/registration_flow.screen.dart';
import 'package:app/src/features/auth/presentation/widgets/auth_flow_scaffold.widget.dart';
import 'package:app/src/core/api/mon_peya_api.exception.dart';
import 'package:app/src/integration/adapters/mon_peya_backend.adapter.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key, this.embeddedInModule = false});
  static const routeName = '/phone';

  final bool embeddedInModule;

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  static const _countries = <({String code, String flag, String name})>[
    (code: '+225', flag: '🇨🇮', name: "Côte d'Ivoire"),
    (code: '+33', flag: '🇫🇷', name: 'France'),
    (code: '+1', flag: '🇺🇸', name: 'USA'),
    (code: '+44', flag: '🇬🇧', name: 'UK'),
  ];

  final _controller = TextEditingController();
  var _country = _countries[0];
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  static String formatPhoneNumber(String input) {
    final d = _digitsOnly(input);
    final clamped = d.length > 10 ? d.substring(0, 10) : d;
    final buf = StringBuffer();
    for (var i = 0; i < clamped.length; i++) {
      if (i > 0 && i % 2 == 0) buf.write(' ');
      buf.write(clamped[i]);
    }
    return buf.toString();
  }

  bool get _isValidPhone {
    final digits = _digitsOnly(_controller.text);
    return digits.length == 10;
  }

  Future<void> _showCountryPicker() async {
    final chosen = await showDialog<({String code, String flag, String name})>(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Dialog(
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    'Choisir le pays',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final c in _countries)
                    InkWell(
                      onTap: () => Navigator.of(context).pop(c),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Text(c.flag, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 56,
                              child: Text(
                                c.code,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                c.name,
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ),
                            if (_country.code == c.code)
                              Icon(Icons.check, color: cs.onSurface, size: 18),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (chosen == null) return;
    setState(() => _country = chosen);
  }

  Future<void> _dismissKeyboard() async {
    FocusManager.instance.primaryFocus?.unfocus();
    // Let the IME finish closing so it does not carry over onto the next screen.
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  Future<void> _continueAfterOtp(String fullPhone) async {
    await AuthStore.setPhone(fullPhone);
    if (!mounted) return;
    await _dismissKeyboard();
    if (!mounted) return;

    if (widget.embeddedInModule) {
      final done = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => const RegistrationFlowScreen(embeddedInModule: true),
        ),
      );
      if (done == true && mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    Navigator.of(context).pushNamed(Routes.registrationFlow);
  }

  Future<void> _openLoginPin(String fullPhone) async {
    await _dismissKeyboard();
    if (!mounted) return;

    if (widget.embeddedInModule) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => LoginPinScreen(
            embeddedInModule: true,
            phoneNumber: fullPhone,
          ),
        ),
      );
      if (ok == true && mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    Navigator.of(context).pushNamed(
      Routes.loginPin,
      arguments: {'phoneNumber': fullPhone},
    );
  }

  Future<void> _handleNext() async {
    if (!_isValidPhone || _submitting) return;

    // Close keyboard before lookup / navigation to PIN or OTP.
    await _dismissKeyboard();
    if (!mounted) return;

    final digits = _digitsOnly(_controller.text);
    final fullPhone = '${_country.code}$digits';

    setState(() => _submitting = true);
    try {
      final lookup = await monPeyaLookupPhone(fullPhone);
      if (!mounted) return;

      await AuthStore.setPhone(fullPhone);

      // Known Peya client → PIN login (no OTP).
      if (lookup.isRecognized) {
        await _openLoginPin(fullPhone);
        return;
      }

      // Unknown number → OTP + validation-code modal → registration.
      await monPeyaSendOtp(fullPhone);
      if (!mounted) return;

      await _dismissKeyboard();
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _OtpBottomSheet(
          onResend: () => monPeyaSendOtp(fullPhone),
          onSubmit: (code) async {
            try {
              final session = await monPeyaVerifyOtp(phone: fullPhone, code: code);
              await monPeyaPersistAuthSession(session);
              if (!context.mounted) return false;
              Navigator.of(context).pop();
              await _continueAfterOtp(fullPhone);
              return true;
            } on MonPeyaApiException {
              return false;
            }
          },
        ),
      );
    } on MonPeyaApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Connexion impossible. Vérifiez votre réseau et le backend Mon Peya.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoPath = isDark ? AssetPaths.logoDark : AssetPaths.logo;

    return AuthFlowScaffold(
      logoPath: logoPath,
      onBack: () => AuthNavigation.backFromPhoneInput(
        context,
        embeddedInModule: widget.embeddedInModule,
      ),
      title: const Text('Saisissez votre numéro de téléphone'),
      subtitle: const Text('Utilisez votre numéro de téléphone pour vous inscrire ou vous connecter.'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: _showCountryPicker,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        border: Border(
                          right: BorderSide(color: cs.outlineVariant),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_country.flag, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            _country.code,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.expand_more, size: 18, color: cs.onSurface),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.phone,
                      onChanged: (v) {
                        final next = formatPhoneNumber(v);
                        if (next != _controller.text) {
                          _controller.value = TextEditingValue(
                            text: next,
                            selection: TextSelection.collapsed(offset: next.length),
                          );
                        }
                        setState(() {});
                      },
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: '07 12 34 56 78',
                        hintStyle: TextStyle(color: cs.onSurfaceVariant),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottom: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _isValidPhone ? const Color(0xFF006D56) : const Color(0xFFB9D8CF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: (_isValidPhone && !_submitting) ? _handleNext : null,
            child: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Suivant', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}

class _OtpBottomSheet extends StatefulWidget {
  const _OtpBottomSheet({
    required this.onSubmit,
    required this.onResend,
  });

  final Future<bool> Function(String code) onSubmit;
  final Future<void> Function() onResend;

  @override
  State<_OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends State<_OtpBottomSheet> {
  static const _len = 4;
  String _code = '';
  bool _error = false;
  bool _resending = false;
  int _timer = 0;

  late final List<List<String>> _keypad;

  Future<void> _resend() async {
    if (_timer > 0 || _resending) return;
    setState(() => _resending = true);
    try {
      await widget.onResend();
      if (!mounted) return;
      _startTimer();
    } on MonPeyaApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _keypad = generateKeypad3Rows();
    _startTimer();
  }

  void _startTimer() {
    setState(() => _timer = 60);
    Future.doWhile(() async {
      if (!mounted) return false;
      if (_timer <= 0) return false;
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _timer -= 1);
      return _timer > 0;
    });
  }

  void _press(String n) {
    if (_code.length >= _len) return;
    setState(() {
      _error = false;
      _code = _code + n;
    });
  }

  void _del() {
    if (_code.isEmpty) return;
    setState(() {
      _error = false;
      _code = _code.substring(0, _code.length - 1);
    });
  }

  void _longDel() => setState(() {
        _error = false;
        _code = '';
      });

  Future<void> _submit() async {
    if (_code.length != _len) return;
    final ok = await widget.onSubmit(_code);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _error = true;
        _code = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border.all(
              color: isDark ? Colors.white : cs.outlineVariant,
              width: 0.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Code de validation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Veuillez saisir le code reçu par SMS pour continuer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _error ? cs.error : cs.outlineVariant,
                        width: _error ? 2.5 : 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_len, (i) {
                        final isFilled = _code.length > i;
                        final isActive = _code.length == i;
                        final boxBg = isActive
                            ? cs.onSurface
                            : isFilled
                                ? cs.outlineVariant
                                : cs.surfaceContainerHighest;

                        return Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: boxBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isFilled ? '•' : '',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: isActive ? cs.surface : cs.onSurface,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  if (_error) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 18, color: cs.error),
                        const SizedBox(width: 6),
                        Text(
                          'Code OTP invalide',
                          style: TextStyle(color: cs.error, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: (_timer <= 0 && !_resending) ? _resend : null,
                    child: Text(
                      _resending
                          ? 'Envoi en cours…'
                          : _timer <= 0
                              ? 'Renvoyer le code'
                              : 'Renvoyer le code dans : 00:${_timer.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _timer <= 0 ? FontWeight.w800 : FontWeight.w600,
                        color: _timer <= 0 ? cs.onSurface : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PinKeypad(
                    keypad: _keypad,
                    onKeyPress: _press,
                    onDelete: _del,
                    onLongDelete: _longDel,
                    textColor: cs.onSurface,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _code.length == _len ? const Color(0xFF111827) : cs.outlineVariant,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _code.length == _len ? _submit : null,
                      child: const Text('Suivant', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

