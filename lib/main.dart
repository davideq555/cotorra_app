import 'package:cotorra_app/themes/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/search_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/search_screen.dart';

void main() {
  runApp(const CotorraApp());
}

class CotorraApp extends StatelessWidget {
  const CotorraApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
        ChangeNotifierProxyProvider<AuthProvider, SearchProvider>(
          create: (ctx) => SearchProvider(ctx.read<AuthProvider>()),
          update: (ctx, auth, previous) => SearchProvider(auth),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'CotorraApp',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: auth.isAuthenticated
                ? const SearchScreen()
                : const AuthScreen(),
          );
        },
      ),
    );
  }
}
