import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/screens/visualizer/image_visualizer_screen.dart';
import 'package:cotorra_app/screens/visualizer/link_visualizer_screen.dart';
import 'package:cotorra_app/screens/visualizer/pdf_visualizer_screen.dart';
import 'package:cotorra_app/services/api_service.dart';
import 'package:cotorra_app/widgets/common/document_report_sheet.dart';
import 'package:flutter/material.dart';

class DocumentViewScreen extends StatefulWidget {
  final Documento documento;

  const DocumentViewScreen({super.key, required this.documento});

  @override
  State<DocumentViewScreen> createState() => _DocumentViewScreenState();
}

class _DocumentViewScreenState extends State<DocumentViewScreen> {
  final ApiService _apiService = ApiService();
  Documento? _documento;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDocumento();
  }

  Future<void> _loadDocumento() async {
    print('[DocumentViewScreen] Cargando documento ID: ${widget.documento.id}');
    try {
      final doc = await _apiService.getDocumento(widget.documento.id);
      print('[DocumentViewScreen] Documento cargado: ${doc.titulo}');
      print(
        '[DocumentViewScreen] Formato: ${doc.formato?.nombre} (id: ${doc.formatoId})',
      );
      print('[DocumentViewScreen] URL: ${doc.archivoUrl}');
      if (mounted) {
        setState(() {
          _documento = doc;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[DocumentViewScreen] Error al cargar documento: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar el documento: $e';
          _isLoading = false;
        });
      }
    }
  }

  static const _unsupportedFormats = [
    'DOCUMENTO',
    'PRESENTACION',
    'HOJA_CALCULO',
    'ZIP',
  ];

  /// Abre el bottom sheet de reporte.
  /// El sheet muestra la confirmación (éxito/error) y se cierra solo.
  Future<void> _reportDocument() async {
    final documento = _documento ?? widget.documento;
    await DocumentReportSheet.show(
      context,
      documentoId: documento.id,
      documentoTitulo: documento.titulo,
    );
  }

  Widget _buildVisualizer() {
    final documento = _documento ?? widget.documento;
    final formatoNombre = documento.formato?.nombre.toUpperCase();

    print(
      '[DocumentViewScreen] _buildVisualizer - formatoNombre: $formatoNombre, titulo: ${documento.titulo}',
    );

    if (formatoNombre == null) {
      final isImage =
          documento.titulo.toLowerCase().contains('laboratorio') ||
          documento.titulo.toLowerCase().contains('imagen');
      final isLink = documento.archivoUrl.startsWith('http');
      print(
        '[DocumentViewScreen] Formato null, fallback heuristica - isImage: $isImage, isLink: $isLink',
      );

      if (isImage) return ImageVisualizerScreen(documento: documento);
      if (isLink) return LinkVisualizerScreen(documento: documento);
      return PdfVisualizerScreen(documento: documento);
    }

    switch (formatoNombre) {
      case 'PDF':
        print('[DocumentViewScreen] Selecionando PdfVisualizerScreen');
        return PdfVisualizerScreen(documento: documento);
      case 'IMAGEN':
        print('[DocumentViewScreen] Selecionando ImageVisualizerScreen');
        return ImageVisualizerScreen(documento: documento);
      case 'ENLACE':
        print('[DocumentViewScreen] Selecionando LinkVisualizerScreen');
        return LinkVisualizerScreen(documento: documento);
      default:
        if (_unsupportedFormats.contains(formatoNombre)) {
          print('[DocumentViewScreen] Formato no soportado: $formatoNombre');
          return _UnsupportedFormatView(formato: formatoNombre);
        }
        print(
          '[DocumentViewScreen] Formato desconocido, usando PdfVisualizerScreen por defecto',
        );
        return PdfVisualizerScreen(documento: documento);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.documento.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Reportar documento',
            onPressed: _reportDocument,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      _loadDocumento();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : _buildVisualizer(),
    );
  }
}

class _UnsupportedFormatView extends StatelessWidget {
  final String formato;

  const _UnsupportedFormatView({required this.formato});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.insert_drive_file,
                size: 64,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Formato no soportado',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'El formato $formato no puede ser visualizado en la app.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
