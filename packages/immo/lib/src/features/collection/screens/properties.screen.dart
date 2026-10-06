import 'package:flutter/material.dart';

import 'package:immo/src/features/collection/models/property.model.dart';
import 'package:immo/src/features/collection/services/property.service.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key, this.onSelectProperty});

  final ValueChanged<String>? onSelectProperty;

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  late final Future<List<CollectionProperty>> _properties =
      CollectionPropertyService().fetchProperties();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _properties,
      builder: (context, snap) {
        final list = snap.data ?? const <CollectionProperty>[];
        return ImmoTabPage(
          title: 'Biens',
          subtitle: 'Immeubles, lots et locataires',
          children: [
            if (snap.connectionState != ConnectionState.done)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ))
            else if (list.isEmpty)
              const ImmoEmptyState(
                icon: Icons.apartment_rounded,
                title: 'Aucun bien en gestion',
                message: 'Ajoutez vos immeubles et lots pour suivre loyers et locataires.',
              )
            else
              for (final p in list)
                ImmoListTile(
                  icon: Icons.apartment_rounded,
                  title: p.name,
                  subtitle: [
                    if (p.address != null) p.address!,
                    if (p.unitCount != null) '${p.unitCount} lots',
                  ].join(' · '),
                  onTap: widget.onSelectProperty == null
                      ? null
                      : () => widget.onSelectProperty!(p.id),
                ),
          ],
        );
      },
    );
  }
}
