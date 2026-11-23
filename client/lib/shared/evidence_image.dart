import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/data/api_client.dart';

class EvidenceImage extends StatefulWidget {
  const EvidenceImage({
    required this.url,
    required this.api,
    required this.fit,
    this.width,
    this.height,
    super.key,
  });

  final String url;
  final ApiClient? api;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  State<EvidenceImage> createState() => _EvidenceImageState();
}

class _EvidenceImageState extends State<EvidenceImage> {
  static final _managed = RegExp(
    r'^(?:/api/|/)?files/([a-f0-9-]{36}\.[a-z0-9]+)$',
    caseSensitive: false,
  );

  Future<Uint8List>? _bytes;
  String? _filename;
  String? _token;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant EvidenceImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.api != widget.api ||
        _token != widget.api?.token) {
      _load();
    }
  }

  void _load() {
    final path = Uri.tryParse(widget.url)?.path ?? '';
    _filename = _managed.firstMatch(path)?.group(1);
    final api = widget.api;
    _token = api?.token;
    _bytes = _filename != null && api != null && _token != null
        ? api.getRawBytes('Files/$_filename')
        : null;
  }

  Widget _unavailable() => const Tooltip(
    message: 'No se pudo cargar la evidencia',
    child: Center(child: Icon(Icons.broken_image_outlined)),
  );

  @override
  Widget build(BuildContext context) {
    if (_filename == null) {
      final uri = Uri.tryParse(widget.url);
      if (uri == null || !const {'http', 'https'}.contains(uri.scheme)) {
        return _unavailable();
      }
      return Image.network(
        widget.url,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, _, _) => _unavailable(),
      );
    }
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: FutureBuilder<Uint8List>(
        future: _bytes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final bytes = snapshot.data;
          if (_bytes == null || bytes == null) return _unavailable();
          return Image.memory(
            bytes,
            fit: widget.fit,
            errorBuilder: (_, _, _) => _unavailable(),
          );
        },
      ),
    );
  }
}
