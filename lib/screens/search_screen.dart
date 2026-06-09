import 'package:cotorra_app/data/services/mockData.dart';
import 'package:cotorra_app/providers/search_provider.dart';
import 'package:cotorra_app/widgets/searchScreenComponent/documentCard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/*
* Funciones a reparar hacer bien la busquedas y reparar los provider a los que llaman,
* utilizar formulario, hacer las conexiones de la api
*/

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<StatefulWidget> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF7CB342);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar documentos...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    // fillColor: const Color(0xFFF5F5F5),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: _performSearch,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Consumer<SearchProvider>(
              builder: (context, searchProvider, child) {
                if (searchProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  );
                }

                final displayDocs = searchProvider.documentos.isNotEmpty
                    ? searchProvider.documentos
                    : mockDocuments();

                return ListView.builder(
                  itemCount: displayDocs.length,
                  itemBuilder: (context, index) {
                    return DocumentCard(doc: displayDocs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _performSearch() {
    // Provider.of<SearchProvider>(
    //   context,
    //   listen: false,
    // ).searchDocumentos(_searchController.text.trim());
    Provider.of<SearchProvider>(context,listen: false)
        .searchDocumentos(_searchController.text);  //la funcion del provider debe devolver una lista y esta vacia
    print("hace una busqueda");
  }

  // @override
  // void initState() {
  //   ingredients = context.read<IngredientProvider>().ingredients;
  //   super.initState();
  // }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // bool _validacionIsIngredient(String nombre) {
  //   return (ingredients.indexWhere(
  //         (ingrediente) => ingrediente.nombre == nombre,
  //       ) !=
  //       -1);
  // }
}
