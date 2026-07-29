import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/features/transport/models/transport_profile.model.dart';
import 'package:billetterie/src/features/transport/services/transport_profile.store.dart';
import 'package:billetterie/src/features/transport/widgets/transport_doc_tile.widget.dart';

/// Profile Documents screen — manage KYC files with inline preview.
class TransportDocumentsScreen extends StatefulWidget {
  const TransportDocumentsScreen({super.key, required this.initial});

  final TransportProfileState initial;

  @override
  State<TransportDocumentsScreen> createState() =>
      _TransportDocumentsScreenState();
}

class _TransportDocumentsScreenState extends State<TransportDocumentsScreen> {
  final _store = TransportProfileStore();
  final _picker = ImagePicker();

  late bool _isCompany;
  String? _idFront;
  String? _idBack;
  String? _companyDoc;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isCompany = widget.initial.isCompany;
    _idFront = _usablePath(widget.initial.idCardFrontPath);
    _idBack = _usablePath(widget.initial.idCardBackPath);
    _companyDoc = _usablePath(widget.initial.companyDocPath);
  }

  String? _usablePath(String? raw) {
    if (raw == null || raw.isEmpty || raw.startsWith('local://')) return null;
    return File(raw).existsSync() ? raw : null;
  }

  Future<void> _attach(String kind) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final brand = BilletterieBrand.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: brand.primary),
                title: const Text('Galerie'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(Icons.photo_camera_outlined, color: brand.primary),
                title: const Text('Appareil photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
    if (source == null || !mounted) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (picked == null || !mounted) return;

    final stored = await _persistPicked(picked.path, kind);
    if (!mounted) return;
    setState(() {
      switch (kind) {
        case 'front':
          _idFront = stored;
        case 'back':
          _idBack = stored;
        case 'company':
          _companyDoc = stored;
      }
    });
  }

  Future<String> _persistPicked(String sourcePath, String kind) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/billetterie_docs');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final dest = File(
      '${folder.path}/$kind-${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  void _remove(String kind) {
    setState(() {
      switch (kind) {
        case 'front':
          _idFront = null;
        case 'back':
          _idBack = null;
        case 'company':
          _companyDoc = null;
      }
    });
  }

  Future<void> _preview(String title, String? path) async {
    if (path == null || !File(path).existsSync()) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TransportDocPreviewScreen(title: title, path: path),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final next = await _store.saveDocuments(
        isCompany: _isCompany,
        idCardFrontPath: _idFront,
        idCardBackPath: _idBack,
        companyDocPath: _companyDoc,
        clearIdFront: _idFront == null,
        clearIdBack: _idBack == null,
        clearCompanyDoc: _companyDoc == null,
      );
      if (!mounted) return;
      Navigator.of(context).pop(next);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: brand.bg,
      appBar: AppBar(
        backgroundColor: brand.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: brand.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Documents',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: brand.text,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Compte société / compagnie',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: brand.text,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: _isCompany,
                  activeThumbColor: brand.primary,
                  onChanged: (v) => setState(() => _isCompany = v),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: brand.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                TransportDocTile(
                  brand: brand,
                  title: 'Pièce d’identité — recto',
                  path: _idFront,
                  onAttach: () => _attach('front'),
                  onRemove: _idFront == null ? null : () => _remove('front'),
                  onPreview: () =>
                      _preview('Pièce d’identité — recto', _idFront),
                ),
                const SizedBox(height: 10),
                TransportDocTile(
                  brand: brand,
                  title: 'Pièce d’identité — verso',
                  path: _idBack,
                  onAttach: () => _attach('back'),
                  onRemove: _idBack == null ? null : () => _remove('back'),
                  onPreview: () =>
                      _preview('Pièce d’identité — verso', _idBack),
                ),
                if (_isCompany) ...[
                  const SizedBox(height: 10),
                  TransportDocTile(
                    brand: brand,
                    title: 'Document société (RCCM / registre)',
                    path: _companyDoc,
                    onAttach: () => _attach('company'),
                    onRemove: _companyDoc == null
                        ? null
                        : () => _remove('company'),
                    onPreview: () =>
                        _preview('Document société', _companyDoc),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: brand.bg,
                border: Border(
                  top: BorderSide(color: brand.border),
                ),
              ),
              child: _DocumentsGradientButton(
                label: _saving ? 'Enregistrement…' : 'Enregistrer',
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.save_outlined,
                        size: 20,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentsGradientButton extends StatelessWidget {
  const _DocumentsGradientButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    final textTheme = Theme.of(context).textTheme;
    final enabled = onPressed != null;
    final gradient = LinearGradient(
      colors: [brand.primary, brand.primaryDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: enabled ? gradient : null,
            color: enabled ? null : brand.border,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  icon!,
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
