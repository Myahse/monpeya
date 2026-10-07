import 'package:flutter/material.dart';

import 'package:grenier/src/core/host/grenier_host.bridge.dart';
import 'package:grenier/src/presentation/widgets/grenier_ui.dart';

/// Consent screen: creates the Mon Grenier account from Mon Peya details.
/// Nothing is sent before the user ticks the box and confirms.
class GrenierLinkScreen extends StatefulWidget {
  const GrenierLinkScreen({
    super.key,
    required this.profile,
    required this.onCreate,
    required this.onLater,
  });

  final GrenierHostProfile? profile;

  /// Creates the account; returns an error message, or null on success.
  final Future<String?> Function() onCreate;
  final VoidCallback onLater;

  @override
  State<GrenierLinkScreen> createState() => _GrenierLinkScreenState();
}

enum _Step { idle, loading, done }

class _GrenierLinkScreenState extends State<GrenierLinkScreen> {
  bool _accepted = false;
  _Step _step = _Step.idle;
  String? _error;

  Future<void> _create() async {
    setState(() {
      _step = _Step.loading;
      _error = null;
    });
    final error = await widget.onCreate();
    if (!mounted) return;
    setState(() {
      _step = error == null ? _Step.done : _Step.idle;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final canCreate = _accepted && _step == _Step.idle;

    return Scaffold(
      backgroundColor: GrenierColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(24, top + 24, 24, 16),
              children: [
                const GrenierRise(child: _LinkVisual()),
                const SizedBox(height: 22),
                const GrenierRise(
                  delay: Duration(milliseconds: 80),
                  child: Column(
                    children: [
                      Text(
                        'Créer votre compte Mon Grenier',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.15),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Mon Grenier est un service partenaire. Pour l’utiliser, nous créons votre compte chez eux avec vos informations Mon Peya.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.5, color: Color(0xFF4B5563), height: 1.45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                GrenierRise(
                  delay: const Duration(milliseconds: 160),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: grenierCard(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INFORMATIONS PARTAGÉES',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: GrenierColors.primary,
                            letterSpacing: .3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SharedField(
                          label: 'Prénom et nom',
                          value: profile?.fullName ?? 'Vous serez invité à vous connecter à Mon Peya',
                        ),
                        if (profile?.phone != null) ...[
                          const SizedBox(height: 12),
                          _SharedField(label: 'Téléphone', value: profile!.phone!),
                        ],
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFF0F1F0)),
                        const SizedBox(height: 10),
                        const Text(
                          'Votre code PIN et votre solde Peya Pay ne sont jamais partagés.',
                          style: TextStyle(fontSize: 12.5, color: GrenierColors.muted, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                GrenierRise(
                  delay: const Duration(milliseconds: 240),
                  child: InkWell(
                    onTap: _step == _Step.idle
                        ? () => setState(() => _accepted = !_accepted)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _accepted,
                          activeColor: GrenierColors.primary,
                          onChanged: _step == _Step.idle
                              ? (v) => setState(() => _accepted = v ?? false)
                              : null,
                        ),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              'J’accepte que Mon Peya transmette ces informations à Mon Grenier pour créer mon compte.',
                              style: TextStyle(fontSize: 13.5, color: Color(0xFF374151), height: 1.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _error == null
                      ? const SizedBox.shrink()
                      : Padding(
                          key: ValueKey(_error),
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                          ),
                        ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _step == _Step.done
                      ? const _DoneBanner()
                      : SizedBox(
                          key: const ValueKey('cta'),
                          height: 54,
                          child: FilledButton(
                            onPressed: canCreate ? _create : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: GrenierColors.primary,
                              disabledBackgroundColor: const Color(0xFFE5E7EB),
                              disabledForegroundColor: GrenierColors.muted,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_step == _Step.loading) ...[
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Text(
                                  _step == _Step.loading ? 'Création du compte…' : 'Créer mon compte',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 44,
                  child: TextButton(
                    onPressed: _step == _Step.loading ? null : widget.onLater,
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF4B5563)),
                    child: Text(
                      _step == _Step.done ? 'Continuer' : 'Plus tard',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SharedField extends StatelessWidget {
  const _SharedField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: GrenierColors.soft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.check_rounded, color: GrenierColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12.5, color: GrenierColors.muted)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mon Peya → Mon Grenier, with dots flowing between the two.
class _LinkVisual extends StatefulWidget {
  const _LinkVisual();

  @override
  State<_LinkVisual> createState() => _LinkVisualState();
}

class _LinkVisualState extends State<_LinkVisual> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _badge(String text, {required bool filled}) => Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? GrenierColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: filled ? null : Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            height: 1.1,
            fontWeight: FontWeight.w800,
            color: filled ? Colors.white : const Color(0xFF006D56),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _badge('Mon\nPeya', filled: false),
        const SizedBox(width: 14),
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Transform.translate(
            offset: Offset(6 * Curves.easeInOut.transform(_c.value), 0),
            child: Row(
              children: [
                for (final a in const [0.35, 0.65, 1.0])
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: GrenierColors.primary.withValues(alpha: a),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        _badge('Mon\nGrenier', filled: true),
      ],
    );
  }
}

class _DoneBanner extends StatelessWidget {
  const _DoneBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('done'),
      height: 54,
      decoration: BoxDecoration(
        color: GrenierColors.soft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, t, child) => Transform.scale(scale: t, child: child),
            child: const Icon(Icons.check_circle_rounded, color: GrenierColors.dark),
          ),
          const SizedBox(width: 8),
          const Text(
            'Compte créé',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: GrenierColors.dark),
          ),
        ],
      ),
    );
  }
}
