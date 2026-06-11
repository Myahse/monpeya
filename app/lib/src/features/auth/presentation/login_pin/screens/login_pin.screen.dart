import 'dart:async';

import 'package:flutter/material.dart';
import 'package:immo/immo.dart';

import 'package:app/src/core/assets/constants/asset.paths.dart';
import 'package:app/src/core/auth/biometric.auth.dart';
import 'package:app/src/core/routing/routes.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/core/widgets/pin_keypad.widget.dart';
import 'package:app/src/integration/adapters/peyapay_host.adapter.dart';

class LoginPinScreen extends StatefulWidget {
  const LoginPinScreen({
    super.key,
    this.embeddedInModule = false,
    this.phoneNumber,
  });

  static const routeName = '/login-pin';

  final bool embeddedInModule;
  final String? phoneNumber;

  @override
  State<LoginPinScreen> createState() => _LoginPinScreenState();
}

class _LoginPinScreenState extends State<LoginPinScreen> {
  String _pin = '';
  bool _showError = false;
  bool _submitting = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _autoBiometricAttempted = false;
  String? _phoneNumber;
  late final List<List<String>> _keypad;

  @override
  void initState() {
    super.initState();
    _keypad = generateKeypad3Rows();
    _phoneNumber = widget.phoneNumber;
    _bootstrap();
  }

  Future<void> _refreshBiometricState() async {
    final available = await BiometricAuth.canUseBiometrics();
    final enabled = await BiometricAuth.isEnabledInSettings();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });

    final phone = _phoneNumber;
    if (!available || phone == null) return;

    final hasPin = await AuthStore.hasPinForPhone(phone);
    if (!mounted || !hasPin) return;

    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometricLogin(auto: true));
  }

  Future<void> _bootstrap() async {
    _phoneNumber ??= await AuthStore.getPhone();
    await _refreshBiometricState();
  }

  String? _readPhoneArg() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['phoneNumber'] is String) {
      return args['phoneNumber'] as String;
    }
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _phoneNumber ??= widget.phoneNumber ?? _readPhoneArg();
  }

  void _onKeyPress(String n) {
    if (_pin.length >= 4 || _submitting) return;
    setState(() {
      _showError = false;
      _pin = _pin + n;
    });
    if (_pin.length == 4) {
      final phone = _phoneNumber;
      if (phone != null) _submit(phone);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty || _submitting) return;
    setState(() {
      _showError = false;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  void _onLongDelete() {
    if (_submitting) return;
    setState(() {
      _showError = false;
      _pin = '';
    });
  }

  void _syncImmoSessionInBackground(String phone, String pin) {
    unawaited(
      ImmoAuthService().loginWithPhoneAndPin(
        phone: phone,
        pin: pin,
        apiClient: ImmoApiClient(),
      ),
    );
  }

  Future<void> _completeLogin(String phone, String pin) async {
    await AuthStore.setSessionRegistered(true);
    activateMonPeyaSession();
    notifyMonPeyaSessionChanged();
    _syncImmoSessionInBackground(phone, pin);
    if (!mounted) return;
    if (widget.embeddedInModule) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
      return;
    }
    Navigator.of(context).pushReplacementNamed(Routes.app);
  }

  Future<void> _submit(String phone) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final stored = await AuthStore.getPinForPhone(phone);
    if (!mounted) return;

    if (stored != null && stored == _pin) {
      await _completeLogin(phone, _pin);
      return;
    }

    setState(() {
      _submitting = false;
      _showError = true;
      _pin = '';
    });
  }

  Future<void> _tryBiometricLogin({bool auto = false}) async {
    if (_submitting) return;
    if (auto) {
      if (_autoBiometricAttempted) return;
      _autoBiometricAttempted = true;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted || _submitting) return;
    }
    if (!_biometricAvailable) return;

    final phone = _phoneNumber;
    if (phone == null) return;

    final hasPin = await AuthStore.hasPinForPhone(phone);
    if (!mounted || !hasPin) return;

    final ok = await BiometricAuth.authenticate(
      reason: widget.embeddedInModule
          ? 'Déverrouillez PeyaPay avec la biométrie'
          : 'Déverrouillez Mon Peya avec la biométrie',
    );
    if (!mounted || !ok) return;

    if (!_biometricEnabled) {
      await BiometricAuth.setEnabledInSettings(true);
      if (mounted) setState(() => _biometricEnabled = true);
    }

    final pin = await AuthStore.getPinForPhone(phone);
    if (!mounted || pin == null) return;

    setState(() => _submitting = true);
    await _completeLogin(phone, pin);
  }

  @override
  Widget build(BuildContext context) {
    final phoneNumber = _phoneNumber;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? cs.surface : Colors.white;
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);
    final logoPath = isDark ? AssetPaths.logoDark : AssetPaths.logo;

    if (phoneNumber == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final stored = await AuthStore.getPhone();
        if (!mounted) return;
        if (stored != null) {
          setState(() => _phoneNumber = stored);
          unawaited(_refreshBiometricState());
          return;
        }
        if (widget.embeddedInModule) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(false);
          }
        } else {
          Navigator.of(context).pushReplacementNamed(Routes.phoneInput);
        }
      });
    }

    final showBiometric = _biometricAvailable && phoneNumber != null;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 24),
                  Image.asset(
                    logoPath,
                    width: 200,
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Entrez votre code PIN',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ink),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 240,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? cs.surfaceContainerHighest : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _showError ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        return Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isDark ? cs.surface : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _pin.length > i ? '•' : '',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  if (_showError)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Code PIN incorrect. Réessayez.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFEF4444)),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  children: [
                    PinKeypad(
                      keypad: _keypad,
                      onKeyPress: _onKeyPress,
                      onDelete: _onDelete,
                      onLongDelete: _onLongDelete,
                      textColor: ink,
                      showBiometric: showBiometric,
                      onBiometric: () => _tryBiometricLogin(),
                      biometricEnabled: !_submitting,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.8,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _pin.length == 4 ? const Color(0xFF006D56) : const Color(0xFFB9D8CF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: (_pin.length == 4 && phoneNumber != null && !_submitting)
                            ? () => _submit(phoneNumber)
                            : null,
                        child: _submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Valider', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
