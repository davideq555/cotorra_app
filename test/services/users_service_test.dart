import 'dart:convert';

import 'package:cotorra_app/models/usuario_stats.dart';
import 'package:cotorra_app/services/api/users_service.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

/// Arma una respuesta JSON con el status pedido.
http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

const _statsFull = {
  'usuario_id': 7,
  'total_documentos': 12,
  'total_descargas': 340,
  'total_favoritos': 8,
  'valoracion_promedio': 4.5,
  'total_upvotes_comentarios': 21,
  'karma': 57,
};

void main() {
  late MockHttpClient mockHttp;
  late ApiClient client;
  late UsersService service;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() {
    mockHttp = MockHttpClient();
    client = ApiClient(baseUrl: 'http://test-api/api/v1', httpClient: mockHttp);
    client.setToken('test-jwt');
    service = UsersService(client);
  });

  /// Uri de la última invocación GET registrada en el mock.
  Uri lastGetUri() {
    final captured = verify(
      () => mockHttp.get(captureAny(), headers: any(named: 'headers')),
    ).captured;
    return captured.last as Uri;
  }

  group('UsersService.getUsuarioStats', () {
    test('pide GET /usuarios/{id}/stats y mapea UsuarioStats', () async {
      when(
        () => mockHttp.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _json(_statsFull));

      final stats = await service.getUsuarioStats(7);

      final uri = lastGetUri();
      expect(uri.path, '/api/v1/usuarios/7/stats');
      expect(uri.queryParameters, isEmpty);

      expect(stats.usuarioId, 7);
      expect(stats.totalDocumentos, 12);
      expect(stats.totalDescargas, 340);
      expect(stats.totalFavoritos, 8);
      expect(stats.valoracionPromedio, 4.5);
      expect(stats.totalUpvotesComentarios, 21);
      expect(stats.karma, 57);
    });

    test('respuesta no 2xx lanza ApiException con statusCode', () async {
      when(
        () => mockHttp.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _json({'detail': 'Not Found'}, 404));

      await expectLater(
        service.getUsuarioStats(7),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });
  });

  group('UsuarioStats (DTO)', () {
    test('fromJson mapea todas las columnas del contrato', () {
      final stats = UsuarioStats.fromJson(_statsFull);

      expect(stats.usuarioId, 7);
      expect(stats.totalDocumentos, 12);
      expect(stats.totalDescargas, 340);
      expect(stats.totalFavoritos, 8);
      expect(stats.valoracionPromedio, 4.5);
      expect(stats.totalUpvotesComentarios, 21);
      expect(stats.karma, 57);
    });

    test('fromJson aplica defaults del schema cuando faltan claves', () {
      final stats = UsuarioStats.fromJson({'usuario_id': 3});

      expect(stats.usuarioId, 3);
      expect(stats.totalDocumentos, 0);
      expect(stats.totalDescargas, 0);
      expect(stats.totalFavoritos, 0);
      expect(stats.valoracionPromedio, 0.0);
      expect(stats.totalUpvotesComentarios, 0);
      expect(stats.karma, 0);
    });

    test('fromJson con payload vacío usa defaults en todo', () {
      final stats = UsuarioStats.fromJson({});

      expect(stats.usuarioId, 0);
      expect(stats.totalDocumentos, 0);
      expect(stats.valoracionPromedio, 0.0);
      expect(stats.karma, 0);
    });

    test('fromJson castea valoracion_promedio entera a double', () {
      final stats = UsuarioStats.fromJson({
        'usuario_id': 1,
        'valoracion_promedio': 5,
      });

      expect(stats.valoracionPromedio, 5.0);
      expect(stats.valoracionPromedio, isA<double>());
    });

    test('toJson round-trée con fromJson', () {
      final stats = UsuarioStats.fromJson(_statsFull);

      expect(UsuarioStats.fromJson(stats.toJson()).karma, 57);
      expect(stats.toJson()['total_favoritos'], 8);
      expect(stats.toJson()['valoracion_promedio'], 4.5);
    });
  });
}
