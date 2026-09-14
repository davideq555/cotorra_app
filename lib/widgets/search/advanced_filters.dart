import 'package:cotorra_app/providers/auth_provider.dart';
import 'package:cotorra_app/providers/search_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdvancedFilters extends StatelessWidget {
  final Function(String?) onSearch;

  const AdvancedFilters({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Theme.of(context).colorScheme.primary;
    final searchProvider = context.watch<SearchProvider>();
    final authProvider = context.watch<AuthProvider>();
    final availableYears = searchProvider.getAvailableYears();

    final isMateriaEnabled =
        searchProvider.selectedCarrera != null &&
        !searchProvider.carreraMateriasLoading;
    final userCarreras = authProvider.userCarreras;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: searchProvider.filtersExpanded
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtrar por Carrera',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      // color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),

                  if (userCarreras.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'No tienes carreras asociadas',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      initialValue: searchProvider.selectedCarrera?.id,
                      decoration: InputDecoration(
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      hint: const Text('Todas las carreras'),
                      isExpanded: true,
                      isDense: true,
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Todas las carreras'),
                        ),
                        ...userCarreras.map((carrera) {
                          return DropdownMenuItem<int>(
                            value: carrera.id,
                            child: Text(carrera.nombre),
                          );
                        }),
                      ],
                      onChanged: (int? carreraId) {
                        if (carreraId == null) {
                          searchProvider.setSelectedCarrera(null);
                        } else {
                          final carrera = userCarreras.firstWhere(
                            (c) => c.id == carreraId,
                          );
                          searchProvider.setSelectedCarrera(carrera);
                        }
                      },
                    ),
                  const SizedBox(height: 8),

                  searchProvider.carreraMateriasLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : DropdownButtonFormField<int>(
                          initialValue: searchProvider.selectedMateria?.id,
                          decoration: InputDecoration(
                            filled: true,
                            // fillColor: isMateriaEnabled ? Colors.white : Colors.grey.shade200,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              // borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          hint: Text(
                            'Seleccionar Materia',
                            style: TextStyle(
                              // color: isMateriaEnabled ? Colors.grey.shade600 : Colors.grey.shade400,
                            ),
                          ),
                          isExpanded: true,
                          isDense: true,
                          items: searchProvider.selectedMateria != null
                              ? [
                                  const DropdownMenuItem<int>(
                                    value: null,
                                    child: Text('Todas las materias'),
                                  ),
                                  ...searchProvider.carreraMaterias.map((
                                    materia,
                                  ) {
                                    return DropdownMenuItem<int>(
                                      value: materia.id,
                                      child: Text(materia.nombre),
                                    );
                                  }),
                                ]
                              : searchProvider.carreraMaterias.map((materia) {
                                  return DropdownMenuItem<int>(
                                    value: materia.id,
                                    child: Text(materia.nombre),
                                  );
                                }).toList(),
                          onChanged: isMateriaEnabled
                              ? (int? materiaId) {
                                  if (materiaId == null) {
                                    searchProvider.setSelectedMateria(null);
                                  } else {
                                    final materia = searchProvider
                                        .carreraMaterias
                                        .firstWhere((m) => m.id == materiaId);
                                    searchProvider.setSelectedMateria(materia);
                                  }
                                }
                              : null,
                        ),
                  const SizedBox(height: 12),

                  const Divider(),
                  const SizedBox(height: 6),

                  Text(
                    'Año Académico',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      // color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: searchProvider.selectedYear,
                    decoration: InputDecoration(
                      filled: true,
                      // fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        // borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    hint: const Text('Todos los años'),
                    isExpanded: true,
                    isDense: true,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Todos los años'),
                      ),
                      ...availableYears.map((year) {
                        return DropdownMenuItem<String>(
                          value: year,
                          child: Text(year),
                        );
                      }),
                    ],
                    onChanged: (String? year) {
                      searchProvider.setSelectedYear(year);
                    },
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            searchProvider.clearCascadeFilters();
                          },
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Limpiar'),
                          style: OutlinedButton.styleFrom(
                            // foregroundColor: Colors.grey.shade700,
                            // side: BorderSide(color: Colors.grey.shade400),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => onSearch(null),
                          icon: const Icon(Icons.search, size: 16),
                          label: const Text('Buscar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
