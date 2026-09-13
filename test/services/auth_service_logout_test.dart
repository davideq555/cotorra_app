import 'package:cotorra_app/services/api/auth_service.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;
  late ApiClient client;
  late AuthService authService;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    client = ApiClient(
      baseUrl: 'https://test.example/api/v1',
      httpClient: mockClient,
    );
    authService = AuthService(client);
  });

  /// Stub de POST que siempre responde 200.
  void stubPost200() {
    when(
      () => mockClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => http.Response('{}', 200));
  }

  group('AuthService.logout — header X-Refresh-Token', () {
    test('envía X-Refresh-Token cuando refreshToken tiene valor', () async {
      stubPost200();

      await authService.logout(refreshToken: 'rt-abc');

      final captured = verify(
        () => mockClient.post(
          captureAny(),
          headers: captureAny(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).captured;

      // captured = [uri, headers] en orden de captura.
      expect(captured[0], Uri.parse('https://test.example/api/v1/auth/logout'));
      final headers = captured[1] as Map<String, String>;
      expect(headers['X-Refresh-Token'], 'rt-abc');
      // Los headers base siguen presentes.
      expect(headers['Content-Type'], 'application/json');
    });

    test('NO envía el header cuando refreshToken es null', () async {
      stubPost200();

      await authService.logout();

      final captured = verify(
        () => mockClient.post(
          any(),
          headers: captureAny(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).captured;
      final headers = captured.single as Map<String, String>;
      expect(headers.containsKey('X-Refresh-Token'), isFalse);
    });

    test('NO envía el header cuando refreshToken es string vacío', () async {
      stubPost200();

      await authService.logout(refreshToken: '');

      final captured = verify(
        () => mockClient.post(
          any(),
          headers: captureAny(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).captured;
      final headers = captured.single as Map<String, String>;
      expect(headers.containsKey('X-Refresh-Token'), isFalse);
    });
  });

  group('AuthService.logoutAll — header X-Refresh-Token', () {
    test('envía X-Refresh-Token al path /auth/logout-all', () async {
      stubPost200();

      await authService.logoutAll(refreshToken: 'rt-all');

      final captured = verify(
        () => mockClient.post(
          captureAny(),
          headers: captureAny(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).captured;

      expect(
        captured[0],
        Uri.parse('https://test.example/api/v1/auth/logout-all'),
      );
      final headers = captured[1] as Map<String, String>;
      expect(headers['X-Refresh-Token'], 'rt-all');
    });

    test('NO envía el header cuando refreshToken es null', () async {
      stubPost200();

      await authService.logoutAll();

      final captured = verify(
        () => mockClient.post(
          any(),
          headers: captureAny(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).captured;
      final headers = captured.single as Map<String, String>;
      expect(headers.containsKey('X-Refresh-Token'), isFalse);
    });
  });
}
