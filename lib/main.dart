import 'package:cotorra_app/themes/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/document_cache_provider.dart';
import 'providers/favorites_cache_provider.dart';
import 'providers/search_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_cache_provider.dart';
import 'providers/user_documents_cache_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  // Carga el tema persistido ANTES del primer frame para evitar flasheos.
  final themeProvider = ThemeProvider();
  await themeProvider.load();
  runApp(CotorraApp(themeProvider: themeProvider));
}

class CotorraApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const CotorraApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
        ChangeNotifierProxyProvider<AuthProvider, SearchProvider>(
          create: (ctx) => SearchProvider(ctx.read<AuthProvider>()),
          // update: (ctx, auth, previous) => SearchProvider(auth),
          update: (ctx, auth, previous) => previous ?? SearchProvider(auth),
        ),
        ChangeNotifierProvider(create: (_) => DocumentCacheProvider()),
        ChangeNotifierProvider(create: (_) => UserCacheProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesCacheProvider()),
        ChangeNotifierProvider(create: (_) => UserDocumentsCacheProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'CotorraApp',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: context.watch<ThemeProvider>().themeMode,
            home: auth.isAuthenticated
                ? const MainScreen()
                : const AuthScreen(),
          );
        },
      ),
    );
  }
}
