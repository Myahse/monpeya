import 'package:flutter/material.dart';

import 'package:immo/src/features/collection/services/collection.store.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

class PropertiesScreen extends StatelessWidget {
  const PropertiesScreen({super.key, required this.store, this.onSelectProperty});

  final CollectionStore store;
  final ValueChanged<String>? onSelectProperty;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = store.properties;
        return ImmoTabPage(
          title: 'Biens',
          subtitle: 'Immeubles, lots et locataires',
          onRefresh: store.signedIn ? store.refresh : null,
          children: [
            if (!store.loaded)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ))
            else if (!store.signedIn)
              const ImmoEmptyState(
                icon: Icons.lock_outline_rounded,
                title: 'Connexion requise',
                message: 'Connectez-vous à Mon Peya pour suivre vos loyers.',
              )
            else if (store.error != null && list.isEmpty)
              ImmoEmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Chargement impossible',
                message: store.error!,
                actionLabel: 'Réessayer',
                onAction: store.refresh,
              )
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
                    if (p.address != null && p.address!.isNotEmpty) p.address!,
                    if (p.unitCount != null)
                      p.unitCount == 1 ? '1 locataire' : '${p.unitCount} locataires',
                  ].join(' · '),
                  onTap: onSelectProperty == null
                      ? null
                      : () => onSelectProperty!(p.id),
                ),
          ],
        );
      },
    );
  }
}
