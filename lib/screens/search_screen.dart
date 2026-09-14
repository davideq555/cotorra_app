import 'package:cotorra_app/providers/search_provider.dart';
import 'package:cotorra_app/widgets/common/document_card.dart';
import 'package:cotorra_app/widgets/search/advanced_filters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final provider = Provider.of<SearchProvider>(context, listen: false);
    if (provider.filtersExpanded) {
      provider.toggleFiltersExpanded();
    }
    provider.searchDocumentos(_searchController.text.trim());
  }

  void _performAdvancedSearch(String? _) {
    final provider = Provider.of<SearchProvider>(context, listen: false);
    provider.toggleFiltersExpanded();
    provider.searchDocumentos(_searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();
    final primaryGreen = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
      child: Column(
        children: [
          // Search bar
          _SearchBar(
            controller: _searchController,
            onSearch: _performSearch,
            primaryColor: primaryGreen,
          ),
          const SizedBox(height: 12),

          // Advanced filters toggle button
          _FiltersToggle(
            isExpanded: searchProvider.filtersExpanded,
            onToggle: () {
              final provider = Provider.of<SearchProvider>(
                context,
                listen: false,
              );
              if (!provider.filtersExpanded) {
                provider.initUserFilters();
              }
              provider.toggleFiltersExpanded();
            },
            primaryColor: primaryGreen,
          ),
          const SizedBox(height: 8),

          // Content: either filters or results
          Expanded(
            child: searchProvider.filtersExpanded
                ? AdvancedFilters(onSearch: _performAdvancedSearch)
                : _buildResultsAndChips(searchProvider, primaryGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsAndChips(
    SearchProvider searchProvider,
    Color primaryColor,
  ) {
    return Column(
      children: [
        // Active filters chips (when filters are active and results exist)
        if ((searchProvider.hasActiveFilters ||
                searchProvider.hasCascadeFilters) &&
            searchProvider.documentos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ActiveFiltersChips(
              searchProvider: searchProvider,
              primaryColor: primaryColor,
            ),
          ),

        // Results
        Expanded(child: _buildResults(searchProvider)),
      ],
    );
  }

  Widget _buildResults(SearchProvider searchProvider) {
    if (searchProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayDocs = searchProvider.documentos;

    if (displayDocs.isEmpty) {
      final hasSearched =
          _searchController.text.isNotEmpty ||
          searchProvider.hasActiveFilters ||
          searchProvider.hasCascadeFilters;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearched ? Icons.search_off : Icons.search,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              hasSearched
                  ? 'Ups, no hay documentos que coincidan con tu búsqueda'
                  : 'No se encontraron documentos',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            if (hasSearched) ...[
              const SizedBox(height: 8),
              Text(
                'Intenta con otros términos o filtros',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: displayDocs.length,
      itemBuilder: (context, index) {
        return DocumentCard(doc: displayDocs[index]);
      },
    );
  }
}

// ==================== SUB-WIDGETS ====================

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final Color primaryColor;

  const _SearchBar({
    required this.controller,
    required this.onSearch,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Buscar documentos...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => onSearch(),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: onSearch,
          ),
        ),
      ],
    );
  }
}

class _FiltersToggle extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final Color primaryColor;

  const _FiltersToggle({
    required this.isExpanded,
    required this.onToggle,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: onToggle,
          icon: Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            size: 20,
          ),
          label: Text(isExpanded ? 'Ocultar filtros' : 'Filtros avanzados'),
          style: TextButton.styleFrom(foregroundColor: primaryColor),
        ),
      ],
    );
  }
}

class _ActiveFiltersChips extends StatelessWidget {
  final SearchProvider searchProvider;
  final Color primaryColor;

  const _ActiveFiltersChips({
    required this.searchProvider,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (searchProvider.selectedCarrera != null)
          _FilterChip(
            label: searchProvider.selectedCarrera!.nombre,
            color: primaryColor,
          ),
        if (searchProvider.selectedMateria != null)
          _FilterChip(
            label: searchProvider.selectedMateria!.nombre,
            color: primaryColor,
          ),
        if (searchProvider.selectedYear != null)
          _FilterChip(label: searchProvider.selectedYear!, color: primaryColor),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;

  const _FilterChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
