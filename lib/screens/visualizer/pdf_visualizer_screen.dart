import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/services/pdf_cache_service.dart';
import 'package:cotorra_app/widgets/common/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfVisualizerScreen extends StatefulWidget {
  final Documento documento;

  const PdfVisualizerScreen({super.key, required this.documento});

  @override
  State<PdfVisualizerScreen> createState() => _PdfVisualizerScreenState();
}

class _PdfVisualizerScreenState extends State<PdfVisualizerScreen> {
  final PdfCacheService _pdfCacheService = PdfCacheService();

  // Controller del viewer: sobrevive al rebuild de "Recargar" (el widget
  // hace _attach(null) en dispose y vuelve a atar el mismo controller).
  final PdfViewerController _pdfController = PdfViewerController();
  final TextEditingController _pageInputController = TextEditingController(
    text: '1',
  );
  final FocusNode _pageInputFocus = FocusNode();

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

  @override
  void dispose() {
    _pageInputController.dispose();
    _pageInputFocus.dispose();
    super.dispose();
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

  /// Sincroniza el input de página con la página actual, salvo que el
  /// usuario esté editando el campo.
  void _syncPageInput() {
    if (!_pageInputFocus.hasFocus) {
      _pageInputController.text = '$_currentPage';
    }
  }

  /// Va a la página ingresada en el input, clampeada a [1, _totalPages].
  void _goToPageFromInput(String value) {
    _pageInputFocus.unfocus();
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      _pageInputController.text = '$_currentPage';
      return;
    }
    final max = _totalPages > 0 ? _totalPages : parsed;
    final target = parsed.clamp(1, max).toInt();
    _pageInputController.text = '$target';
    if (target != _currentPage) {
      _pdfController.goToPage(pageNumber: target);
    }
  }

  /// Params compartidos por ambas ramas del viewer (file / uri).
  PdfViewerParams _buildViewerParams() => PdfViewerParams(
    onPageChanged: (pageNumber) {
      setState(() => _currentPage = pageNumber ?? 1);
      _syncPageInput();
    },
    onDocumentChanged: (document) {
      setState(() {
        _totalPages = document?.pages.length ?? 0;
        _currentPage = 1;
        _isPdfLoading = false;
      });
      _syncPageInput();
    },
  );

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            // Theme-aware: en oscuro usa la misma superficie que las cards.
            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 44,
                      child: TextField(
                        controller: _pageInputController,
                        focusNode: _pageInputFocus,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.go,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 2,
                          ),
                          counterText: '',
                          hintText: '—',
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onSubmitted: _goToPageFromInput,
                      ),
                    ),
                    Text(
                      ' / $_totalPages',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
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
                      color: primaryColor,
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
                          controller: _pdfController,
                          params: _buildViewerParams(),
                        )
                      : PdfViewer.uri(
                          Uri.parse(
                            widget.documento.archivoUrlPublica ??
                                widget.documento.archivoUrl,
                          ),
                          controller: _pdfController,
                          params: _buildViewerParams(),
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
