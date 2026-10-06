import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/rental/auth/rental.session.dart';
import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/models/rental_profile_role.dart';
import 'package:immo/src/features/rental/models/rental.property.dart';
import 'package:immo/src/features/rental/navigation/rental_bottom.navigation.dart';
import 'package:immo/src/features/rental/services/rental_api.service.dart';
import 'package:immo/src/features/rental/services/rental_data.cache.dart';
import 'package:immo/src/features/rental/services/rental_location.service.dart';
import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';
import 'package:immo/src/features/rental/widgets/property_card.widget.dart';
import 'package:immo/src/features/rental/widgets/rental_layout_widgets.widget.dart';
import 'package:immo/src/features/rental/widgets/rental_location_modal.widget.dart';
import 'package:immo/src/features/rental/widgets/rental_skeleton.widget.dart';

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({
    super.key,
    this.onPropertySelect,
    this.onCreateListing,
    this.onCreateTenant,
    this.onViewTenant,
    this.onSeeAll,
  });

  final ValueChanged<RentalProperty>? onPropertySelect;
  final VoidCallback? onCreateListing;
  final VoidCallback? onCreateTenant;
  final ValueChanged<String>? onViewTenant;
  final VoidCallback? onSeeAll;

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  static const _notifDismissKey = '@rental_home_notif_prompt_dismissed';

  List<RentalProperty> _properties = const [];
  List<RentalProperty> _nearbyProperties = const [];
  Set<String> _favoriteIds = {};
  String? _error;
  bool _loading = false;
  bool _showNotifPrompt = true;
  RentalLocationStatus? _locationStatus;
  String? _locationMessage;

  RentalSession? _session;
  final _cache = RentalDataCache.instance;

  RentalApiService get _api {
    final session = _session;
    assert(session != null, 'RentalSession not ready');
    return session!.api;
  }

  @override
  void initState() {
    super.initState();
    _cache.addListener(_onCacheChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = RentalSessionScope.of(context);
    if (!identical(_session, session)) {
      _session?.removeListener(_onSessionChanged);
      _session = session;
      _session!.addListener(_onSessionChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadNotifPref();
        _maybeLoad();
      });
    }
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChanged);
    _cache.removeListener(_onCacheChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (!mounted) return;
    setState(() {});
    // Role / auth changes need a reload; quiet notifyListeners do not.
    final session = _session;
    if (session == null || !session.bootstrapComplete) return;
    if (_properties.isEmpty) {
      _maybeLoad();
    }
  }

  void _onCacheChanged() {
    if (!mounted) return;
    final session = _session;
    if (session == null || !session.bootstrapComplete) return;
    if (session.profileRole == RentalProfileRole.landlord && !session.guestMode) {
      return;
    }
    final cached = _cache.available;
    if (cached == null) return;
    final location = RentalLocationService.cached;
    final nearby = location == null
        ? const <RentalProperty>[]
        : _nearbyWithinRadius(
            cached,
            location,
            RentalLocationService.nearbyRadiusMeters,
          );
    final favIds = session.userId == null
        ? _favoriteIds
        : (_cache.favoriteIdsIfFresh(session.userId!) ?? _favoriteIds);
    setState(() {
      _properties = cached;
      _nearbyProperties = nearby;
      _favoriteIds = favIds;
      _error = null;
    });
  }

  Future<void> _loadNotifPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _showNotifPrompt = !(prefs.getBool(_notifDismissKey) ?? false));
  }

  Future<void> _dismissNotifPrompt() async {
    setState(() => _showNotifPrompt = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifDismissKey, true);
  }

  void _maybeLoad() {
    final session = _session;
    if (session == null || !session.bootstrapComplete) return;
    // Already hydrated — WS/cache keep the list fresh without a remount reload.
    if (_properties.isNotEmpty) return;
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final session = _session;
    if (session == null) return;
    final role = session.profileRole;

    if (!forceRefresh && _properties.isNotEmpty) {
      // Soft sync favorites hearts only when we already show listings.
      if (role != RentalProfileRole.landlord || session.guestMode) {
        await _loadFavoriteIds();
      }
      return;
    }

    final hasCachedSeeker = role != RentalProfileRole.landlord || session.guestMode
        ? (_cache.available?.isNotEmpty ?? false)
        : false;

    if (hasCachedSeeker && !forceRefresh) {
      final cached = _cache.available!;
      final location = RentalLocationService.cached;
      final nearby = location == null
          ? const <RentalProperty>[]
          : _nearbyWithinRadius(
              cached,
              location,
              RentalLocationService.nearbyRadiusMeters,
            );
      setState(() {
        _properties = cached;
        _nearbyProperties = nearby;
        _loading = false;
        _error = null;
      });
      await _loadFavoriteIds();
      return;
    }

    setState(() {
      _loading = _properties.isEmpty;
      _error = null;
    });

    // Guests browse published listings; landlord “Mes biens” needs Immo auth.
    if (role == RentalProfileRole.landlord && !session.guestMode) {
      await _loadLandlordProperties();
    } else {
      await _loadSeekerProperties(forceRefresh: forceRefresh);
      await _loadFavoriteIds(forceRefresh: forceRefresh);
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadFavoriteIds({bool forceRefresh = false}) async {
    final session = _session;
    final userId = session?.userId;
    if (session == null ||
        !session.authenticated ||
        userId == null ||
        userId.isEmpty) {
      if (mounted) setState(() => _favoriteIds = {});
      return;
    }
    try {
      final ids = await _api.favorites.fetchFavoriteIds(
        userId,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() => _favoriteIds = ids);
    } catch (_) {
      // Browse still works if favorites sync fails.
    }
  }

  Future<void> _toggleFavorite(RentalProperty property) async {
    var session = _session ?? RentalSessionScope.of(context);
    if (!session.authenticated) {
      final ok = await session.ensureImmoReady(context);
      if (!mounted || !ok) {
        final msg = RentalSessionScope.of(context).immoLinkError;
        if (msg != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
        return;
      }
      session = RentalSessionScope.of(context);
      _session = session;
    }
    final userId = session.userId;
    if (userId == null || userId.isEmpty) return;

    final isFav = _favoriteIds.contains(property.id);
    try {
      if (isFav) {
        await session.api.favorites.removeFavorite(
          userId: userId,
          propertyId: property.id,
        );
        if (!mounted) return;
        setState(() {
          _favoriteIds = {..._favoriteIds}..remove(property.id);
        });
      } else {
        await session.api.favorites.addFavorite(
          userId: userId,
          propertyId: property.id,
        );
        if (!mounted) return;
        setState(() {
          _favoriteIds = {..._favoriteIds, property.id};
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _loadLandlordProperties() async {
    final session = _session;
    if (session == null) return;
    if (session.guestMode || session.userId == null || session.userId!.isEmpty) {
      if (!mounted) return;
      setState(() => _properties = const []);
      return;
    }
    try {
      final items = await _api.properties.fetchMyProperties(ownerUserId: session.userId);
      if (!mounted) return;
      setState(() => _properties = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _loadSeekerProperties({bool forceRefresh = false}) async {
    try {
      final items = await _api.properties.fetchAvailableProperties(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      // Prefer cached GPS on revisit; only prompt/refresh when we have none.
      final RentalLocationResult locationResult;
      if (RentalLocationService.cached != null && !forceRefresh) {
        locationResult = RentalLocationResult.ok(RentalLocationService.cached!);
      } else {
        locationResult = await ensureRentalLocation(context);
      }
      if (!mounted) return;

      final nearby = locationResult.hasLocation
          ? _nearbyWithinRadius(
              items,
              locationResult.location!,
              RentalLocationService.nearbyRadiusMeters,
            )
          : const <RentalProperty>[];

      setState(() {
        _properties = items;
        _nearbyProperties = nearby;
        _locationStatus = locationResult.status;
        _locationMessage = locationResult.message;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  /// Properties with coordinates inside [radiusMeters] of the user, nearest first.
  static List<RentalProperty> _nearbyWithinRadius(
    List<RentalProperty> all,
    RentalUserLocation user,
    double radiusMeters,
  ) {
    final scored = <({RentalProperty property, double meters})>[];

    for (final p in all) {
      final lat = p.latitude;
      final lng = p.longitude;
      if (lat == null || lng == null) continue;
      final meters = RentalLocationService.distanceMeters(
        fromLat: user.latitude,
        fromLng: user.longitude,
        toLat: lat,
        toLng: lng,
      );
      if (meters <= radiusMeters) {
        scored.add((property: p, meters: meters));
      }
    }

    scored.sort((a, b) => a.meters.compareTo(b.meters));
    return List<RentalProperty>.unmodifiable(
      scored.map((e) => e.property),
    );
  }

  Future<void> _retryLocation() async {
    setState(() => _loading = true);
    await _loadSeekerProperties();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openLocationSettings() async {
    final status = _locationStatus;
    if (status == RentalLocationStatus.deniedForever) {
      await RentalLocationService.openAppSettings();
    } else if (status == RentalLocationStatus.serviceDisabled) {
      await RentalLocationService.openLocationSettings();
    } else {
      await _retryLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = RentalSessionScope.of(context);
    final role = session.profileRole;
    final name = session.displayName;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final b = ImmoBrand.rentalOf(context);
          final topPad = MediaQuery.paddingOf(context).top;
          // Header band; white panel starts slightly overlapping it and fills to bottom.
          final headerBand = topPad + 132.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: b.header),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: RentalHomeHeader(userName: name),
              ),
              Positioned(
                top: headerBand,
                left: 0,
                right: 0,
                bottom: 0,
                child: RentalWhiteSheet(
                  child: role.isBusiness && !session.guestMode
                      ? _LandlordBody(
                          loading: _loading,
                          error: _error,
                          properties: _properties,
                          showNotifPrompt: _showNotifPrompt,
                          onDismissNotif: _dismissNotifPrompt,
                          onRefresh: () => _load(forceRefresh: true),
                          onRetryProperties: _loadLandlordProperties,
                          onPropertySelect: widget.onPropertySelect,
                          onCreateListing: widget.onCreateListing,
                        )
                      : _SeekerHomeBody(
                          loading: _loading,
                          error: _error,
                          nearbyProperties: _nearbyProperties,
                          availableProperties: _properties,
                          favoriteIds: _favoriteIds,
                          locationStatus: _locationStatus,
                          locationMessage: _locationMessage,
                          showNotifPrompt: _showNotifPrompt,
                          onDismissNotif: _dismissNotifPrompt,
                          onRefresh: () => _load(forceRefresh: true),
                          onRetry: _loadSeekerProperties,
                          onRetryLocation: _retryLocation,
                          onOpenLocationSettings: _openLocationSettings,
                          onPropertySelect: widget.onPropertySelect,
                          onFavoriteTap: _toggleFavorite,
                          onSeeAll: widget.onSeeAll,
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SeekerHomeBody extends StatelessWidget {
  const _SeekerHomeBody({
    required this.loading,
    required this.error,
    required this.nearbyProperties,
    required this.availableProperties,
    required this.favoriteIds,
    required this.locationStatus,
    required this.locationMessage,
    required this.showNotifPrompt,
    required this.onDismissNotif,
    required this.onRefresh,
    required this.onRetry,
    required this.onRetryLocation,
    required this.onOpenLocationSettings,
    this.onPropertySelect,
    this.onFavoriteTap,
    this.onSeeAll,
  });

  final bool loading;
  final String? error;
  final List<RentalProperty> nearbyProperties;
  final List<RentalProperty> availableProperties;
  final Set<String> favoriteIds;
  final RentalLocationStatus? locationStatus;
  final String? locationMessage;
  final bool showNotifPrompt;
  final VoidCallback onDismissNotif;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRetry;
  final VoidCallback onRetryLocation;
  final VoidCallback onOpenLocationSettings;
  final ValueChanged<RentalProperty>? onPropertySelect;
  final ValueChanged<RentalProperty>? onFavoriteTap;
  final VoidCallback? onSeeAll;

  bool get _needsLocationAction =>
      locationStatus != null &&
      locationStatus != RentalLocationStatus.ok &&
      nearbyProperties.isEmpty;

  @override
  Widget build(BuildContext context) {
    final empty = !loading &&
        error == null &&
        nearbyProperties.isEmpty &&
        availableProperties.isEmpty &&
        !_needsLocationAction;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: RentalTheme.greenMid,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: RentalBottomNavigation.contentBottomPadding(context),
        ),
        children: [
          if (showNotifPrompt)
            RentalHomeNotificationCard(
              onAllow: onDismissNotif,
              onNotNow: onDismissNotif,
            ),
          const SizedBox(height: RentalTheme.spacingMd),
          if (loading && availableProperties.isEmpty)
            const RentalHomeListingsSkeleton()
          else if (error != null)
            _ErrorBlock(message: error!, onRetry: onRetry)
          else if (empty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: RentalTheme.spacingLg,
                vertical: 32,
              ),
              child: Text(
                'Aucun bien disponible pour le moment.',
                textAlign: TextAlign.center,
                style: TextStyle(color: RentalTheme.of(context).muted),
              ),
            )
          else ...[
            RentalSectionHeader(
              title: 'Autour de vous',
              actionLabel: 'Voir tout',
              onAction: onSeeAll,
            ),
            const SizedBox(height: RentalTheme.spacingMd),
            if (_needsLocationAction)
              _LocationPermissionCard(
                message: locationMessage ??
                    'Autorisez la localisation pour voir les biens dans un rayon de 500 m.',
                status: locationStatus!,
                onAllow: onRetryLocation,
                onOpenSettings: onOpenLocationSettings,
              )
            else
              _PropertyRow(
                properties: nearbyProperties,
                favoriteIds: favoriteIds,
                onPropertySelect: onPropertySelect,
                onFavoriteTap: onFavoriteTap,
                emptyLabel:
                    'Aucun bien dans un rayon de 500 m autour de vous.',
              ),
            const SizedBox(height: RentalTheme.spacingXl),
            RentalSectionHeader(
              title: 'Disponibles',
              actionLabel: 'Voir tout',
              onAction: onSeeAll,
            ),
            const SizedBox(height: RentalTheme.spacingMd),
            _PropertyRow(
              properties: availableProperties,
              favoriteIds: favoriteIds,
              onPropertySelect: onPropertySelect,
              onFavoriteTap: onFavoriteTap,
              emptyLabel: 'Aucun bien disponible pour le moment.',
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationPermissionCard extends StatelessWidget {
  const _LocationPermissionCard({
    required this.message,
    required this.status,
    required this.onAllow,
    required this.onOpenSettings,
  });

  final String message;
  final RentalLocationStatus status;
  final VoidCallback onAllow;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);
    final needsSettings = status == RentalLocationStatus.deniedForever ||
        status == RentalLocationStatus.serviceDisabled;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RentalTheme.spacingLg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: b.searchFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: b.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on_outlined, color: b.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Localisation requise',
                    style: TextStyle(
                      color: b.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: b.muted, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: needsSettings ? onOpenSettings : onAllow,
                style: FilledButton.styleFrom(
                  backgroundColor: RentalTheme.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  needsSettings ? 'Ouvrir les réglages' : 'Autoriser',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow({
    required this.properties,
    required this.emptyLabel,
    this.favoriteIds = const {},
    this.onPropertySelect,
    this.onFavoriteTap,
  });

  final List<RentalProperty> properties;
  final String emptyLabel;
  final Set<String> favoriteIds;
  final ValueChanged<RentalProperty>? onPropertySelect;
  final ValueChanged<RentalProperty>? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RentalTheme.spacingLg,
          vertical: 12,
        ),
        child: Text(
          emptyLabel,
          style: TextStyle(
            color: RentalTheme.of(context).muted,
            fontSize: 13,
          ),
        ),
      );
    }

    return SizedBox(
      height: 192,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: RentalTheme.spacingLg),
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
          return RentalPropertyCard(
            property: property,
            isFavorite: favoriteIds.contains(property.id),
            onTap: () => onPropertySelect?.call(property),
            onFavoriteTap: onFavoriteTap == null
                ? null
                : () => onFavoriteTap!(property),
          );
        },
      ),
    );
  }
}

class _LandlordBody extends StatelessWidget {
  const _LandlordBody({
    required this.loading,
    required this.error,
    required this.properties,
    required this.showNotifPrompt,
    required this.onDismissNotif,
    required this.onRefresh,
    required this.onRetryProperties,
    this.onPropertySelect,
    this.onCreateListing,
  });

  final bool loading;
  final String? error;
  final List<RentalProperty> properties;
  final bool showNotifPrompt;
  final VoidCallback onDismissNotif;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRetryProperties;
  final ValueChanged<RentalProperty>? onPropertySelect;
  final VoidCallback? onCreateListing;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: RentalTheme.greenMid,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: RentalBottomNavigation.contentBottomPadding(context),
        ),
        children: [
          if (showNotifPrompt)
            RentalHomeNotificationCard(
              onAllow: onDismissNotif,
              onNotNow: onDismissNotif,
            ),
          const SizedBox(height: RentalTheme.spacingMd),
          const RentalSectionHeader(
            title: 'Mes biens',
          ),
          const SizedBox(height: RentalTheme.spacingMd),
          if (loading && properties.isEmpty)
            const RentalHomeListingsSkeleton(sections: 1)
          else if (error != null)
            _ErrorBlock(message: error!, onRetry: onRetryProperties)
          else if (properties.isEmpty)
            _EmptyProperties(onCreate: onCreateListing)
          else ...[
            SizedBox(
              height: 192,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: RentalTheme.spacingLg,
                ),
                itemCount: properties.length,
                itemBuilder: (context, index) {
                  final property = properties[index];
                  return RentalPropertyCard(
                    property: property,
                    showFavorite: false,
                    onTap: () => onPropertySelect?.call(property),
                  );
                },
              ),
            ),
            const SizedBox(height: RentalTheme.spacingMd),
            RentalGradientPillButton(label: 'Publier un bien', onPressed: onCreateListing),
          ],
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RentalTheme.spacingLg, vertical: 32),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: RentalTheme.of(context).danger),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _EmptyProperties extends StatelessWidget {
  const _EmptyProperties({this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RentalTheme.spacingLg),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: b.searchFill,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.home_work_outlined,
              size: 64,
              color: RentalTheme.green.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: RentalTheme.spacingMd),
          Text(
            'Vous n’avez pas encore de bien. Créez-en un.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: b.muted),
          ),
          const SizedBox(height: RentalTheme.spacingMd),
          RentalGradientPillButton(label: 'Publier un bien', onPressed: onCreate),
        ],
      ),
    );
  }
}
