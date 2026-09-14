import 'dart:io';
import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/services/image_cache_service.dart';
import 'package:cotorra_app/widgets/common/loading_overlay.dart';
import 'package:flutter/material.dart';

class ImageVisualizerScreen extends StatefulWidget {
  final Documento documento;

  const ImageVisualizerScreen({super.key, required this.documento});

  @override
  State<ImageVisualizerScreen> createState() => _ImageVisualizerScreenState();
}

class _ImageVisualizerScreenState extends State<ImageVisualizerScreen> {
  final ImageCacheService _imageCacheService = ImageCacheService();

  bool _isLoading = true;
  bool _isImageLoading = true;
  // Reserva de estado offline (cache/download/delete); pendiente de
  // consumo por el indicador offline en la barra superior.
  // ignore: unused_field
  bool _isCached = false;
  String? _localPath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkCacheAndLoad();
  }

  Future<void> _checkCacheAndLoad() async {
    final isCached = await _imageCacheService.isImageCached(
      widget.documento.id,
    );
    setState(() => _isCached = isCached);

    if (isCached) {
      final path = await _imageCacheService.getLocalImagePath(
        widget.documento.id,
      );
      if (path != null) {
        setState(() {
          _localPath = path;
          _isLoading = false;
          _isImageLoading = false;
        });
        return;
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() => _errorMessage = null),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final imageUrl =
        widget.documento.archivoUrlPublica ?? widget.documento.archivoUrl;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: Colors.grey.shade200,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: _localPath != null
                        ? Image.file(
                            File(_localPath!),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildErrorWidget();
                            },
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                if (_isImageLoading) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted) {
                                      setState(() => _isImageLoading = false);
                                    }
                                  });
                                }
                                return child;
                              }
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildErrorWidget();
                            },
                          ),
                  ),
                ),
                if (_isImageLoading)
                  const LoadingOverlay(message: 'Cargando imagen...'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.documento.descripcion != null &&
                    widget.documento.descripcion!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      widget.documento.descripcion!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.documento.autor ?? 'Anónimo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.documento.materia?.nombre ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No se pudo cargar la imagen',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() => _isImageLoading = true);
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
