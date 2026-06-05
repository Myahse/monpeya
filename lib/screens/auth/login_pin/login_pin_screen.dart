import 'package:flutter/material.dart';

import '../../../app/assets/asset_paths.dart';
import '../../../app/routing/routes.dart';
import '../../../app/storage/auth_store.dart';
import '../../../app/widgets/pin_keypad.dart';

class LoginPinScreen extends StatefulWidget {
  const LoginPinScreen({super.key});
  static const routeName = '/login-pin';

  @override
  State<LoginPinScreen> createState() => _LoginPinScreenState();
}

class _LoginPinScreenState extends State<LoginPinScreen> {
  String _pin = '';
  bool _showError = false;
  late final List<List<String>> _keypad;

  @override
  void initState() {
    super.initState();
    _keypad = generateKeypad3Rows();
  }

  void _onKeyPress(String n) {
    if (_pin.length >= 4) return;
    setState(() {
      _showError = false;
      _pin = _pin + n;
    });
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      _showError = false;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  void _onLongDelete() => setState(() {
        _showError = false;
        _pin = '';
      });

  Future<void> _submit(String phone) async {
    final stored = await AuthStore.getPinForPhone(phone);
    if (!mounted) return;
    if (stored != null && stored == _pin) {
      await AuthStore.setSessionRegistered(true);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(Routes.app);
      return;
    }
    setState(() {
      _showError = true;
      _pin = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final phoneNumber = (args is Map && args['phoneNumber'] is String) ? args['phoneNumber'] as String : null;

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? cs.surface : Colors.white;
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);

    final logoPath = isDark ? AssetPaths.logoDark : AssetPaths.logo;

    if (phoneNumber == null) {
      // Defensive: go back to phone input if missing.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(Routes.phoneInput);
      });
    }

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
                  const SizedBox(height: 34),
                  Image.asset(
                    logoPath,
                    width: 256,
                    height: 115,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Entrez votre code PIN',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Saisissez votre code PIN à 4 chiffres pour vous connecter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: 256,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _showError ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF), width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        return Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _pin.length > i ? '•' : '',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
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
                padding: const EdgeInsets.only(bottom: 22),
                child: Column(
                  children: [
                    PinKeypad(
                      keypad: _keypad,
                      onKeyPress: _onKeyPress,
                      onDelete: _onDelete,
                      onLongDelete: _onLongDelete,
                      textColor: ink,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.8,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _pin.length == 4 ? const Color(0xFF006D56) : const Color(0xFFB9D8CF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: (_pin.length == 4 && phoneNumber != null) ? () => _submit(phoneNumber) : null,
                        child: const Text('Valider', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

