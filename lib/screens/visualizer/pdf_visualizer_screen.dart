import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/providers/auth_provider.dart';
import 'package:cotorra_app/providers/favorites_cache_provider.dart';
import 'package:cotorra_app/services/api_service.dart';
import 'package:cotorra_app/services/pdf_cache_service.dart';
import 'package:cotorra_app/widgets/common/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

class PdfVisualizerScreen extends StatefulWidget {
  final Documento documento;

  const PdfVisualizerScreen({super.key, required this.documento});

  @override
  State<PdfVisualizerScreen> createState() => _PdfVisualizerScreenState();
}

class _PdfVisualizerScreenState extends State<PdfVisualizerScreen> {
  final PdfCacheService _pdfCacheService = PdfCacheService();
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool _isPdfLoading = true;
  bool _isProcessingFavorite = false;
  String? _localPath;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isCached = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkCacheAndLoad();
  }

  Future<void> _checkCacheAndLoad() async {
    final isCached = await _pdfCacheService.isPdfCached(widget.documento.id);
    setState(() => _isCached = isCached);

    if (isCached) {
      final path = await _pdfCacheService.getLocalPdfPath(widget.documento.id);
      if (path != null) {
        setState(() {
          _localPath = path;
          _isLoading = false;
          _isPdfLoading = false;
        });
        return;
      }
    }
    setState(() => _isLoading = false);
  }

  void _checkIfFavorite() {
    final favProvider = context.read<FavoritesCacheProvider>();
    final isFav = favProvider.favorites.any((doc) => doc.id == widget.documento.id);
    setState(() => _isFavorite = isFav);
  }

  Future<void> _toggleFavorite() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para agregar a favoritos')),
      );
      return;
    }

    setState(() => _isProcessingFavorite = true);

    try {
      final favProvider = context.read<FavoritesCacheProvider>();

      final result = await _apiService.toggleFavorito(
        auth.token!,
        widget.documento.id,
      );

      final isNowFavorite = result['is_favorite'] as bool? ?? false;

      if (isNowFavorite) {
        await favProvider.load(auth.token!, auth.userId!);
        await _downloadPdfForOffline();
      } else {
        await favProvider.load(auth.token!, auth.userId!);
        await _deletePdf();
      }

      if (mounted) {
        setState(() {
          _isFavorite = isNowFavorite;
          _isProcessingFavorite = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNowFavorite
                ? 'Agregado a favoritos y guardado offline'
                : 'Eliminado de favoritos'),
            backgroundColor: const Color(0xFF7CB342),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadPdfForOffline() async {
    final url = widget.documento.archivoUrlPublica ?? widget.documento.archivoUrl;

    try {
      final path = await _pdfCacheService.downloadAndCachePdf(
        url,
        widget.documento.id,
      );

      if (mounted) {
        setState(() {
          _localPath = path;
          _isCached = true;
        });
      }
    } catch (e) {
      debugPrint('Error downloading PDF for offline: $e');
    }
  }

  Future<void> _deletePdf() async {
    await _pdfCacheService.deletePdf(widget.documento.id);
    if (mounted) {
      setState(() {
        _localPath = null;
        _isCached = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF7CB342);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfFavorite();
    });

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
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
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_totalPages > 0)
                Text(
                  'Página $_currentPage de $_totalPages',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                )
              else
                const SizedBox.shrink(),
              Row(
                children: [
                  if (_isCached)
                    IconButton(
                      icon: const Icon(Icons.offline_pin, size: 20),
                      onPressed: null,
                      tooltip: 'Disponible offline',
                      color: primaryGreen,
                    )
                  else
                    const SizedBox.shrink(),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: () {
                      setState(() {
                        _localPath = null;
                        _isCached = false;
                      });
                      _checkCacheAndLoad();
                    },
                    tooltip: 'Recargar',
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  _localPath != null
                      ? PdfViewer.file(
                          _localPath!,
                          params: PdfViewerParams(
                            onPageChanged: (pageNumber) {
                              setState(() => _currentPage = pageNumber ?? 1);
                            },
                            onDocumentChanged: (document) {
                              setState(() {
                                _totalPages = document?.pages.length ?? 0;
                                _currentPage = 1;
                                _isPdfLoading = false;
                              });
                            },
                          ),
                        )
                      : PdfViewer.uri(
                          Uri.parse(widget.documento.archivoUrlPublica ??
                              widget.documento.archivoUrl),
                          params: PdfViewerParams(
                            onPageChanged: (pageNumber) {
                              setState(() => _currentPage = pageNumber ?? 1);
                            },
                            onDocumentChanged: (document) {
                              setState(() {
                                _totalPages = document?.pages.length ?? 0;
                                _currentPage = 1;
                                _isPdfLoading = false;
                              });
                            },
                          ),
                        ),
                  if (_isPdfLoading)
                    LoadingOverlay(message: 'Cargando documento...'),
                ],
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isProcessingFavorite ? null : _toggleFavorite,
                icon: _isProcessingFavorite
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: Colors.white,
                      ),
                label: Text(
                  _isFavorite ? 'En Favoritos' : 'Agregar a Favoritos',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
