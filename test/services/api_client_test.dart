import 'dart:convert';

import 'package:cotorra_app/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    // El refresh lee 'refresh_token' de prefs; mock inicial para los tests
    // que refrescan.
    SharedPreferences.setMockInitialValues({'refresh_token': 'rt-valid'});
    mockClient = MockHttpClient();
  });

  tearDown(() {
    // Reseteamos los estáticos para no contaminar otros archivos de test.
    ApiClient.sharedTokenRefresher = null;
    ApiClient.sharedOnSessionExpired = null;
  });

  /// Helper: response JSON con status code dado.
  http.Response respuesta(int code, {Map<String, dynamic>? body}) =>
      http.Response(jsonEncode(body ?? {'ok': true}), code);

  /// Helper: mockea GET que responde 401 en el primer pedido y `final`
  /// en el segundo (simula el reintento post-refresh).
  void mockGet401Luego200() {
    var pedidos = 0;
    when(
      () => mockClient.get(any(), headers: any(named: 'headers')),
    ).thenAnswer((_) async {
      pedidos++;
      if (pedidos == 1) {
        return respuesta(401, body: {'detail': 'Token expirado'});
      }
      return respuesta(200, body: {'id': 1, 'nombre': 'ok'});
    });
  }

  group('ApiClient - refresh-on-401 con refresher compartido', () {
    test(
      'refresca vía sharedTokenRefresher y reintenta con el token nuevo',
      () async {
        // Arrange: cliente SIN tokenRefresher de instancia, solo el compartido.
        ApiClient.sharedTokenRefresher = (refreshToken) async {
          return 'new-access-token';
        };
        mockGet401Luego200();

        final client = ApiClient(
          baseUrl: 'https://test.example/api/v1',
          httpClient: mockClient,
        );
        client.setToken('stale-token');

        // Act
        final response = await client.get('/documentos/');

        // Assert: el reintento (2° pedido) sale con el token fresco.
        final headersCapturados = verify(
          () => mockClient.get(any(), headers: captureAny(named: 'headers')),
        ).captured;
        final ultimoHeaders = headersCapturados.last as Map<String, String>;
        expect(ultimoHeaders['Authorization'], 'Bearer new-access-token');

        // El token nuevo queda persistido en prefs.
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('token'), 'new-access-token');

        // La respuesta 200 del reintento parsea sin lanzar.
        final decoded = client.decodeResponse(response);
        expect(decoded, isA<Map<String, dynamic>>());
        expect((decoded as Map<String, dynamic>)['nombre'], 'ok');
      },
    );

    test(
      'refresh fallido invoca el handler compartido y lanza ApiException 401',
      () async {
        // Arrange: el refresher compartido falla (sesión realmente expirada).
        ApiClient.sharedTokenRefresher = (refreshToken) async {
          throw Exception('refresh inválido');
        };
        var sessionExpiredCalls = 0;
        ApiClient.sharedOnSessionExpired = () => sessionExpiredCalls++;

        when(
          () => mockClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => respuesta(401, body: {'detail': 'Token expirado'}),
        );

        final client = ApiClient(
          baseUrl: 'https://test.example/api/v1',
          httpClient: mockClient,
        );
        client.setToken('stale-token');

        // Act
        final response = await client.get('/documentos/');

        // Assert: decodeResponse lanza ApiException con statusCode 401.
        expect(
          () => client.decodeResponse(response),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
          ),
        );

        // El handler compartido fue invocado exactamente 1 vez.
        expect(sessionExpiredCalls, 1);
      },
    );

    test(
      'el tokenRefresher de instancia tiene precedencia sobre el compartido',
      () async {
        // Arrange: instancia Y estático registrados a la vez.
        var instanciaCalls = 0;
        var staticCalls = 0;
        ApiClient.sharedTokenRefresher = (refreshToken) async {
          staticCalls++;
          return 'static-token';
        };
        mockGet401Luego200();

        final client = ApiClient(
          baseUrl: 'https://test.example/api/v1',
          httpClient: mockClient,
        );
        client.setToken('stale-token');
        client.tokenRefresher = (refreshToken) async {
          instanciaCalls++;
          return 'instance-token';
        };

        // Act
        await client.get('/documentos/');

        // Assert: se invocó el de instancia y el estático NO fue llamado.
        expect(instanciaCalls, 1);
        expect(staticCalls, 0);

        // El reintento sale con el token de la instancia, no el del estático.
        final headersCapturados = verify(
          () => mockClient.get(any(), headers: captureAny(named: 'headers')),
        ).captured;
        final ultimoHeaders = headersCapturados.last as Map<String, String>;
        expect(ultimoHeaders['Authorization'], 'Bearer instance-token');
      },
    );

    test('skipRefresh no dispara refresh ni expira la sesión', () async {
      // Arrange: refresher compartido registrado, pero el request pide skip.
      var refresherCalls = 0;
      ApiClient.sharedTokenRefresher = (refreshToken) async {
        refresherCalls++;
        return 'new-access-token';
      };
      var sessionExpiredCalls = 0;
      ApiClient.sharedOnSessionExpired = () => sessionExpiredCalls++;

      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => respuesta(401, body: {'detail': 'Token expirado'}),
      );

      final client = ApiClient(
        baseUrl: 'https://test.example/api/v1',
        httpClient: mockClient,
      );
      client.setToken('stale-token');

      // Act
      final response = await client.post('/algo', skipRefresh: true);

      // Assert: el 401 pasa derecho, sin refresh ni logout.
      expect(response.statusCode, 401);
      expect(refresherCalls, 0);
      expect(sessionExpiredCalls, 0);
    });
  });
}
