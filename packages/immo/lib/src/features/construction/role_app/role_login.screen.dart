import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/construction/navigation/construction.tab.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';
import 'package:immo/src/shared/widgets/immo_pin_keypad.widget.dart';
import 'package:immo/src/shared/widgets/immo_sheet.widget.dart';

/// Sign-in of a single-role app, as Mon Peya's: the code client (phone number), then the
/// 4-digit PIN on a shuffled keypad, sent as soon as the 4th digit is typed.
class RoleLoginScreen extends StatefulWidget {
  const RoleLoginScreen({
    super.key,
    required this.role,
    required this.onSubmit,
    this.initialCodeClient,
  });

  final ConstructionRole role;

  /// Returns null once signed in, or the message to show.
  final Future<String?> Function(String codeClient, String pin) onSubmit;

  /// The code client last used: opens straight on the PIN.
  final String? initialCodeClient;

  @override
  State<RoleLoginScreen> createState() => _RoleLoginScreenState();
}

class _RoleLoginScreenState extends State<RoleLoginScreen> {
  static const _pinLength = 4;

  late final _code = TextEditingController(text: widget.initialCodeClient);
  late String? _codeClient = widget.initialCodeClient;
  String _pin = '';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _continue() {
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Saisissez votre code client.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _codeClient = code;
      _pin = '';
      _error = null;
    });
  }

  void _changeCode() => setState(() {
        _codeClient = null;
        _pin = '';
        _error = null;
      });

  void _digit(String d) {
    if (_busy || _pin.length >= _pinLength) return;
    setState(() {
      _error = null;
      _pin += d;
    });
    if (_pin.length == _pinLength) _submit();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final error = await widget.onSubmit(_codeClient!, _pin);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
      _pin = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ImmoHeaderPage(
        eyebrow: 'Mr Immo Construction',
        title: widget.role.label,
        subtitle: 'Espace professionnel',
        trailing: Icon(widget.role.icon, color: Colors.white, size: 30),
        body: _codeClient == null ? _codeStep(context) : _pinStep(context),
      ),
    );
  }

  Widget _codeStep(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return ListView(
      padding: const EdgeInsets.all(ImmoSpacing.lg),
      children: [
        const ImmoSectionTitle('Connexion'),
        Text(
          'Votre code client est le numéro de téléphone de votre compte.',
          style: TextStyle(fontSize: 13.5, color: b.muted, height: 1.4),
        ),
        const SizedBox(height: ImmoSpacing.lg),
        const ImmoFieldLabel('Code client'),
        TextField(
          controller: _code,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          autofillHints: const [AutofillHints.telephoneNumber, AutofillHints.username],
          onSubmitted: (_) => _continue(),
          style: TextStyle(color: b.text),
          decoration: immoFieldDecoration(context, hintText: 'Ex. 07 00 00 02 03'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: b.danger, fontSize: 13.5)),
        ],
        const SizedBox(height: ImmoSpacing.lg),
        FilledButton(
          onPressed: _continue,
          style: FilledButton.styleFrom(
            backgroundColor: b.primary,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          ),
          child: const Text('Continuer'),
        ),
      ],
    );
  }

  Widget _pinStep(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(ImmoSpacing.lg, ImmoSpacing.lg, ImmoSpacing.lg, ImmoSpacing.md),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - ImmoSpacing.lg - ImmoSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    'Entrez votre code PIN',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: b.text),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'Code client $_codeClient',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.5, color: b.muted),
                        ),
                      ),
                      TextButton(
                        onPressed: _busy ? null : _changeCode,
                        style: TextButton.styleFrom(foregroundColor: b.primary),
                        child: const Text('Changer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: ImmoSpacing.md),
                  _PinBoxes(filled: _pin.length, length: _pinLength, error: _error != null),
                  SizedBox(
                    height: 56,
                    child: Center(
                      child: _busy
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: b.primary),
                            )
                          : _error == null
                              ? null
                              : Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: b.danger, fontSize: 13.5, height: 1.35),
                                ),
                    ),
                  ),
                ],
              ),
              ImmoPinKeypad(
                enabled: !_busy,
                onDigit: _digit,
                onDelete: () => setState(() {
                  if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
                }),
                onClear: () => setState(() => _pin = ''),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The 4 boxes of Mon Peya's PIN screen; a dot per digit typed.
class _PinBoxes extends StatelessWidget {
  const _PinBoxes({required this.filled, required this.length, required this.error});

  final int filled;
  final int length;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Semantics(
      label: 'Code PIN, $filled chiffres sur $length',
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: b.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: error ? b.danger : b.border, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < length; i++)
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: b.searchFill, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  i < filled ? '•' : '',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: b.text),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
