import 'package:cotorra_app/models/carrera.dart';
import 'package:cotorra_app/services/api_service.dart';
import 'package:flutter/material.dart';

/// Dropdown reutilizable para seleccionar una Carrera.
/// Debe recibir un `facultadId` para filtrar las carreras disponibles.
///
/// Uso:
/// ```dart
/// CarreraDropdown(
///   enabled: selectedFacultad != null,
///   onChanged: (carrera) { ... },
/// )
/// ```
class CarreraDropdown extends StatefulWidget {
  /// La carrera actualmente seleccionada (null = ninguna).
  final Carrera? value;

  /// Callback ejecutado cuando se selecciona una carrera.
  final ValueChanged<Carrera?> onChanged;

  /// Si es false, deshabilita el dropdown. Default: true.
  final bool enabled;

  /// Label del campo. Default: 'Carrera'.
  final String label;

  /// Hint cuando no hay selección. Default: 'Seleccionar Carrera'.
  final String? hint;

  const CarreraDropdown({
    super.key,
    this.value,
    required this.onChanged,
    this.enabled = true,
    this.label = 'Carrera',
    this.hint,
  });

  @override
  State<CarreraDropdown> createState() => CarreraDropdownState();
}

class CarreraDropdownState extends State<CarreraDropdown> {
  final ApiService _apiService = ApiService();
  List<Carrera> _carreras = [];
  bool _isLoading = false;

  Future<void> _loadCarreras(int facultadId) async {
    setState(() => _isLoading = true);
    try {
      _carreras = await _apiService.getCarrerasPorFacultad(facultadId);
    } catch (_) {
      _carreras = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void didUpdateWidget(CarreraDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si se habilita y no tiene carreras cargadas, no hacer nada aquí.
    // El control de carga se delega al padre que debe llamar resetAndLoad.
  }

  /// Fuerza la recarga de carreras para una nueva facultad.
  /// Llamar desde el padre cuando cambia la facultad seleccionada.
  void resetAndLoad(int facultadId) {
    setState(() {
      _carreras = [];
    });
    _loadCarreras(facultadId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // Si no hay carreras y está habilitado, mostrar hint indicando que seleccione facultad primero
    final hintText = _carreras.isEmpty && widget.enabled
        ? 'Seleccioná una facultad primero'
        : (widget.hint ?? 'Seleccionar ${widget.label}');

    return DropdownButtonFormField<int>(
      value: widget.value?.id,
      decoration: InputDecoration(
        filled: true,
        // fillColor: widget.enabled && _carreras.isNotEmpty
        //     ? Colors.white
        //     : Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      hint: Text(
        hintText,
        // style: TextStyle(
        //   color: widget.enabled && _carreras.isNotEmpty
        //       ? Colors.grey.shade600
        //       : Colors.grey.shade400,
        // ),
      ),
      isExpanded: true,
      items: _carreras.map((carrera) {
        return DropdownMenuItem<int>(
          value: carrera.id,
          child: Text(carrera.nombre, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: widget.enabled && _carreras.isNotEmpty
          ? (int? id) {
              if (id == null) {
                widget.onChanged(null);
              } else {
                final carrera = _carreras.firstWhere((c) => c.id == id);
                widget.onChanged(carrera);
              }
            }
          : null,
    );
  }
}
