import 'package:cotorra_app/screens/dashboard_screen.dart';
import 'package:cotorra_app/screens/gestion/gestion_screen.dart';
import 'package:cotorra_app/screens/my_favorities_screen.dart';
import 'package:cotorra_app/screens/profile/configuracion_screen.dart';
import 'package:cotorra_app/screens/search_screen.dart';
import 'package:cotorra_app/screens/perfil_screen.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/search_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SearchProvider>(context, listen: false).searchDocumentos('');
    });
  }

  /////////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF7CB342);

    // watch: el icono de gestión debe desaparecer al logout/cambiar de rol.
    final userRol = context.watch<AuthProvider>().userRol;

    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: _selectedIndex == 0
          ? null
          : AppBar(
              title: Text(
                _selectedIndex == 1
                    ? 'Buscar'
                    : _selectedIndex == 2
                    ? 'Favoritos'
                    : 'Mi Perfil',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              actions: [
                if (_selectedIndex == 3 && GestionScreen.gatedRole(userRol))
                  IconButton(
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    tooltip: 'Gestión',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GestionScreen(),
                        ),
                      );
                    },
                  ),
                if (_selectedIndex == 3)
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Configuración',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ConfiguracionScreen(),
                        ),
                      );
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                  },
                ),
              ],
            ),

      ////////////  BODY  //////////////
      body: _selectedIndex == 0
          ? DashboardScreen()
          : _selectedIndex == 1
          ? SearchScreen()
          : _selectedIndex == 2
          ? MyFavorities()
          : PerfilScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (_selectedIndex == 1) {
              Provider.of<SearchProvider>(
                context,
                listen: false,
              ).clearCascadeFilters();
              Provider.of<SearchProvider>(
                context,
                listen: false,
              ).clearFilters();
            }
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: primaryGreen,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),

          /// BOTONES BARRA NAVEGACION  ///
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              label: 'Favoritos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
