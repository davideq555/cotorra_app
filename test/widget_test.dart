// Smoke test for CotorraApp
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cotorra_app/main.dart';
import 'package:cotorra_app/providers/auth_provider.dart';
import 'package:cotorra_app/providers/search_provider.dart';
import 'package:cotorra_app/providers/theme_provider.dart';

void main() {
  // AuthProvider -> GoogleAuthService lee Env (dotenv) al construirse;
  // sin cargar .env el pump lanza NotInitializedError.
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
  });

  testWidgets('App launch smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          // ChangeNotifierProvider(create: (_) => SearchProvider()), // error del test anterior solo agregue para quitar el error
          ChangeNotifierProxyProvider<AuthProvider, SearchProvider>(
            create: (ctx) => SearchProvider(ctx.read<AuthProvider>()),
            update: (ctx, auth, previous) => SearchProvider(auth),
          ),
        ],
        child: CotorraApp(themeProvider: ThemeProvider()),
      ),
    );

    // Verify that the login screen title or branding exists
    expect(find.text('Cotorra'), findsOneWidget);
  });
}
