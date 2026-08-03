import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import 'package:leadway/src/presentation/constants/leadway.brand.dart';

/// Prévisualisation d'un document PDF Leadway (contrat ou devis).
class LeadwayPdfViewerScreen extends StatefulWidget {
  const LeadwayPdfViewerScreen({
    super.key,
    required this.bytes,
    required this.title,
    required this.onShare,
    required this.onSave,
  });

  final Uint8List bytes;
  final String title;
  final VoidCallback onShare;
  final VoidCallback onSave;

  @override
  State<LeadwayPdfViewerScreen> createState() => _LeadwayPdfViewerScreenState();
}

class _LeadwayPdfViewerScreenState extends State<LeadwayPdfViewerScreen> {
  late final PdfControllerPinch _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openData(widget.bytes),
    );
    _controller.loadingState.addListener(_onLoadingChanged);
  }

  void _onLoadingChanged() {
    if (!mounted) return;
    final state = _controller.loadingState.value;
    setState(() {
      _loading = state == PdfLoadingState.loading;
      if (state == PdfLoadingState.error) {
        _error = 'Impossible d\'afficher le PDF.';
      }
    });
  }

  @override
  void dispose() {
    _controller.loadingState.removeListener(_onLoadingChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LeadwayTheme(
      child: Scaffold(
      backgroundColor: LeadwayBrand.of(context).bg,
      appBar: AppBar(
        backgroundColor: LeadwayBrand.primary,
        foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Partager',
            onPressed: widget.onShare,
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            tooltip: 'Enregistrer',
            onPressed: widget.onSave,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : Stack(
              children: [
                PdfViewPinch(
                  controller: _controller,
                  padding: 12,
                  builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                    options: const DefaultBuilderOptions(),
                    documentLoaderBuilder: (_) => const Center(child: CircularProgressIndicator()),
                    pageLoaderBuilder: (_) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    errorBuilder: (_, error) => Center(child: Text('Erreur : $error')),
                  ),
                ),
                if (_loading)
                  const Center(child: CircularProgressIndicator(color: LeadwayBrand.primary)),
              ],
            ),
      ),
    );
  }
}
