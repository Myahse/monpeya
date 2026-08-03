import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/models/rental.property.dart';
import 'package:immo/src/features/rental/navigation/rental_bottom.navigation.dart';
import 'package:immo/src/features/rental/services/rental_data.cache.dart';
import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';
import 'package:immo/src/features/rental/widgets/property_card.widget.dart';

/// Full browse / See all list for available properties.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.onPropertySelect});

  final ValueChanged<RentalProperty>? onPropertySelect;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  List<RentalProperty> _properties = const [];
  bool _loading = false;
  String? _error;
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
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onCacheChanged() {
    if (!mounted) return;
    if (_searchCtrl.text.trim().isNotEmpty) return;
    final cached = _cache.available;
    if (cached == null) return;
    setState(() {
      _properties = cached;
      _error = null;
    });
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final q = _searchCtrl.text.trim();
    if (!forceRefresh && q.isEmpty && _properties.isNotEmpty) return;

    final cached =
        q.isEmpty && !forceRefresh ? _cache.availableIfFresh : null;
    if (cached != null) {
      setState(() {
        _properties = cached;
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = _properties.isEmpty;
      _error = null;
    });
    try {
      final items = await RentalSessionScope.of(context)
          .api
          .properties
          .fetchAvailableProperties(
            search: q.isEmpty ? null : q,
            forceRefresh: forceRefresh,
          );
      if (!mounted) return;
      setState(() => _properties = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: b.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: b.bg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: b.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchCtrl,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(color: b.text),
                      onSubmitted: (_) => _load(),
                      decoration: InputDecoration(
                        hintText: 'Nom, quartier, ville…',
                        hintStyle: TextStyle(color: b.muted),
                        prefixIcon: Icon(Icons.search, color: b.muted),
                        filled: true,
                        fillColor: b.searchFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _load(forceRefresh: true),
                color: RentalTheme.green,
                child: _loading && _properties.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: RentalTheme.green))
                    : _error != null
                        ? ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24),
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
                              ),
                            ],
                          )
                        : _properties.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 80),
                                  Center(
                                    child: Text(
                                      'Aucun bien trouvé.',
                                      style: TextStyle(color: b.muted),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: EdgeInsets.only(
                                  top: 8,
                                  bottom: RentalBottomNavigation
                                      .contentBottomPadding(context),
                                ),
                                itemCount: (_properties.length / 2).ceil(),
                                itemBuilder: (context, row) {
                                  final left = _properties[row * 2];
                                  final hasRight =
                                      row * 2 + 1 < _properties.length;
                                  final right = hasRight
                                      ? _properties[row * 2 + 1]
                                      : null;
                                  final cell = (MediaQuery.sizeOf(context).width -
                                          RentalTheme.spacingLg * 2 -
                                          10) /
                                      2;
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      RentalTheme.spacingLg,
                                      0,
                                      RentalTheme.spacingLg,
                                      10,
                                    ),
                                    child: Row(
                                      children: [
                                        RentalPropertyCard(
                                          property: left,
                                          size: cell,
                                          margin: EdgeInsets.zero,
                                          onTap: () => widget.onPropertySelect
                                              ?.call(left),
                                        ),
                                        const SizedBox(width: 10),
                                        if (right != null)
                                          RentalPropertyCard(
                                            property: right,
                                            size: cell,
                                            margin: EdgeInsets.zero,
                                            onTap: () => widget
                                                .onPropertySelect
                                                ?.call(right),
                                          )
                                        else
                                          SizedBox(width: cell),
                                      ],
                                    ),
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
