import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/models/materia.dart';
import 'package:cotorra_app/models/tipoDocumento.dart';
import 'package:cotorra_app/providers/auth_provider.dart';
import 'package:cotorra_app/services/api/catalogs_service.dart';
import 'package:cotorra_app/services/api/documents_service.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:cotorra_app/utils/document_action_errors.dart';
import 'package:cotorra_app/utils/document_update_body.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Resultado del sheet de edición — contrato con PerfilScreen.
///
/// - [documento]: PUT devolvió 200 con el `Documento` del servidor; perfil
///   lo aplica con `applyUpdate` (R5).
/// - [removeLocally]: PUT devolvió 404 — el documento ya no existe; el
///   sheet ya mostró la Snackbar roja y perfil solo aplica `applyDelete`.
class DocumentEditResult {
  const DocumentEditResult({this.documento, this.removeLocally = false});

  final Documento? documento;
  final bool removeLocally;
}

/// Bottom sheet para editar los metadatos de un documento propio (R2, R3).
///
/// Prellena con el [original] tocado en Perfil — sin fetch extra. Carga los
/// catálogos (`tipos-documento` y `materias` público con `limit: 100`) para
/// los dropdowns. NO expone reemplazo de archivo ni aprobación: solo
/// metadatos.
///
/// El sheet es dueño del PUT (decisión de diseño): guarda `_isSubmitting`
/// para bloquear doble submit, cierra sin request si el diff es vacío, y
/// ante errores recuperables (401/403/otros/SocketException) muestra la
/// Snackbar roja del mapper compartido y SE QUEDA ABIERTO re-habilitando
/// "Guardar" (R6). El único error que lo cierra es el 404, recién traducido
/// a `removeLocally` para que perfil quite el item de la caché.
class DocumentEditSheet extends StatefulWidget {
  const DocumentEditSheet({super.key, required this.original});

  /// Documento con los valores a prellenar (viene de la tarjeta tocada).
  final Documento original;

  /// Abre el sheet sobre [context]. Retorna el resultado de la edición o
  /// null si el usuario lo descarta sin guardar.
  static Future<DocumentEditResult?> show(
    BuildContext context, {
    required Documento original,
  }) {
    return showModalBottomSheet<DocumentEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        // Espacio inferior dinámico para que el teclado no tape el input.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DocumentEditSheet(original: original),
      ),
    );
  }

  @override
  State<DocumentEditSheet> createState() => _DocumentEditSheetState();
}

class _DocumentEditSheetState extends State<DocumentEditSheet> {
  static const primaryGreen = Color(0xFF7CB342);

  /// Años académicos offered por el formulario (mismo rango que el upload).
  static const _anosAcademicos = [2020, 2021, 2022, 2023, 2024, 2025, 2026];

  late final TextEditingController _tituloController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _autorController;

  // Selección de los dropdowns. `tipo` guarda el id como String porque
  // buildUpdateBody lo parsea con int.tryParse y lo serializa como int.
  String? _tipo;
  int? _materiaId;
  int? _anoAcademico;

  List<TipoDocumento> _tipos = const [];
  List<Materia> _materias = const [];
  bool _cargandoCatalogos = true;
  bool _isSubmitting = false;

  /// Años que realmente se muestran: los estándar más, cuando hace falta, el
  /// año legado del documento como opción sintética (ver [initState]).
  late final List<int> _anosOpciones;

  @override
  void initState() {
    super.initState();
    final doc = widget.original;
    _tituloController = TextEditingController(text: doc.titulo);
    _descripcionController = TextEditingController(text: doc.descripcion ?? '');
    _autorController = TextEditingController(text: doc.autor ?? '');
    // Semilla de las selecciones desde el documento tocado: así ningún valor
    // es null ANTES de que carguen los catálogos — un guardado en esa ventana
    // diffeaba null contra el valor real y borraba el campo en el servidor
    // (verify WARNING-1). Además, "Guardar" queda deshabilitado en la carga.
    _tipo = doc.tipo.toString();
    _materiaId = doc.materiaId;
    final anoOriginal = int.tryParse(doc.anoAcademico ?? '');
    if (anoOriginal != null && !_anosAcademicos.contains(anoOriginal)) {
      // Año legado fuera del rango 2020–2026: misma estrategia que la materia
      // sintética — se ofrece como opción extra y queda preseleccionado, así
      // un documento intocado no mete `año_academico` en el diff ni lo borra
      // (verify WARNING-2), y el usuario puede cambiar a un año estándar.
      _anosOpciones = [anoOriginal, ..._anosAcademicos];
    } else {
      _anosOpciones = _anosAcademicos;
    }
    _anoAcademico = anoOriginal;
    _cargarCatalogos();
  }

