import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/services/pdf_cache_service.dart';
import 'package:cotorra_app/widgets/common/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfVisualizerScreen extends StatefulWidget {
  final Documento documento;

  const PdfVisualizerScreen({super.key, required this.documento});

  @override
  State<PdfVisualizerScreen> createState() => _PdfVisualizerScreenState();
}

class _PdfVisualizerScreenState extends State<PdfVisualizerScreen> {
  final PdfCacheService _pdfCacheService = PdfCacheService();

  bool _isLoading = true;
  bool _isPdfLoading = true;
  String? _localPath;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isCached = false;

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

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF7CB342);

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
                color: Colors.black.withOpacity(0.05),
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
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
                          Uri.parse(
                            widget.documento.archivoUrlPublica ??
                                widget.documento.archivoUrl,
                          ),
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
      ],
    );
  }
}
