import 'package:cotorra_app/models/facultad.dart';
import 'package:cotorra_app/services/api_service.dart';
import 'package:flutter/material.dart';

/// Dropdown reutilizable para seleccionar una Facultad.
/// Carga las facultades desde la API automáticamente.
///
/// Uso:
/// ```dart
/// FacultadDropdown(
///   value: selectedFacultad,
///   onChanged: (facultad) { ... },
/// )
/// ```
class FacultadDropdown extends StatefulWidget {
  /// Facultad actualmente seleccionada (null = ninguna).
  final Facultad? value;

  /// Callback ejecutado cuando se selecciona una facultad.
  final ValueChanged<Facultad?> onChanged;

  /// Si es false, deshabilita el dropdown. Default: true.
  final bool enabled;

  /// Label del campo. Default: 'Facultad'.
  final String label;

  /// Hint cuando no hay selección. Default: 'Seleccionar Facultad'.
  final String? hint;

  const FacultadDropdown({
    super.key,
    this.value,
    required this.onChanged,
    this.enabled = true,
    this.label = 'Facultad',
    this.hint,
  });

  @override
  State<FacultadDropdown> createState() => _FacultadDropdownState();
}

class _FacultadDropdownState extends State<FacultadDropdown> {
  final ApiService _apiService = ApiService();
  List<Facultad> _facultades = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFacultades();
  }

  Future<void> _loadFacultades() async {
    if (_facultades.isNotEmpty) return;

    setState(() => _isLoading = true);
    try {
      _facultades = await _apiService.getFacultades();
    } catch (_) {
      _facultades = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: widget.value?.id,
      decoration: InputDecoration(
        filled: true,
        // fillColor: widget.enabled ? Colors.white : Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      hint: Text(widget.hint ?? 'Seleccionar ${widget.label}'),
      isExpanded: true,
      items: _facultades.map((facultad) {
        return DropdownMenuItem<int>(
          value: facultad.id,
          child: Text(facultad.nombre, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: widget.enabled
          ? (int? id) {
              if (id == null) {
                widget.onChanged(null);
              } else {
                final facultad = _facultades.firstWhere((f) => f.id == id);
                widget.onChanged(facultad);
              }
            }
          : null,
    );
  }
}
