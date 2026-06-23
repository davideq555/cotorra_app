import 'package:cotorra_app/providers/search_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdvancedFilters extends StatefulWidget {
  const AdvancedFilters({super.key});

  @override
  State<AdvancedFilters> createState() => _AdvancedFiltersState();
}

class _AdvancedFiltersState extends State<AdvancedFilters> {
  @override
  void initState() {
    super.initState();
    // Load facultades when widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadFacultades();
    });
  }

  void _performSearch() {
    final searchProvider = context.read<SearchProvider>();
    searchProvider.searchWithFilters();
    // Close the filters panel after searching
    if (searchProvider.filtersExpanded) {
      searchProvider.toggleFiltersExpanded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Theme.of(context).colorScheme.primary;
    final searchProvider = context.watch<SearchProvider>();
    final availableYears = searchProvider.getAvailableYears();

    // Check if carrera dropdown should be enabled
    final isCarreraEnabled = searchProvider.selectedFacultad != null && !searchProvider.carrerasLoading;
    // Check if materia dropdown should be enabled
    final isMateriaEnabled = searchProvider.selectedCarrera != null && !searchProvider.carreraMateriasLoading;

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
                  // === CASCADE FILTERS: Facultad -> Carrera -> Materia ===
                  Text(
                    'Filtrar por Carrera',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      // color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Facultad dropdown
                  searchProvider.facultadesLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : DropdownButtonFormField<int>(
                          value: searchProvider.selectedFacultad?.id,
                          decoration: InputDecoration(
                            filled: true,
                            // fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),  ////
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          hint: const Text('Seleccionar Facultad'),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('Todas las facultades'),
                            ),
                            ...searchProvider.facultades.map((facultad) {
                              return DropdownMenuItem<int>(
                                value: facultad.id,
                                child: Text(facultad.nombre),
                              );
                            }),
                          ],
                          onChanged: (int? facultadId) {
                            if (facultadId == null) {
                              searchProvider.setSelectedFacultad(null);
                            } else {
                              final facultad = searchProvider.facultades
                                  .firstWhere((f) => f.id == facultadId);
                              searchProvider.setSelectedFacultad(facultad);
                            }
                          },
                        ),
                  const SizedBox(height: 8),

                  // Carrera dropdown (always visible, enabled only when facultad is selected)
                  searchProvider.carrerasLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : DropdownButtonFormField<int>(
                          value: searchProvider.selectedCarrera?.id,
                          decoration: InputDecoration(
                            filled: true,
                            // fillColor: isCarreraEnabled ? Colors.white : Colors.grey.shade200,
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
                            'Seleccionar Carrera',
                            style: TextStyle(
                              // color: isCarreraEnabled ? Colors.grey.shade600 : Colors.grey.shade400,
                            ),
                          ),
                          isExpanded: true,
                          isDense: true,
                          items: searchProvider.selectedCarrera != null
                              ? [
                                  const DropdownMenuItem<int>(
                                    value: null,
                                    child: Text('Todas las carreras'),
                                  ),
                                  ...searchProvider.carreras.map((carrera) {
                                    return DropdownMenuItem<int>(
                                      value: carrera.id,
                                      child: Text(carrera.nombre),
                                    );
                                  }),
                                ]
                              : searchProvider.carreras.map((carrera) {
                                  return DropdownMenuItem<int>(
                                    value: carrera.id,
                                    child: Text(carrera.nombre),
                                  );
                                }).toList(),
                          onChanged: isCarreraEnabled
                              ? (int? carreraId) {
                                  if (carreraId == null) {
                                    searchProvider.setSelectedCarrera(null);
                                  } else {
                                    final carrera = searchProvider.carreras
                                        .firstWhere((c) => c.id == carreraId);
                                    searchProvider.setSelectedCarrera(carrera);
                                  }
                                }
                              : null,
                        ),
                  const SizedBox(height: 8),

                  // Materia dropdown (always visible, enabled only when carrera is selected)
                  searchProvider.carreraMateriasLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : DropdownButtonFormField<int>(
                          value: searchProvider.selectedMateria?.id,
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
                                  ...searchProvider.carreraMaterias.map((materia) {
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
                                    final materia = searchProvider.carreraMaterias
                                        .firstWhere((m) => m.id == materiaId);
                                    searchProvider.setSelectedMateria(materia);
                                  }
                                }
                              : null,
                        ),
                  const SizedBox(height: 12),

                  const Divider(),
                  const SizedBox(height: 6),

                  // === YEAR FILTER ===
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

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            searchProvider.clearCascadeFilters();
                            searchProvider.clearFilters();
                          },
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Limpiar'),
                          style: OutlinedButton.styleFrom(
                            // foregroundColor: Colors.grey.shade700,
                            // side: BorderSide(color: Colors.grey.shade400),
                            side: BorderSide(color: Theme.of(context).colorScheme.primary),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _performSearch,
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