  /// Carga tipos-doc y materias (públicos, requireAuth: false). Falla en
  /// silencio: sin catálogos quedan los dropdowns vacíos y la edición de
  /// textos sigue disponible — el diff nunca enviará un valor inexistente.
  Future<void> _cargarCatalogos() async {
    List<TipoDocumento> tipos = const [];
    List<Materia> materias = const [];
    try {
      final catalogs = CatalogsService(ApiClient());
      final tiposFuture = catalogs.getTiposDocumento();
      final materiasFuture = catalogs.getMaterias(limit: 100);
      tipos = await tiposFuture;
      materias = await materiasFuture;
    } catch (_) {
      // Fallback silencioso (patrón de _loadStats en Perfil).
    }
    if (!mounted) return;

    final doc = widget.original;
    // Fidelidad de prefill (R2): si el materiaId del documento no está en
    // la lista (tope de 100 del catálogo plano), se anteponen una entrada
    // sintética con el nombre propio del documento.
    if (doc.materiaId != null && !materias.any((m) => m.id == doc.materiaId)) {
      materias = [
        Materia(
          id: doc.materiaId!,
          nombre: doc.materia?.nombre ?? 'Materia actual',
        ),
        ...materias,
      ];
    }

    setState(() {
      _tipos = tipos;
      _materias = materias;
      // Si el tipo semilla no quedó en el catálogo (o la carga falló), se
      // deselecciona: DropdownButton exige value ∈ items, y con _tipo null
      // buildUpdateBody omite la clave y el tipo original se conserva.
      if (!tipos.any((t) => t.id == doc.tipo)) _tipo = null;
      if (doc.materiaId != null && materias.any((m) => m.id == doc.materiaId)) {
        _materiaId = doc.materiaId;
      }
      _cargandoCatalogos = false;
    });
  }

  Future<void> _guardar() async {
    // Doble resguardo (verify WARNING-1): el botón ya está deshabilitado durante
    // la carga de catálogos, pero el handler tampoco debe correr ahí.
    if (_isSubmitting || _cargandoCatalogos) return;

    if (_tituloController.text.trim().isEmpty) {
      // Espejo del validator del upload: el título nunca viaja vacío.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El título no puede estar vacío.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final body = buildUpdateBody(
      widget.original,
      _tituloController.text,
      _descripcionController.text,
      _tipo ?? '',
      _materiaId,
      _anoAcademico,
      _autorController.text,
    );

    // Capturamos messenger y navigator ANTES del async gap: el sheet se
    // cierra en los caminos de éxito/404 y el SnackBar debe vivir.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Sin cambios: cerrar sin enviar PUT (R3 — el diff vacío es un no-op).
    if (body.isEmpty) {
      navigator.pop();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      // ApiClient propio con el token activo (patrón del resto de la app).
      final client = ApiClient();
      if (token != null && token.isNotEmpty) client.setToken(token);
      final actualizado = await DocumentsService(
        client,
      ).updateDocumento(widget.original.id, body);
      navigator.pop(DocumentEditResult(documento: actualizado));
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // El documento ya no existe: cerrar con removeLocally y mostrar el
        // mensaje "ya no existe" — perfil quita el item de lista y caché.
        navigator.pop(const DocumentEditResult(removeLocally: true));
        messenger.showSnackBar(
          SnackBar(
            content: Text(documentActionErrorMessage(e)),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      _reintentar(messenger, e);
    } catch (e) {
      // Error recuperable (SocketException y otros): el sheet se queda
      // abierto con "Guardar" re-habilitado, sin mutación local (R6).
      _reintentar(messenger, e);
    }
  }

  /// Snackbar roja con el mensaje del mapper compartido y guard liberado.
  void _reintentar(ScaffoldMessengerState messenger, Object error) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(documentActionErrorMessage(error)),
        backgroundColor: Colors.redAccent,
      ),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
  }

  InputDecoration _decoracion(String etiqueta) {
    return InputDecoration(
      labelText: etiqueta,
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _campoTexto(
    String etiqueta,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        decoration: _decoracion(etiqueta),
      ),
    );
  }

  Widget _campoDropdown<T>({
    required String etiqueta,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                isExpanded: true,
                value: value,
                hint: hint == null
                    ? null
                    : Text(
                        hint,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                items: items,
                onChanged: _isSubmitting ? null : onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra de arrastre
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Editar documento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.original.titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: _cargandoCatalogos
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _campoTexto('Título', _tituloController),
                          _campoTexto(
                            'Descripción',
                            _descripcionController,
                            maxLines: 3,
                          ),
                          _campoDropdown<String>(
                            etiqueta: 'Tipo de documento',
                            value: _tipo,
                            hint: 'Seleccioná un tipo',
                            items: _tipos
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t.id.toString(),
                                    child: Text(
                                      t.nombre,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _tipo = v),
                          ),
                          _campoDropdown<int>(
                            etiqueta: 'Materia',
                            value: _materiaId,
                            hint: 'Sin materia',
                            items: _materias
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m.id,
                                    child: Text(
                                      m.nombre,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _materiaId = v),
                          ),
                          _campoDropdown<int>(
                            etiqueta: 'Año académico',
                            value: _anoAcademico,
                            hint: 'Sin año',
                            items: _anosOpciones
                                .map(
                                  (ano) => DropdownMenuItem(
                                    value: ano,
                                    child: Text('$ano'),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _anoAcademico = v),
                          ),
                          _campoTexto('Autor', _autorController),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // Inhabilitado hasta que los catálogos carguen (verify
              // WARNING-1): guardar en esa ventana podía difear materia null.
              onPressed: _isSubmitting || _cargandoCatalogos ? null : _guardar,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Guardar cambios',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _autorController.dispose();
    super.dispose();
  }
}
