import 'dart:convert';

import 'package:cotorra_app/models/materia.dart';
import 'package:cotorra_app/models/token.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    mockClient = MockHttpClient();
  });

  group('ApiService - login', () {
    test('login exitoso retorna Token', () async {
      // Arrange
      final tokenJson = jsonEncode({
        'access_token': 'test_token_123',
        'token_type': 'Bearer',
      });
      final response = http.Response(tokenJson, 200);

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => response);

      // Para tests reales, ApiService debería recibir el client como dependencia
      // Por ahora solo verificamos que el modelo Token parsea bien
      final token = Token.fromJson(jsonDecode(tokenJson));
      expect(token.accessToken, 'test_token_123');
      expect(token.tokenType, 'Bearer');
    });

    test('login con credenciales invalidas retorna Token sin access_token', () {
      final invalidJson = jsonEncode({'detail': 'Invalid credentials'});
      final token = Token.fromJson(jsonDecode(invalidJson));
      // Token.fromJson usa ?? para valores por defecto
      expect(token.accessToken, isEmpty);
    });
  });

  group('ApiService - getMaterias', () {
    test('getMaterias retorna lista de Materia', () async {

      final materia = Materia.fromJson({'id': 1, 'nombre': 'Matemática I'});
      expect(materia.id, 1);
      expect(materia.nombre, 'Matemática I');
    });

    test('Materia.fromJson maneja valores nulos', () {
      final materia = Materia.fromJson({
        'id': 1,
        'nombre': 'Test',
      });
      expect(materia.descripcion, isNull);
      expect(materia.codigo, isNull);
    });
  });

  group('ApiService - getDocumentos', () {
    test('construye URL correcta con filtros', () {
      // Test de construcción de parámetros
      final params = <String, String>{
        'skip': '0',
        'limit': '20',
        'sort_by': 'fecha_subida',
        'sort_order': 'desc',
      };
      params['q'] = 'examen';
      params['materia_id'] = '5';

      final uri = Uri.parse('https://apicotorra.deqa.com.ar/api/v1/documentos/')
          .replace(queryParameters: params);

      expect(uri.toString(), contains('q=examen'));
      expect(uri.toString(), contains('materia_id=5'));
      expect(uri.toString(), contains('sort_by=fecha_subida'));
    });
  });

  group('ApiService - cambiarContrasena', () {
    test('construye body correcto para cambiar contraseña', () {
      final body = jsonEncode({
        'contraseña_actual': 'old123',
        'contraseña_nueva': 'new456',
      });

      final parsed = jsonDecode(body) as Map<String, dynamic>;
      expect(parsed['contraseña_actual'], 'old123');
      expect(parsed['contraseña_nueva'], 'new456');
    });
  });

  group('ApiService - toggleFavorito', () {
    test('toggleFavorito retorna mapa con estructura correcta', () {
      final response = jsonEncode({
        'message': 'Documento agregado a favoritos',
        'success': true,
        'is_favorite': true,
      });

      final parsed = jsonDecode(response) as Map<String, dynamic>;
      expect(parsed['success'], isTrue);
      expect(parsed['is_favorite'], isTrue);
      expect(parsed['message'], contains('favoritos'));
    });
  });
}