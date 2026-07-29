import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:app/src/core/assets/constants/asset.paths.dart';
import 'package:app/src/core/auth/auth.navigation.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/core/widgets/pin_keypad.widget.dart';
import 'package:app/src/features/auth/presentation/widgets/auth_flow_scaffold.widget.dart';
import 'package:app/src/integration/adapters/peyapay_host.adapter.dart';

class RegistrationFlowScreen extends StatefulWidget {
  const RegistrationFlowScreen({super.key, this.embeddedInModule = false});
  static const routeName = '/registration-flow';

  final bool embeddedInModule;

  @override
  State<RegistrationFlowScreen> createState() => _RegistrationFlowScreenState();
}

class _RegistrationFlowScreenState extends State<RegistrationFlowScreen> {
  int _step = 0; // 0: ID photos, 1: Identity + email, 2: PIN
  bool _busy = false;
  final _picker = ImagePicker();

  XFile? _idRecto;
  XFile? _idVerso;

  final _lastName = TextEditingController();
  final _firstName = TextEditingController();
  final _email = TextEditingController();
  final _idNumber = TextEditingController();
  final _birthDate = TextEditingController();
  final _birthPlace = TextEditingController();
  final _profession = TextEditingController();
  String _sex = ''; // 'M' | 'F'

  String _pin = '';
  String _confirmPin = '';
  bool _pinError = false;

  late final List<List<String>> _keypad;

  @override
  void initState() {
    super.initState();
    _keypad = generateKeypad3Rows();
  }

  @override
  void dispose() {
    _lastName.dispose();
    _firstName.dispose();
    _email.dispose();
    _idNumber.dispose();
    _birthDate.dispose();
    _birthPlace.dispose();
    _profession.dispose();
    super.dispose();
  }

  bool get _idPhotosOk => _idRecto != null;

  bool get _identityOk {
    final ln = _lastName.text.trim();
    final fn = _firstName.text.trim();
    final em = _email.text.trim();
    final emailOk = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(em);
    return ln.isNotEmpty && fn.isNotEmpty && emailOk;
  }

  bool get _pinOk => _pin.length == 4 && _confirmPin.length == 4 && _pin == _confirmPin;

  static String _formatDateFr(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString().padLeft(4, '0');
    return '$dd/$mm/$yyyy';
  }

