import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/providers/auth_provider.dart';
import 'package:cotorra_app/providers/favorites_cache_provider.dart';
import 'package:cotorra_app/screens/visualizer/image_visualizer_screen.dart';
import 'package:cotorra_app/screens/visualizer/link_visualizer_screen.dart';
import 'package:cotorra_app/screens/visualizer/pdf_visualizer_screen.dart';
import 'package:cotorra_app/services/api/favorites_service.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:cotorra_app/services/api_service.dart';
import 'package:cotorra_app/services/download_service.dart';
import 'package:cotorra_app/widgets/common/document_report_sheet.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class DocumentViewScreen extends StatefulWidget {
  final Documento documento;

  const DocumentViewScreen({super.key, required this.documento});

  @override
  State<DocumentViewScreen> createState() => _DocumentViewScreenState();
}

class _DocumentViewScreenState extends State<DocumentViewScreen> {
  final ApiService _apiService = ApiService();
  final DownloadService _downloadService = DownloadService();

  Documento? _documento;
  bool _isLoading = true;
  String? _errorMessage;

  // Estado de la barra de acciones inferior.
  bool _isFavorite = false;
  bool _isProcessingFavorite = false;
  bool _isDownloading = false;
  bool _isDownloaded = false;

  static const _primaryGreen = Color(0xFF7CB342);

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
        _checkFavoriteState();
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

  /// Tipo efectivo del documento (mismas reglas que _buildVisualizer).
  /// Devuelve 'PDF', 'IMAGEN', 'ENLACE' u 'OTRO' (no descargable).
  String get _tipoEfectivo {
    final documento = _documento ?? widget.documento;
    final formatoNombre = documento.formato?.nombre.toUpperCase();

    if (formatoNombre == null) {
      final isImage =
          documento.titulo.toLowerCase().contains('laboratorio') ||
          documento.titulo.toLowerCase().contains('imagen');
      if (isImage) return 'IMAGEN';
      if (documento.archivoUrl.startsWith('http')) return 'PDF';
      return 'PDF';
    }

    switch (formatoNombre) {
      case 'PDF':
        return 'PDF';
      case 'IMAGEN':
        return 'IMAGEN';
      case 'ENLACE':
        return 'ENLACE';
      default:
        if (_unsupportedFormats.contains(formatoNombre)) return 'OTRO';
        return 'PDF';
    }
  }

  /// ApiClient autenticado con el token activo (patrón del sheet de reporte).
  ApiClient _authedClient() {
    final client = ApiClient();
    final token = context.read<AuthProvider>().token;
    if (token != null && token.isNotEmpty) client.setToken(token);
    return client;
  }

