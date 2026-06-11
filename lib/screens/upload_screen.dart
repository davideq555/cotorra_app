import 'package:flutter/material.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _tagController = TextEditingController();
  
  String? _selectedMateria = 'Matemáticas';
  final List<String> _materias = ['Matemáticas', 'Sistemas', 'Física', 'Química', 'Programación'];
  final List<String> _tags = [];
  
  String? _fileName;
  bool _isUploading = false;

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

  void _selectFile() {
    // Simulating file picking
    setState(() {
      _fileName = 'Apuntes_Clase_Oficial.pdf';
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _fileName == null) {
      if (_fileName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona un archivo PDF o documento'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    setState(() => _isUploading = true);

    // Simulating upload progress
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Documento subido con éxito! Pendiente de aprobación.'),
            backgroundColor: Color(0xFF7CB342),
          ),
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF7CB342);

    return Scaffold(
      // backgroundColor: Colors.white,
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // File Picker Section
              GestureDetector(
                onTap: _selectFile,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    // color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primaryGreen.withOpacity(0.4),
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _fileName != null ? Icons.picture_as_pdf : Icons.cloud_upload_outlined,
                        size: 48,
                        color: primaryGreen,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _fileName ?? 'Toca para seleccionar tu archivo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _fileName != null ? Colors.black87 : Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_fileName == null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Soporta PDF, DOCX, TXT hasta 20MB',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Document Name Input
              const Text(
                'Nombre del documento',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Ej. Apuntes Análisis Matemático I - Límites',
                  // fillColor: const Color(0xFFF5F5F5),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Por favor ingresa un nombre para el documento' : null,
              ),
              const SizedBox(height: 24),
              // Subject Selection (Materia)
              const Text(
                'Materia / Categoría',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  // color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMateria,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: _materias.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedMateria = newValue;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Tags Input Section
              const Text(
                'Añadir tags',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        hintText: 'Ej. derivadas, finales, apuntes',
                        // fillColor: const Color(0xFFF5F5F5),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: _addTag,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Tags Visual Chips
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
                      // backgroundColor: const Color(0xFFF1F8E9),
                      deleteIcon: const Icon(Icons.close, size: 14, color: primaryGreen),
                      onDeleted: () => _removeTag(tag),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide.none,
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 48),
              // Submit Button
              _isUploading
                  ? const Center(child: CircularProgressIndicator(color: primaryGreen))
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
    );
  }
}