  Future<void> _pickBirthDate() async {
    if (_busy) return;

    final now = DateTime.now();
    final lastDate = DateTime(now.year - 18, now.month, now.day);
    final firstDate = DateTime(now.year - 100, 1, 1);

    DateTime selected = lastDate;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border.all(
                color: isDark ? Colors.white : cs.outlineVariant,
                width: 0.5,
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: StatefulBuilder(
                  builder: (context, setLocal) {
                    return Column(
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
                        const SizedBox(height: 14),
                        Text(
                          'Date de naissance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        CalendarDatePicker(
                          initialDate: selected,
                          firstDate: firstDate,
                          lastDate: lastDate,
                          onDateChanged: (d) => setLocal(() => selected = d),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF006D56),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Valider', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    _birthDate.text = _formatDateFr(selected);
    setState(() {});
  }

  Future<void> _pickIdPhoto({required bool recto}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Material(
            color: cs.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                      recto ? 'Recto de la carte' : 'Verso de la carte',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Prendre une photo ou choisir une image',
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    _SheetButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Prendre une photo',
                      onTap: () => Navigator.of(context).pop(ImageSource.camera),
                    ),
                    const SizedBox(height: 10),
                    _SheetButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Choisir dans la galerie',
                      onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (source == null) return;
    final x = await _picker.pickImage(source: source, imageQuality: 85);
    if (!mounted || x == null) return;
    setState(() {
      if (recto) {
        _idRecto = x;
      } else {
        _idVerso = x;
      }
    });
  }

  Future<void> _next() async {
    if (_busy) return;
    if (_step == 0) {
      if (!_idPhotosOk) return;
      setState(() => _step = 1);
      return;
    }

    if (_step == 1) {
      if (!_identityOk) return;
      setState(() => _step = 2);
      return;
    }

    setState(() => _busy = true);
    final phone = await AuthStore.getPhone();
    if (phone == null || phone.trim().isEmpty || !_pinOk) {
      setState(() {
        _busy = false;
        _pinError = true;
      });
      return;
    }

    await AuthStore.setPinForPhone(phone.trim(), _pin);
    await AuthStore.setSessionRegistered(true);
    activateMonPeyaSession();
    notifyMonPeyaSessionChanged();
    if (!mounted) return;
    setState(() => _busy = false);
    if (widget.embeddedInModule) {
      Navigator.of(context).pop(true);
      return;
    }
    AuthNavigation.completeAuthFlow(context);
  }

  void _back() {
    if (_busy) return;
    if (_step == 0) {
      AuthNavigation.backFromRegistration(
        context,
        embeddedInModule: widget.embeddedInModule,
      );
      return;
    }
    setState(() => _step -= 1);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoPath = isDark ? AssetPaths.logoDark : AssetPaths.logo;

    final (stepTitle, stepSubtitle) = switch (_step) {
      0 => ("Ajoutez votre pièce d'identité", 'Prenez une photo du recto (obligatoire) et du verso (optionnel).'),
      1 => ('Vos informations', 'Renseignez vos informations manuellement.'),
      _ => ('Créez votre code PIN', 'Choisissez un code à 4 chiffres.'),
    };

    final canNext = switch (_step) {
      0 => _idPhotosOk,
      1 => _identityOk,
      _ => _pin.length == 4 && _confirmPin.length == 4,
    };

    return AuthFlowScaffold(
      logoPath: logoPath,
      onBack: _back,
      title: Text(stepTitle),
      subtitle: Text(stepSubtitle),
      headerBottom: LinearProgressIndicator(
        value: (_step + 1) / 3,
        backgroundColor: cs.surfaceContainerHighest,
        color: const Color(0xFF006D56),
        minHeight: 6,
        borderRadius: BorderRadius.circular(999),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        children: [
          if (_step == 0) ...[
            _IdPhotoTile(
              title: 'Recto',
              subtitle: 'Obligatoire',
              file: _idRecto,
              onTap: () => _pickIdPhoto(recto: true),
            ),
            const SizedBox(height: 12),
            _IdPhotoTile(
              title: 'Verso',
              subtitle: 'Optionnel',
              file: _idVerso,
              onTap: () => _pickIdPhoto(recto: false),
            ),
          ] else if (_step == 1) ...[
            _Field(label: 'Nom', controller: _lastName, onChanged: () => setState(() {})),
            const SizedBox(height: 12),
            _Field(label: 'Prénoms', controller: _firstName, onChanged: () => setState(() {})),
            const SizedBox(height: 12),
            _Field(
              label: 'Email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            _Field(label: 'Numéro CNI', controller: _idNumber, onChanged: () => setState(() {})),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    label: 'Date de naissance',
                    controller: _birthDate,
                    hint: 'JJ/MM/AAAA',
                    readOnly: true,
                    onTap: _pickBirthDate,
                    onChanged: () => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SexPicker(
                    value: _sex,
                    onChanged: (v) => setState(() => _sex = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Field(label: 'Lieu de naissance', controller: _birthPlace, onChanged: () => setState(() {})),
            const SizedBox(height: 12),
            _Field(label: 'Profession', controller: _profession, onChanged: () => setState(() {})),
          ] else ...[
            _PinBoxes(
              pin: _pin,
              confirmPin: _confirmPin,
              showError: _pinError,
            ),
            if (_pinError) ...[
              const SizedBox(height: 8),
              Text(
                'Les codes PIN ne correspondent pas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.error, fontWeight: FontWeight.w800),
              ),
            ],
            const SizedBox(height: 16),
            PinKeypad(
              keypad: _keypad,
              onKeyPress: (n) {
                setState(() {
                  _pinError = false;
                  if (_pin.length < 4) {
                    _pin = _pin + n;
                    return;
                  }
                  if (_confirmPin.length < 4) {
                    _confirmPin = _confirmPin + n;
                  }
                });
              },
              onDelete: () {
                setState(() {
                  _pinError = false;
                  if (_confirmPin.isNotEmpty) {
                    _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
                    return;
                  }
                  if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
                });
              },
              onLongDelete: () => setState(() {
                _pinError = false;
                _pin = '';
                _confirmPin = '';
              }),
              textColor: cs.onSurface,
            ),
          ],
        ],
      ),
      bottom: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: canNext ? const Color(0xFF006D56) : const Color(0xFFB9D8CF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: (_busy || !canNext)
                  ? null
                  : () async {
                      if (_step == 2 && _pin.length == 4 && _confirmPin.length == 4 && _pin != _confirmPin) {
                        setState(() => _pinError = true);
                        return;
                      }
                      await _next();
                    },
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Suivant', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: cs.onSurface),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _IdPhotoTile extends StatelessWidget {
  const _IdPhotoTile({
    required this.title,
    required this.subtitle,
    required this.file,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final XFile? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: file != null
                    ? Image.network(
                        file!.path,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      )
                    : const SizedBox(),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: file != null ? 0.35 : 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: file != null ? Colors.white : cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: file != null ? Colors.white70 : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: (file != null ? Colors.white.withValues(alpha: 0.22) : cs.surface),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Icon(
                      file != null ? Icons.edit_outlined : Icons.add_a_photo_outlined,
                      color: file != null ? Colors.white : cs.onSurface,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            if (file == null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.badge_outlined, size: 34, color: cs.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(
                      'Ajouter une photo',
                      style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.keyboardType,
    this.hint,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.onSurface),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: cs.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.outlineVariant)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.outlineVariant)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onChanged: (_) => onChanged(),
          onTap: onTap,
        ),
      ],
    );
  }
}

class _SexPicker extends StatelessWidget {
  const _SexPicker({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sexe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.onSurface)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value.isEmpty ? null : value,
          items: const [
            DropdownMenuItem(value: 'M', child: Text('Homme')),
            DropdownMenuItem(value: 'F', child: Text('Femme')),
          ],
          onChanged: (v) => onChanged(v ?? ''),
          decoration: InputDecoration(
            filled: true,
            fillColor: cs.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.outlineVariant)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.outlineVariant)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _PinBoxes extends StatelessWidget {
  const _PinBoxes({required this.pin, required this.confirmPin, required this.showError});
  final String pin;
  final String confirmPin;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget row(String label, String value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 8),
          Container(
            width: 256,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: showError ? cs.error : cs.outlineVariant,
                width: showError ? 2.5 : 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                return Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    value.length > i ? '•' : '',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: cs.onSurface),
                  ),
                );
              }),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        row('PIN', pin),
        const SizedBox(height: 14),
        row('Confirmer', confirmPin),
      ],
    );
  }
}

