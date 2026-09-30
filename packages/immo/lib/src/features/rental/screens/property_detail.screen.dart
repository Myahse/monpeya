import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/models/rental.property.dart';
import 'package:immo/src/features/rental/services/rental_data.cache.dart';
import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';
import 'package:immo/src/features/rental/utils/rental_maps.util.dart';
import 'package:immo/src/features/rental/widgets/rental_layout_widgets.widget.dart';
import 'package:immo/src/features/rental/widgets/rental_skeleton.widget.dart';
import 'package:immo/src/shared/config/map_tiles.config.dart';

/// Property detail — mockup layout (hero, provider card, CTAs, map).
class PropertyDetailScreen extends StatefulWidget {
  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
    required this.onBack,
    this.initialProperty,
  });

  final String propertyId;
  final VoidCallback onBack;
  /// When opening from a list/map card, show immediately while refreshing.
  final RentalProperty? initialProperty;

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen>
    with SingleTickerProviderStateMixin {
  RentalProperty? _property;
  String? _error;
  int _imageIndex = 0;
  bool _favorite = false;
  bool _favoriteBusy = false;

  AnimationController? _entranceController;
  Animation<double>? _entrance;
  bool _entranceStarted = false;

  static const _sheetOverlap = 48.0;
  static const _sheetRevealTravel = 56.0;
  static const _heroOverlayStyle = SystemUiOverlayStyle(
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  void _ensureEntranceAnimation() {
    if (_entranceController != null) return;
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entrance = CurvedAnimation(
      parent: _entranceController!,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void initState() {
    super.initState();
    _property = widget.initialProperty ??
        RentalDataCache.instance.propertyById(widget.propertyId);
    _ensureEntranceAnimation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
      _maybeStartEntrance();
    });
  }

  @override
  void dispose() {
    _entranceController?.dispose();
    super.dispose();
  }

  void _maybeStartEntrance() {
    if (_entranceStarted || _property == null) return;
    _entranceStarted = true;
    _ensureEntranceAnimation();
    _entranceController!.forward(from: 0);
  }

  Future<void> _load() async {
    // Already showing list/cache data — refresh quietly, don't flash loading.
    final hasPaint = _property != null;
    if (!hasPaint) {
      setState(() => _error = null);
    }
    try {
      final session = RentalSessionScope.of(context);
      final property = await session.api.properties.fetchPropertyById(
        widget.propertyId,
        forceRefresh: !hasPaint,
      );
      if (!mounted) return;
      setState(() {
        _property = property ?? widget.initialProperty ?? _property;
        if (_property == null) {
          _error = 'Bien introuvable';
        } else {
          _error = null;
        }
      });
      _maybeStartEntrance();
      await _refreshFavoriteState();
    } catch (e) {
      if (!mounted) return;
      if (_property != null) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _refreshFavoriteState() async {
    final session = RentalSessionScope.of(context);
    final userId = session.userId;
    final propertyId = _property?.id ?? widget.propertyId;
    if (!session.authenticated || userId == null || userId.isEmpty) {
      if (mounted) setState(() => _favorite = false);
      return;
    }
    try {
      final favored = await session.api.favorites.isFavorited(
        userId: userId,
        propertyId: propertyId,
      );
      if (mounted) setState(() => _favorite = favored);
    } catch (_) {
      // Keep current heart state if the check fails.
    }
  }

  String _priceLabel(RentalProperty p) {
    if (p.price <= 0) return '—';
    final formatted = p.price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
    return '$formatted Fcfa';
  }

  String _surfaceLabel(RentalProperty p) {
    if (p.surface <= 0) return '';
    final v = p.surface == p.surface.roundToDouble()
        ? p.surface.toInt().toString()
        : p.surface.toStringAsFixed(0);
    return '$v m2';
  }

  String _locationLine(RentalProperty p) {
    final city = p.city.trim();
    final address = p.address.trim();
    if (city.isEmpty) return address.isEmpty ? '—' : address;
    if (address.isEmpty) return city;
    final short = address.split(',').first.trim();
    if (short.isEmpty || short.toLowerCase() == city.toLowerCase()) {
      return city;
    }
    return '$city, $short';
  }

  String _providerLabel(RentalProperty p) {
    final name = p.ownerName.trim();
    if (name.isEmpty) return 'Provider';
    return 'La $name';
  }

  double _rating(RentalProperty p) {
    if (p.rating <= 0) return 0;
    return p.rating.clamp(0, 5);
  }

  Future<void> _callProvider(RentalProperty p) async {
    final phone = p.ownerPhone.trim();
    if (phone.isEmpty) {
      _toast('Aucun numéro disponible');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    final ok = await launchUrl(uri);
    if (!ok && mounted) _toast('Impossible d\'appeler');
  }

  Future<void> _contactProvider(RentalProperty p) async {
    final email = p.ownerEmail.trim();
    final phone = p.ownerPhone.trim();
    if (email.isNotEmpty) {
      final uri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {'subject': 'Mr Immo — ${p.title}'},
      );
      final ok = await launchUrl(uri);
      if (ok) return;
    }
    if (phone.isNotEmpty) {
      final uri = Uri(
        scheme: 'sms',
        path: phone,
        queryParameters: {'body': 'Bonjour, je suis intéressé par ${p.title}.'},
      );
      final ok = await launchUrl(uri);
      if (ok) return;
    }
    if (mounted) _toast('Aucun contact disponible');
  }

  Future<void> _share(RentalProperty p) async {
    final text = '${p.title}\n${_locationLine(p)}\n${_priceLabel(p)} / month';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _toast('Détails copiés');
  }

  Future<void> _toggleFavorite(RentalProperty p) async {
    if (_favoriteBusy) return;

    var session = RentalSessionScope.of(context);
    if (!session.authenticated) {
      final ok = await session.ensureImmoReady(context);
      if (!mounted || !ok) {
        _toast(
          RentalSessionScope.of(context).immoLinkError ??
              'Connectez-vous pour ajouter aux favoris',
        );
        return;
      }
      session = RentalSessionScope.of(context);
    }
    final userId = session.userId;
    if (userId == null || userId.isEmpty) {
      _toast('Compte Mr Immo introuvable pour ce numéro.');
      return;
    }

    setState(() => _favoriteBusy = true);
    final next = !_favorite;
    try {
      if (next) {
        await session.api.favorites.addFavorite(
          userId: userId,
          propertyId: p.id,
        );
      } else {
        await session.api.favorites.removeFavorite(
          userId: userId,
          propertyId: p.id,
        );
      }
      if (!mounted) return;
      setState(() => _favorite = next);
    } catch (e) {
      if (mounted) _toast(e.toString());
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  void _showAmenities(RentalProperty p) {
    final b = RentalTheme.of(context);
    final items = p.amenities.isEmpty
        ? const ['Non renseigné pour ce bien']
        : p.amenities;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: b.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: b.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Amenities',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: b.text,
                  ),
                ),
                const SizedBox(height: 12),
                for (final a in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: RentalTheme.green, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(a, style: TextStyle(color: b.text)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openFullscreenGallery(List<String> images) async {
    if (images.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullscreenGallery(
          images: images,
          initialIndex: _imageIndex,
        ),
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);

    if (_error != null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: b.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: b.bg,
          body: _ErrorView(
            message: _error!,
            onBack: widget.onBack,
            onRetry: _load,
          ),
        ),
      );
    }

    if (_property == null) {
      return RentalPropertyDetailSkeleton(onBack: widget.onBack);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _heroOverlayStyle,
      child: Scaffold(
        backgroundColor: b.bg,
        body: _withNormalizedViewPadding(
          context,
          _buildBody(_property!),
        ),
      ),
    );
  }

  /// Uses [MediaQuery.viewPadding] as [MediaQuery.padding] so full-bleed
  /// layouts match on iOS and Android (notch, Dynamic Island, home indicator).
  Widget _withNormalizedViewPadding(BuildContext context, Widget child) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(padding: viewPadding),
      child: child,
    );
  }

  Widget _buildBody(RentalProperty property) {
    _ensureEntranceAnimation();
    final entrance = _entrance!;
    final images = property.imageUrls.isNotEmpty
        ? property.imageUrls
        : (property.imageUrl != null ? [property.imageUrl!] : <String>[]);
    final rating = _rating(property);
    final surface = _surfaceLabel(property);
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroHeader(
          images: images,
          imageIndex: _imageIndex,
          favorite: _favorite,
          providerLabel: _providerLabel(property),
          onBack: widget.onBack,
          onPageChanged: (i) => setState(() => _imageIndex = i),
          onExpand: () => _openFullscreenGallery(images),
          onShare: () => _share(property),
          onFavorite: () => _toggleFavorite(property),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: entrance,
            builder: (context, child) {
              final t = entrance.value;
              final sheetY =
                  -_sheetOverlap - (1 - t) * _sheetRevealTravel;
              // Cap starts flush on the sheet top, rises as the sheet slides down.
              final capOffset =
                  (1 - t) * _SheetTopCap.riseAboveSheet;
              return LayoutBuilder(
                builder: (context, constraints) {
                  // Taller by the upward shift so the panel still fills the
                  // screen bottom after Transform.translate.
                  final sheetHeight = constraints.maxHeight - sheetY;
                  return Transform.translate(
                    offset: Offset(0, sheetY),
                    child: SizedBox(
                      height: sheetHeight,
                      width: constraints.maxWidth,
                      child: _PropertyOverviewSheet(
                        property: property,
                        surface: surface,
                        priceLabel: _priceLabel(property),
                        rating: rating,
                        locationLine: _locationLine(property),
                        bottomInset: bottomSafe,
                        capSlideOffset: capOffset,
                        onSeeAmenities: () => _showAmenities(property),
                        onContact: () => _contactProvider(property),
                        onCall: () => _callProvider(property),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.images,
    required this.imageIndex,
    required this.favorite,
    required this.providerLabel,
    required this.onBack,
    required this.onPageChanged,
    required this.onExpand,
    required this.onShare,
    required this.onFavorite,
  });

  final List<String> images;
  final int imageIndex;
  final bool favorite;
  final String providerLabel;
  final VoidCallback onBack;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onExpand;
  final VoidCallback onShare;
  final VoidCallback onFavorite;

  // Tall enough that provider label stays visible above the overlapping sheet.
  static const _greenBandHeight = 100.0;
  static const _topRadius = 28.0;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    return SizedBox(
      height: 320 + top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: const Color(0xFF0A2E18)),
          if (images.isEmpty)
            const Center(
              child: Icon(Icons.home_work_outlined, size: 72, color: Colors.white70),
            )
          else
            PageView.builder(
              itemCount: images.length,
              onPageChanged: onPageChanged,
              itemBuilder: (_, i) => Image.network(
                images[i],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0xFF0A2E18),
                  child: Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.white70, size: 48),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: top + 120,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99000000), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            top: top + 8,
            left: 8,
            child: _RoundIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack,
            ),
          ),
          Positioned(
            top: top + 8,
            right: 12,
            child: Row(
              children: [
                _RoundIconButton(
                  icon: Icons.crop_free_rounded,
                  onTap: onExpand,
                ),
                const SizedBox(width: 8),
                _RoundIconButton(
                  icon: Icons.ios_share_rounded,
                  onTap: onShare,
                ),
                const SizedBox(width: 8),
                _RoundIconButton(
                  icon: favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  onTap: onFavorite,
                  iconColor: favorite ? const Color(0xFFFF5A5F) : Colors.white,
                ),
              ],
            ),
          ),
          if (images.isNotEmpty)
            Positioned(
              left: 16,
              bottom: _greenBandHeight + 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${imageIndex + 1}/${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          // Green provider strip — rounded top, sits on the photo (home-screen pattern)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(_topRadius),
              ),
              child: ColoredBox(
                color: RentalTheme.green,
                child: SizedBox(
                  height: _greenBandHeight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        providerLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.28),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}

class _PropertyOverviewSheet extends StatelessWidget {
  const _PropertyOverviewSheet({
    required this.property,
    required this.surface,
    required this.priceLabel,
    required this.rating,
    required this.locationLine,
    required this.onSeeAmenities,
    required this.onContact,
    required this.onCall,
    this.bottomInset = 0,
    this.capSlideOffset = 0,
  });

  final RentalProperty property;
  final String surface;
  final String priceLabel;
  final double rating;
  final String locationLine;
  final VoidCallback onSeeAmenities;
  final VoidCallback onContact;
  final VoidCallback onCall;
  final double bottomInset;
  final double capSlideOffset;

  static const double topRadius = 28;

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        RentalWhiteSheet(
          topRadius: topRadius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.title,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: b.text,
                              height: 1.1,
                            ),
                          ),
                          if (surface.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              surface,
                              style: TextStyle(
                                fontSize: 14,
                                color: b.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: priceLabel,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: b.text,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / month',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: b.muted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _RatingArc(rating: rating, color: b.text),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton(
                        onPressed: onSeeAmenities,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: b.text,
                          side: BorderSide(color: b.text, width: 1.2),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'See amenities',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _PrimaryCta(
                        label: 'Contact provider',
                        icon: Icons.mail_outline_rounded,
                        filled: true,
                        onTap: onContact,
                      ),
                      const SizedBox(height: 12),
                      _PrimaryCta(
                        label: 'Call provider',
                        icon: Icons.phone_outlined,
                        filled: false,
                        onTap: onCall,
                      ),
                      const SizedBox(height: 22),
                      Divider(color: b.border, height: 1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_rounded,
                            color: RentalTheme.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              locationLine,
                              style: TextStyle(
                                color: b.text,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => openRentalLocationInGoogleMaps(
                              latitude: property.latitude,
                              longitude: property.longitude,
                              placeLabel: locationLine,
                            ),
                            child: const Text('Ouvrir'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _MiniMap(property: property),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Painted last so it sits in front of the white sheet edge.
        Positioned(
          right: 8,
          top: -_SheetTopCap.riseAboveSheet + capSlideOffset,
          child: _SheetTopCap(color: b.card),
        ),
      ],
    );
  }
}

/// Small white tab with rounded top — straddles the sheet top over the green strip.
class _SheetTopCap extends StatelessWidget {
  const _SheetTopCap({required this.color});

  final Color color;

  static const width = 100.0;
  static const height = 84.0;
  static const topRadius = 28.0;
  static const logoSize = 52.0;
  /// Pixels above the sheet top; remainder of [height] overlaps the sheet to
  /// mask the rounded corner wedge over the green strip.
  static const riseAboveSheet = 66.0;
  static const _rentalLogoAsset = 'assets/logo/immo/rental.png';

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(topRadius),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(topRadius),
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: Align(
            alignment: const Alignment(0, -0.55),
            child: Image.asset(
              _rentalLogoAsset,
              package: 'immo',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.home_work_rounded,
                color: RentalTheme.green,
                size: 36,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Five stars fanned along a gentle upward arc, with the score under them.
class _RatingArc extends StatelessWidget {
  const _RatingArc({required this.rating, required this.color});

  final double rating;
  final Color color;

  static const _starCount = 5;
  static const _starSize = 17.0;
  static const _width = 78.0;
  static const _height = 34.0;
  static const _arcLift = 14.0;

  IconData _iconFor(int index) {
    final threshold = index + 1;
    if (rating >= threshold) return Icons.star_rounded;
    if (rating >= threshold - 0.5) return Icons.star_half_rounded;
    return Icons.star_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _width,
          height: _height,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(_starCount, (i) {
              final t = _starCount == 1 ? 0.5 : i / (_starCount - 1);
              final x = t * (_width - _starSize);
              final y = _arcLift * (1 - math.sin(math.pi * t));
              // Tilt follows the curve tangent.
              final angle = (t - 0.5) * 0.85;

              return Positioned(
                left: x,
                top: y,
                child: Transform.rotate(
                  angle: angle,
                  child: Icon(
                    _iconFor(i),
                    size: _starSize,
                    color: color,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          rating > 0 ? rating.toStringAsFixed(1) : '—',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);
    if (filled) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: RentalTheme.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: Icon(icon, size: 20),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: b.text,
          side: BorderSide(color: b.text, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
    );
  }
}

class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.property});

  final RentalProperty property;

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);
    final hasPoint = property.latitude != null && property.longitude != null;
    final point = hasPoint
        ? LatLng(property.latitude!, property.longitude!)
        : const LatLng(5.3364, -4.0267);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 170,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: hasPoint ? 14.5 : 12,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: MapTilesConfig.tileUrl(light: true),
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.monpeya.immo',
                  retinaMode: RetinaMode.isHighDensity(context),
                ),
                if (hasPoint)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 36,
                        height: 36,
                        child: const Icon(
                          Icons.place_rounded,
                          color: Color(0xFF2563EB),
                          size: 36,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Material(
                color: b.card,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => openRentalLocationInGoogleMaps(
                    latitude: property.latitude,
                    longitude: property.longitude,
                    placeLabel: [
                      property.address,
                      property.city,
                    ].where((e) => e.trim().isNotEmpty).join(', '),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_new_rounded, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Maps',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
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
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  const _FullscreenGallery({
    required this.images,
    required this.initialIndex,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: PageController(initialPage: widget.initialIndex),
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => InteractiveViewer(
              child: Center(
                child: Image.network(
                  widget.images[i],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    '${_index + 1}/${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onBack,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: b.text),
              onPressed: onBack,
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: b.text),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: onRetry,
                      style: FilledButton.styleFrom(
                        backgroundColor: RentalTheme.green,
                      ),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
