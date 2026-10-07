import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/features/event/utils/event_maps.util.dart';
import 'package:billetterie/src/features/event/widgets/event_ui_chrome.dart';
import 'package:billetterie/src/shared/widgets/ticket_purchase_result.dialog.dart';

/// Payload for the event details screen (mock / API-ready).
class EventDetailsData {
  const EventDetailsData({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.dateTimeLabel,
    required this.description,
    required this.place,
    required this.availableTickets,
    this.ticketNumber,
    this.city,
    this.latitude,
    this.longitude,
    this.category,
    this.galleryUrls,
    this.tip,
    this.status = 'Ouvert',
  });

  final String id;
  final String title;
  final String imageUrl;
  final String dateTimeLabel;
  final String description;
  final String place;
  final int availableTickets;
  final String? ticketNumber;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? category;
  final List<String>? galleryUrls;
  final String? tip;
  final String status;

  List<String> get images {
    final g = galleryUrls;
    if (g != null && g.isNotEmpty) return g;
    return [imageUrl, imageUrl, imageUrl, imageUrl, imageUrl];
  }
}

/// Event details — fixed header; only content scrolls.
class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({super.key, required this.data});

  final EventDetailsData data;

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _moreOpen = false;
  int _galleryIndex = 2;

  EventDetailsData get data => widget.data;

  Future<void> _share() async {
    final text = '${data.title}\n${data.dateTimeLabel}\n${data.place}';
    await Share.share(text, subject: data.title);
  }

  void _register() {
    final brand = BilletterieBrand.eventOf(context);
    if (data.availableTickets <= 0) {
      showBilletterieResultDialog(
        context,
        title: 'Complet',
        message: 'Il ne reste plus de billets pour cet événement.',
        kind: BilletterieResultKind.error,
        brand: brand,
      );
      return;
    }
    showBilletterieResultDialog(
      context,
      title: 'Bientôt disponible',
      message:
          'L’inscription ouvrira bientôt.\n${data.availableTickets} billets encore disponibles.',
      kind: BilletterieResultKind.info,
      brand: brand,
    );
  }

  Future<void> _openInGoogleMaps() async {
    final brand = BilletterieBrand.eventOf(context);
    final placeQuery = [
      data.place.trim(),
      if ((data.city ?? '').trim().isNotEmpty &&
          !data.place.toLowerCase().contains(data.city!.trim().toLowerCase()))
        data.city!.trim(),
    ].where((s) => s.isNotEmpty).join(', ');

    final opened = await openEventLocationInGoogleMaps(
      latitude: data.latitude,
      longitude: data.longitude,
      placeLabel: placeQuery.isEmpty ? data.title : placeQuery,
    );
    if (!mounted) return;
    if (!opened) {
      showBilletterieResultDialog(
        context,
        title: 'Carte indisponible',
        message:
            'Impossible d’ouvrir Google Maps pour ce lieu. Vérifiez qu’une application de cartes est installée.',
        kind: BilletterieResultKind.error,
        brand: brand,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.eventOf(context);
    final chrome = EventUiChrome.of(context);
    final accent = brand.primaryDark;
    final city = data.city ?? data.place.split(',').first.trim();
    final category = (data.category ?? 'Événement').toUpperCase();
    final ticketNo = data.ticketNumber ?? data.id;
    final images = data.images;
    final tip = data.tip ?? data.description;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: chrome.statusStyle,
      child: Scaffold(
        backgroundColor: chrome.scaffold,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fixed top.
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    _RoundIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      accent: accent,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            city,
                            style: TextStyle(
                              color: chrome.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ÉVÉNEMENT / $category',
                            style: TextStyle(
                              color: chrome.muted,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: chrome.surface,
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        onTap: _openInGoogleMaps,
                        borderRadius: BorderRadius.circular(22),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.map_outlined,
                                color: chrome.iconOnSurface.withValues(alpha: 0.85),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Carte',
                                style: TextStyle(
                                  color: chrome.text,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Scrollable content only.
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 118,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final selected = index == _galleryIndex;
                        final size = selected ? 110.0 : 86.0;
                        return GestureDetector(
                          onTap: () => setState(() => _galleryIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: size,
                            height: size,
                            margin: const EdgeInsets.only(right: 10),
                            alignment: Alignment.center,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                images[index],
                                width: size,
                                height: size,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => ColoredBox(
                                  color: chrome.surface,
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: chrome.muted,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SummaryCard(
                      accent: accent,
                      imageUrl:
                          images[_galleryIndex.clamp(0, images.length - 1)],
                      title: data.title,
                      subtitle: data.place,
                      availableTickets: data.availableTickets,
                      category: data.category ?? 'Événement',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Statut',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                data.status,
                                style: TextStyle(
                                  color: chrome.text,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF34D399),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(color: chrome.hairline, height: 1),
                        _InfoRow(
                          label: 'Date & heure',
                          value: data.dateTimeLabel,
                        ),
                        Divider(color: chrome.hairline, height: 1),
                        _InfoRow(
                          label: 'Lieu',
                          value: data.place.split(',').first.trim(),
                        ),
                        if (_moreOpen) ...[
                          Divider(color: chrome.hairline, height: 1),
                          _InfoRow(
                            label: 'Billets dispo.',
                            value:
                                '${data.availableTickets} billet${data.availableTickets > 1 ? 's' : ''}',
                          ),
                          Divider(color: chrome.hairline, height: 1),
                          _InfoRow(
                            label: 'N° ticket',
                            value: ticketNo,
                          ),
                          Divider(color: chrome.hairline, height: 1),
                          _InfoRow(
                            label: 'Adresse',
                            value: data.place,
                          ),
                        ],
                        TextButton(
                          onPressed: () =>
                              setState(() => _moreOpen = !_moreOpen),
                          style: TextButton.styleFrom(
                            foregroundColor: chrome.muted,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _moreOpen ? 'Moins d’infos' : 'Plus d’infos',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Icon(
                                _moreOpen
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      decoration: BoxDecoration(
                        color: chrome.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 3,
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tip,
                                style: TextStyle(
                                  color: chrome.text.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 26, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                color: chrome.text,
                                fontWeight: FontWeight.w500,
                                fontSize: 24,
                                fontFamily: 'Urbanist',
                              ),
                              children: [
                                const TextSpan(text: 'Programme '),
                                TextSpan(
                                  text: 'du soir',
                                  style: TextStyle(
                                    color: accent,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          '3 ÉTAPES',
                          style: TextStyle(
                            color: chrome.muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._buildProgramLog(images, chrome),
                ],
              ),
            ),
            // Fixed bottom CTA.
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    _RoundIconButton(
                      icon: Icons.ios_share_rounded,
                      accent: chrome.muted,
                      onTap: _share,
                      filled: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Material(
                        color: accent,
                        borderRadius: BorderRadius.circular(28),
                        child: InkWell(
                          onTap: _register,
                          borderRadius: BorderRadius.circular(28),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 18,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.confirmation_number_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  data.availableTickets > 0
                                      ? 'Réserver · ${data.availableTickets} dispo.'
                                      : 'Complet',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProgramLog(List<String> images, EventUiChrome chrome) {
    final steps = [
      (
        title: data.title,
        place: data.place.split(',').first.trim(),
        time: data.dateTimeLabel.contains('·')
            ? data.dateTimeLabel.split('·').last.trim()
            : data.dateTimeLabel,
        day: 'ÉTAPE 01',
        image: images.first,
      ),
      (
        title: 'Accueil & check-in',
        place: data.place.split(',').first.trim(),
        time: 'Ouverture',
        day: 'ÉTAPE 02',
        image: images.length > 1 ? images[1] : images.first,
      ),
      (
        title: 'Clôture',
        place: cityFallback,
        time: 'Fin',
        day: 'ÉTAPE 03',
        image: images.length > 2 ? images[2] : images.first,
      ),
    ];

    return [
      for (var i = 0; i < steps.length; i++)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: chrome.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: chrome.border),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: chrome.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (i < steps.length - 1)
                      Container(
                        width: 2,
                        height: 64,
                        margin: const EdgeInsets.only(top: 4),
                        color: chrome.hairline,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: chrome.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          steps[i].image,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => ColoredBox(
                            color: chrome.hairline,
                            child: const SizedBox(width: 52, height: 52),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              steps[i].title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: chrome.text,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              steps[i].place,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: chrome.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            steps[i].time,
                            style: TextStyle(
                              color: chrome.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            steps[i].day,
                            style: TextStyle(
                              color: chrome.muted,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  String get cityFallback =>
      data.city ?? data.place.split(',').first.trim();
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.accent,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final chrome = EventUiChrome.of(context);
    return Material(
      color: filled ? chrome.surface : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: filled ? chrome.border : accent.withValues(alpha: 0.7),
              width: 1.4,
            ),
          ),
          child: Icon(
            icon,
            color: filled ? chrome.iconOnSurface : accent,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.accent,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.availableTickets,
    required this.category,
  });

  final Color accent;
  final String imageUrl;
  final String title;
  final String subtitle;
  final int availableTickets;
  final String category;

  @override
  Widget build(BuildContext context) {
    final chrome = EventUiChrome.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: chrome.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 92,
              height: 92,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: chrome.hairline,
                    ),
                  ),
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        availableTickets > 0 ? 'Dispo' : 'Complet',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: chrome.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
                          fontFamily: 'Urbanist',
                          fontStyle: FontStyle.italic,
                          height: 1.15,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      height: 28,
                      child: Stack(
                        children: [
                          for (var i = 0; i < 3; i++)
                            Positioned(
                              left: i * 14.0,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Color.lerp(
                                  accent,
                                  Colors.white,
                                  i * 0.15,
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 12,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: chrome.muted,
                    fontWeight: FontWeight.w500,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MiniBadge(
                      icon: Icons.confirmation_number_outlined,
                      label: '$availableTickets billets',
                    ),
                    _MiniBadge(
                      icon: Icons.category_outlined,
                      label: category,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final chrome = EventUiChrome.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chrome.isLight
            ? chrome.brand.primarySoft
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chrome.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: chrome.muted),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: chrome.text,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    this.value,
    this.trailing,
  });

  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final chrome = EventUiChrome.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: chrome.muted,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            trailing!
          else
            Flexible(
              child: Text(
                value ?? '',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: chrome.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> openEventDetails(
  BuildContext context,
  EventDetailsData data,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => EventDetailsScreen(data: data),
    ),
  );
}