  Future<void> _checkFavoriteState() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.token == null) return;
    try {
      final isFav = await FavoritesService(
        _authedClient(),
      ).checkFavorito((_documento ?? widget.documento).id);
      if (mounted) setState(() => _isFavorite = isFav);
    } catch (_) {
      // Sin check no crítico: queda en false.
    }
  }

  Future<void> _download() async {
    if (_isDownloading) return;

    final doc = _documento ?? widget.documento;

    if (_tipoEfectivo == 'ENLACE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este documento es solo un enlace, no tiene archivo para descargar.',
          ),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iniciá sesión para descargar')),
      );
      return;
    }

    setState(() => _isDownloading = true);
    try {
      final fileName = await _downloadService.downloadToDownloads(
        doc.id,
        auth.token!,
        fallbackName: _fallbackFileName(doc),
      );
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _isDownloaded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Se guardó en la carpeta Descargas: $fileName'),
          backgroundColor: _primaryGreen,
        ),
      );
    } catch (e) {
      debugPrint('[DocumentViewScreen] Error de descarga: $e');
      if (!mounted) return;
      setState(() => _isDownloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_downloadErrorMessage(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// Nombre de respaldo si el backend no envía Content-Disposition.
  String _fallbackFileName(Documento doc) {
    final clean = doc.titulo.replaceAll(RegExp(r'[<>:"/\\|?*\n]'), '_').trim();
    final ext = switch (_tipoEfectivo) {
      'PDF' => '.pdf',
      'IMAGEN' => '.jpg',
      _ => '',
    };
    final base = clean.isEmpty ? 'documento' : clean;
    final name = '$base$ext';
    return name.length > 120 ? name.substring(0, 120) : name;
  }

  String _downloadErrorMessage(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status == 401) return 'Tu sesión expiró, volvé a iniciar sesión.';
      if (status == 404) return 'El documento no está disponible.';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Verificá tu conexión a internet.';
      }
    }
    if (e.toString().contains('SocketException')) {
      return 'Verificá tu conexión a internet.';
    }
    if (e is PlatformException) {
      // Errores del canal nativo de guardado (MediaStore/permisos).
      if (e.code == 'PERMISSION_DENIED') {
        return 'Denegaste el permiso de almacenamiento; volvé a intentar.';
      }
      return 'El sistema no permitió guardar en Descargas: ${e.message ?? e.code}';
    }
    // Error no clasificado: se registra completo para diagnóstico y se le
    // muestra al usuario un mensaje entendible (no el texto crudo técnico).
    debugPrint('[Download] error no clasificado: $e');
    return 'No se pudo descargar. Intentá de nuevo en unos minutos.';
  }

  Future<void> _toggleFavorite() async {
    if (_isProcessingFavorite) return;

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iniciá sesión para guardar favoritos')),
      );
      return;
    }

    setState(() => _isProcessingFavorite = true);
    final doc = _documento ?? widget.documento;
    // Leemos el provider antes del async gap (lint build_context_across_async).
    final favProvider = context.read<FavoritesCacheProvider>();

    try {
      final result = await FavoritesService(
        _authedClient(),
      ).toggleFavorito(doc.id);
      final isNowFavorite = result['is_favorite'] as bool? ?? !_isFavorite;

      // Mantener sincronizada la caché de la pestaña de favoritos.
      if (auth.userId != null) {
        await favProvider.load(auth.token!, auth.userId!);
      }

      if (!mounted) return;
      setState(() {
        _isFavorite = isNowFavorite;
        _isProcessingFavorite = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowFavorite ? 'Agregado a favoritos' : 'Quitado de favoritos',
          ),
          backgroundColor: _primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingFavorite = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException && e.message.trim().isNotEmpty
                ? e.message
                : 'No se pudo actualizar el favorito. Intentá de nuevo.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — próximamente 🚧'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  Widget _barButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
    Widget? overrideIcon,
  }) {
    return Expanded(
      child: IconButton(
        icon: overrideIcon ?? Icon(icon, color: color),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        child: Row(
          children: [
            _barButton(
              icon: Icons.star_border,
              tooltip: 'Valorar',
              onPressed: () => _comingSoon('Valorar'),
            ),
            _barButton(
              icon: Icons.mode_comment_outlined,
              tooltip: 'Comentarios',
              onPressed: () => _comingSoon('Comentarios'),
            ),
            _barButton(
              icon: _isDownloaded ? Icons.download_done : Icons.download,
              tooltip: _isDownloaded
                  ? 'Descargado (carpeta Descargas)'
                  : 'Descargar',
              color: _isDownloaded ? _primaryGreen : null,
              onPressed: _download,
              overrideIcon: _isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : null,
            ),
            _barButton(
              icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
              tooltip: _isFavorite
                  ? 'Quitar de favoritos'
                  : 'Agregar a favoritos',
              color: _isFavorite ? Colors.red : null,
              onPressed: _toggleFavorite,
              overrideIcon: _isProcessingFavorite
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
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
      bottomNavigationBar: _isLoading || _errorMessage != null
          ? null
          : _buildBottomBar(),
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
