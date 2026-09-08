import 'dart:convert';

import 'package:cotorra_app/services/api/documents_service.dart';
import 'package:cotorra_app/services/api_client.dart';
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

  group('DocumentsService - getDocumentosTotal', () {
    test('retorna meta.total de la respuesta paginada', () async {
      // Arrange
      final response = http.Response(
        jsonEncode({
          'items': [
            {'id': 1, 'titulo': 'Doc mínimo'},
          ],
          'meta': {'total': 1247, 'skip': 0, 'limit': 1, 'has_more': true},
        }),
        200,
      );

      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => response);

      final service = DocumentsService(
        ApiClient(
          baseUrl: 'https://test.example/api/v1',
          httpClient: mockClient,
        ),
      );

      // Act
      final total = await service.getDocumentosTotal();

      // Assert
      expect(total, 1247);

      // Verifica la URI construida: /documentos/ con skip=0 y limit=1
      final capturedUris = verify(
        () => mockClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured;

      final uri = capturedUris.last as Uri;
      expect(uri.path, endsWith('/documentos/'));
      expect(uri.queryParameters['skip'], '0');
      expect(uri.queryParameters['limit'], '1');
    });

    test('respuesta sin meta retorna 0', () async {
      // Arrange
      final response = http.Response(jsonEncode({'items': []}), 200);

      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => response);

      final service = DocumentsService(
        ApiClient(
          baseUrl: 'https://test.example/api/v1',
          httpClient: mockClient,
        ),
      );

      // Act
      final total = await service.getDocumentosTotal();

      // Assert
      expect(total, 0);
    });

    test('respuesta con array plano retorna 0', () async {
      // Arrange
      final response = http.Response(jsonEncode([]), 200);

      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => response);

      final service = DocumentsService(
        ApiClient(
          baseUrl: 'https://test.example/api/v1',
          httpClient: mockClient,
        ),
      );

      // Act
      final total = await service.getDocumentosTotal();

      // Assert
      expect(total, 0);
    });
  });
}
