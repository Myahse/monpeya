import 'dart:io';

import 'package:flutter/material.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';

/// Document slot with thumbnail preview, attach / replace / open full preview.
class TransportDocTile extends StatelessWidget {
  const TransportDocTile({
    super.key,
    required this.brand,
    required this.title,
    required this.path,
    required this.onAttach,
    this.onRemove,
    this.onPreview,
  });

  final BilletterieBrand brand;
  final String title;
  final String? path;
  final VoidCallback onAttach;
  final VoidCallback? onRemove;
  final VoidCallback? onPreview;

  bool get _hasFile {
    final p = path;
    if (p == null || p.isEmpty) return false;
    if (p.startsWith('local://')) return false;
    return File(p).existsSync();
  }

  bool get _attached => path != null && path!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _hasFile
            ? (onPreview ?? onAttach)
            : onAttach,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: brand.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: _PreviewSurface(
                    brand: brand,
                    hasFile: _hasFile,
                    attached: _attached,
                    path: path,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: brand.text,
                      ),
                    ),
                  ),
                  if (_attached) ...[
                    if (onPreview != null && _hasFile)
                      IconButton(
                        tooltip: 'Aperçu',
                        visualDensity: VisualDensity.compact,
                        onPressed: onPreview,
                        icon: Icon(
                          Icons.fullscreen_rounded,
                          color: brand.primary,
                        ),
                      ),
                    IconButton(
                      tooltip: 'Remplacer',
                      visualDensity: VisualDensity.compact,
                      onPressed: onAttach,
                      icon: Icon(
                        Icons.edit_outlined,
                        color: brand.primary,
                      ),
                    ),
                    if (onRemove != null)
                      IconButton(
                        tooltip: 'Supprimer',
                        visualDensity: VisualDensity.compact,
                        onPressed: onRemove,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: brand.muted,
                        ),
                      ),
                  ] else
                    Text(
                      'Ajouter',
                      style: textTheme.labelLarge?.copyWith(
                        color: brand.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewSurface extends StatelessWidget {
  const _PreviewSurface({
    required this.brand,
    required this.hasFile,
    required this.attached,
    required this.path,
  });

  final BilletterieBrand brand;
  final bool hasFile;
  final bool attached;
  final String? path;

  @override
  Widget build(BuildContext context) {
    if (hasFile) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(path!),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _Placeholder(
              brand: brand,
              icon: Icons.broken_image_outlined,
              label: 'Aperçu indisponible',
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_outlined, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Aperçu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return _Placeholder(
      brand: brand,
      icon: attached
          ? Icons.description_outlined
          : Icons.add_photo_alternate_outlined,
      label: attached ? 'Document joint' : 'Appuyer pour ajouter',
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.brand,
    required this.icon,
    required this.label,
  });

  final BilletterieBrand brand;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: brand.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: brand.primary),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: brand.muted,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen document image preview.
class TransportDocPreviewScreen extends StatelessWidget {
  const TransportDocPreviewScreen({
    super.key,
    required this.title,
    required this.path,
  });

  final String title;
  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Image.file(
            File(path),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}
