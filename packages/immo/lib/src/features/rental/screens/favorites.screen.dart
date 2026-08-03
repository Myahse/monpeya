import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/models/rental.property.dart';
import 'package:immo/src/features/rental/navigation/rental_bottom.navigation.dart';
import 'package:immo/src/features/rental/services/rental_data.cache.dart';
import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';
import 'package:immo/src/features/rental/widgets/property_card.widget.dart';
import 'package:immo/src/features/rental/widgets/rental_skeleton.widget.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, this.onPropertySelect});

  final ValueChanged<RentalProperty>? onPropertySelect;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<RentalProperty> _items = const [];
  bool _loading = false;
  bool _linking = false;
  String? _error;
  String? _busyId;
  final _cache = RentalDataCache.instance;

  @override
  void initState() {
    super.initState();
    _cache.addListener(_onCacheChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _cache.removeListener(_onCacheChanged);
    super.dispose();
  }

  void _onCacheChanged() {
    if (!mounted) return;
    final session = RentalSessionScope.of(context);
    final userId = session.userId;
    if (userId == null || userId.isEmpty) return;
    final list = _cache.favorites(userId);
    if (list == null) return;
    setState(() {
      _items = list;
      _error = null;
    });
  }

  Future<void> _load({bool forceRefresh = false}) async {
    var session = RentalSessionScope.of(context);

    // Mon Peya unlocked but Immo userId missing — link quietly, don't ask login again.
    if (session.needsImmoLink ||
        (session.monPeyaUnlocked &&
            (session.guestMode || session.userId == null))) {
      setState(() {
        _linking = true;
        _error = null;
        _loading = false;
      });
      final ok = await session.ensureImmoReady(context);
      if (!mounted) return;
      session = RentalSessionScope.of(context);
      setState(() => _linking = false);
      if (!ok) {
        setState(() {
          _items = const [];
          _error = session.immoLinkError ??
              'Impossible d’accéder aux favoris avec ce compte.';
        });
        return;
      }
    }

    final userId = session.userId;
    if (!session.authenticated || userId == null || userId.isEmpty) {
      setState(() {
        _items = const [];
        _error = null;
        _loading = false;
      });
      return;
    }

    if (!forceRefresh && _items.isNotEmpty) return;

    final cached = !forceRefresh ? _cache.favoritesIfFresh(userId) : null;
    if (cached != null) {
      setState(() {
        _items = cached;
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    try {
      final items = await session.api.favorites.fetchFavorites(
        userId,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginOrLink() async {
    setState(() {
      _linking = true;
      _error = null;
    });
    final ok = await RentalSessionScope.of(context).ensureImmoReady(context);
    if (!mounted) return;
    setState(() => _linking = false);
    if (!ok) {
      final session = RentalSessionScope.of(context);
      setState(() {
        _error = session.immoLinkError ??
            'Connectez-vous pour voir vos biens favoris.';
      });
      return;
    }
    await _load();
  }

  Future<void> _removeFavorite(RentalProperty property) async {
    final session = RentalSessionScope.of(context);
    final userId = session.userId;
    if (!session.authenticated || userId == null || userId.isEmpty) {
      await _loginOrLink();
      return;
    }
    if (_busyId != null) return;

    setState(() => _busyId = property.id);
    try {
      await session.api.favorites.removeFavorite(
        userId: userId,
        propertyId: property.id,
      );
      if (!mounted) return;
      setState(() {
        _items =
            _items.where((p) => p.id != property.id).toList(growable: false);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = RentalSessionScope.of(context);
    final needsMonPeya = !session.monPeyaUnlocked;
    final needsImmo = session.needsImmoLink ||
        (session.monPeyaUnlocked && !session.authenticated);
    final b = RentalTheme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: b.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: b.bg,
        child: RefreshIndicator(
          onRefresh: () => _load(forceRefresh: true),
          color: RentalTheme.green,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              RentalTheme.spacingLg,
              MediaQuery.paddingOf(context).top + 16,
              RentalTheme.spacingLg,
              RentalBottomNavigation.contentBottomPadding(context),
            ),
            children: [
              Text(
                'Favoris',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: b.text,
                ),
              ),
              if (session.authenticated && _items.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '${_items.length} bien${_items.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: b.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (needsMonPeya)
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Column(
                    children: [
                      Text(
                        'Connectez-vous pour voir vos biens favoris.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: b.muted),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _linking ? null : _loginOrLink,
                        icon: const Icon(Icons.login_rounded),
                        label: Text(_linking ? 'Connexion…' : 'Connexion'),
                        style: FilledButton.styleFrom(
                          backgroundColor: RentalTheme.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_linking || (needsImmo && _loading))
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: RentalFavoritesSkeleton(),
                )
              else if (needsImmo)
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Column(
                    children: [
                      Text(
                        _error ??
                            session.immoLinkError ??
                            'Compte Mon Peya connecté, mais le compte Mr Immo n’est pas lié.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: b.muted),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _linking ? null : _loginOrLink,
                        icon: const Icon(Icons.link_rounded),
                        label: const Text('Réessayer'),
                        style: FilledButton.styleFrom(
                          backgroundColor: RentalTheme.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_loading && _items.isEmpty)
                const RentalFavoritesSkeleton()
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Column(
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: b.text),
                      ),
                      TextButton(onPressed: _load, child: const Text('Réessayer')),
                    ],
                  ),
                )
              else if (_items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: RentalTheme.green.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Vos biens favoris apparaîtront ici.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: b.muted),
                      ),
                    ],
                  ),
                )
              else
                Builder(
                  builder: (context) {
                    final cell = (MediaQuery.sizeOf(context).width -
                            RentalTheme.spacingLg * 2 -
                            10) /
                        2;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final property in _items)
                          RentalPropertyCard(
                            property: property,
                            isFavorite: true,
                            size: cell,
                            margin: EdgeInsets.zero,
                            onTap: () =>
                                widget.onPropertySelect?.call(property),
                            onFavoriteTap: _busyId == property.id
                                ? null
                                : () => _removeFavorite(property),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
