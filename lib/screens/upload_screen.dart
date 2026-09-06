import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cotorra_app/providers/auth_provider.dart';
import 'package:cotorra_app/models/materia.dart';
import 'package:cotorra_app/services/api_service.dart';
import 'package:cotorra_app/widgets/common/materia_dropdown.dart';

enum UploadType { archivo, enlace }

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _tagController = TextEditingController();
  final _autorController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _urlController = TextEditingController();
  final GlobalKey<MateriaDropdownState> _materiaDropdownKey =
      GlobalKey<MateriaDropdownState>();

  final ApiService _apiService = ApiService();

  UploadType _uploadType = UploadType.archivo;
  int? _selectedTipoDocumentoId;
  int? _selectedCarreraId;
  Materia? _selectedMateria;
  String? _selectedAnoAcademico;
  final List<String> _tags = [];
  String? _fileName;
  String? _fileBase64;
  bool _isUploading = false;

  static const List<Map<String, dynamic>> _tiposDocumento = [
    {"nombre": "APUNTE", "id": 1},
    {"nombre": "TP", "id": 2},
    {"nombre": "MANUAL", "id": 3},
    {"nombre": "TESIS", "id": 4},
    {"nombre": "EXAMEN", "id": 5},
    {"nombre": "PRESENTACION", "id": 6},
    {"nombre": "MODELO", "id": 7},
    {"nombre": "OTRO", "id": 8},
  ];

  static const List<String> _anosAcademicos = [
    '2026',
    '2025',
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCarrera();
    });
  }

  void _initCarrera() {
    final auth = context.read<AuthProvider>();
    if (auth.userCarreras.isNotEmpty) {
      setState(() {
        _selectedCarreraId = auth.userCarreras.first.id;
      });
      _materiaDropdownKey.currentState?.resetAndLoad(_selectedCarreraId!);
    }
  }

  // Usado por la UI de tags (bloque comentado temporalmente ~línea 500);
  // _tags y _removeTag siguen activos para los chips existentes.
  // ignore: unused_element
  void _addTag() {
    final text = _tagController.text.trim();
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'txt'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _fileName = file.name;
          if (file.bytes != null) {
            _fileBase64 = base64Encode(file.bytes!);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar archivo: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_uploadType == UploadType.archivo && _fileBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un archivo'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_uploadType == UploadType.enlace && _urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa una URL'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedMateria == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una materia'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final auth = context.read<AuthProvider>();
      final token = auth.token;

      print('=== UPLOAD SUBMIT ===');
      print('titulo: ${_titleController.text.trim()}');
      print('tipo: $_selectedTipoDocumentoId');
      print('carreraId: $_selectedCarreraId');
      print('materiaId: ${_selectedMateria?.id}');
      print('anoAcademico: $_selectedAnoAcademico');
      print('autor: ${_autorController.text.trim()}');
      print('descripcion: ${_descripcionController.text.trim()}');
      print('uploadType: $_uploadType');
      if (_uploadType == UploadType.archivo) {
        print('fileName: $_fileName');
        print('fileBase64 length: ${_fileBase64?.length}');
      } else {
        print('url: ${_urlController.text.trim()}');
      }
      print('======================');

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      if (_uploadType == UploadType.archivo) {
        await _apiService.uploadDocumento(
          token,
          titulo: _titleController.text.trim(),
          archivoBase64: _fileBase64!,
          tipo: _selectedTipoDocumentoId!,
          descripcion: _descripcionController.text.trim().isNotEmpty
              ? _descripcionController.text.trim()
              : null,
          autor: _autorController.text.trim().isNotEmpty
              ? _autorController.text.trim()
              : null,
          materiaId: _selectedMateria?.id,
          anoAcademico: _selectedAnoAcademico,
        );
      } else {
        await _apiService.createDocumentoLink(
          token,
          titulo: _titleController.text.trim(),
          urlExterna: _urlController.text.trim(),
          tipo: _selectedTipoDocumentoId!,
          descripcion: _descripcionController.text.trim().isNotEmpty
              ? _descripcionController.text.trim()
              : null,
          autor: _autorController.text.trim().isNotEmpty
              ? _autorController.text.trim()
              : null,
          materiaId: _selectedMateria?.id,
          anoAcademico: _selectedAnoAcademico,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Documento subido con éxito! Pendiente de aprobación.',
            ),
            backgroundColor: Color(0xFF7CB342),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagController.dispose();
    _autorController.dispose();
    _descripcionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF7CB342);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Compartir Material',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<UploadType>(
                  segments: const [
                    ButtonSegment(
                      value: UploadType.archivo,
                      label: Text('Archivo'),
                      icon: Icon(Icons.attach_file),
                    ),
                    ButtonSegment(
                      value: UploadType.enlace,
                      label: Text('Enlace'),
                      icon: Icon(Icons.link),
                    ),
                  ],
                  selected: {_uploadType},
                  onSelectionChanged: (Set<UploadType> selection) {
                    setState(() {
                      _uploadType = selection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),
                if (_uploadType == UploadType.archivo) ...[
                  GestureDetector(
                    onTap: _selectFile,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryGreen.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _fileName != null
                                ? Icons.picture_as_pdf
                                : Icons.cloud_upload_outlined,
                            size: 40,
                            color: primaryGreen,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _fileName ?? 'Toca para seleccionar archivo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _fileName != null
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_fileName == null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'PDF, DOCX, TXT hasta 20MB',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'URL externa',
                      hintText: 'https://...',
                      prefixIcon: const Icon(Icons.link),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa una URL';
                      }
                      if (!Uri.tryParse(value)!.hasAbsolutePath) {
                        return 'URL inválida';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del documento',
                    hintText: 'Ej. Apuntes Análisis Matemático I - Límites',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Por favor ingresa un nombre' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedTipoDocumentoId,
                  decoration: InputDecoration(
                    labelText: 'Tipo de documento',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _tiposDocumento.map((tipo) {
                    return DropdownMenuItem<int>(
                      value: tipo['id'] as int,
                      child: Text(tipo['nombre'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedTipoDocumentoId = value);
                  },
                  validator: (value) =>
                      value == null ? 'Selecciona un tipo' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedCarreraId,
                  decoration: InputDecoration(
                    labelText: 'Carrera',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  isExpanded: true,
                  items: context.watch<AuthProvider>().userCarreras.map((
                    carrera,
                  ) {
                    return DropdownMenuItem<int>(
                      value: carrera.id,
                      child: Text(
                        carrera.nombre,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCarreraId = value;
                      _selectedMateria = null;
                    });
                    if (value != null) {
                      _materiaDropdownKey.currentState?.resetAndLoad(value);
                    }
                  },
                  validator: (value) =>
                      value == null ? 'Selecciona una carrera' : null,
                ),
                const SizedBox(height: 16),
                MateriaDropdown(
                  key: _materiaDropdownKey,
                  value: _selectedMateria,
                  enabled: _selectedCarreraId != null,
                  onChanged: (materia) {
                    setState(() {
                      _selectedMateria = materia;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedAnoAcademico,
                  decoration: InputDecoration(
                    labelText: 'Año académico',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _anosAcademicos.map((ano) {
                    return DropdownMenuItem<String>(
                      value: ano,
                      child: Text(ano),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedAnoAcademico = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _autorController,
                  decoration: InputDecoration(
                    labelText: 'Autor (opcional)',
                    hintText: 'Nombre del autor del material',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción (opcional)',
                    hintText: 'Breve descripción del material',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
                // const SizedBox(height: 24),
                // const Text(
                //   'Añadir tags',
                //   style: TextStyle(
                //     fontSize: 14,
                //     fontWeight: FontWeight.w700,
                //     color: Colors.black87,
                //   ),
                // ),
                // const SizedBox(height: 8),
                // Row(
                //   children: [

                // Expanded(
                //   child: TextField(
                //     controller: _tagController,
                //     decoration: InputDecoration(
                //       hintText: 'Ej. derivadas, finales, apuntes',
                //       border: OutlineInputBorder(
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //     ),
                //     onSubmitted: (_) => _addTag(),
                //   ),
                // ),
                // const SizedBox(width: 12),
                //     Container(
                //       height: 52,
                //       decoration: BoxDecoration(
                //         color: primaryGreen,
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //       child: IconButton(
                //         icon: const Icon(Icons.add, color: Colors.white),
                //         onPressed: _addTag,
                //       ),
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 16),
                if (_tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text(
                          tag,
                          style: const TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        deleteIcon: const Icon(
                          Icons.close,
                          size: 14,
                          color: primaryGreen,
                        ),
                        onDeleted: () => _removeTag(tag),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 32),
                _isUploading
                    ? const Center(
                        child: CircularProgressIndicator(color: primaryGreen),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _submit,
                        child: const Text(
                          'Subir Material',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
