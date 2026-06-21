import 'package:cotorra_app/models/materia.dart';
import 'package:cotorra_app/services/api_service.dart';
import 'package:flutter/material.dart';

/// Dropdown reutilizable para seleccionar una Materia.
/// Debe recibir un `carreraId` para filtrar las materias disponibles.
///
/// Uso:
/// ```dart
/// MateriaDropdown(
///   enabled: selectedCarrera != null,
///   onChanged: (materia) { ... },
/// )
/// ```
class MateriaDropdown extends StatefulWidget {
  final Materia? value;
  final ValueChanged<Materia?> onChanged;
  final bool enabled;
  final String label;
  final String? hint;

  const MateriaDropdown({
    super.key,
    this.value,
    required this.onChanged,
    this.enabled = true,
    this.label = 'Materia',
    this.hint,
  });

  @override
  State<MateriaDropdown> createState() => MateriaDropdownState();
}

class MateriaDropdownState extends State<MateriaDropdown> {
  final ApiService _apiService = ApiService();
  List<Materia> _materias = [];
  bool _isLoading = false;

  Future<void> _loadMaterias(int carreraId) async {
    setState(() => _isLoading = true);
    try {
      _materias = await _apiService.getMateriasPorCarrera(carreraId);
    } catch (_) {
      _materias = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void resetAndLoad(int carreraId) {
    setState(() {
      _materias = [];
    });
    _loadMaterias(carreraId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final hintText = _materias.isEmpty && widget.enabled
        ? 'Seleccioná una carrera primero'
        : (widget.hint ?? 'Seleccionar ${widget.label}');

    return DropdownButtonFormField<int>(
      value: widget.value?.id,
      decoration: InputDecoration(
        filled: true,
        fillColor: widget.enabled && _materias.isNotEmpty
            ? Colors.white
            : Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      hint: Text(
        hintText,
        style: TextStyle(
          color: widget.enabled && _materias.isNotEmpty
              ? Colors.grey.shade600
              : Colors.grey.shade400,
        ),
      ),
      isExpanded: true,
      items: _materias.map((materia) {
        return DropdownMenuItem<int>(
          value: materia.id,
          child: Text(materia.nombre, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: widget.enabled && _materias.isNotEmpty
          ? (int? id) {
              if (id == null) {
                widget.onChanged(null);
              } else {
                final materia = _materias.firstWhere((m) => m.id == id);
                widget.onChanged(materia);
              }
            }
          : null,
    );
  }
}
