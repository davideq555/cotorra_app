import 'dart:convert';

import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/providers/user_documents_cache_provider.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:cotorra_app/utils/cache_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpClient extends Mock implements http.Client {}

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

/// Fixture mínimo de documento como lo devuelve GET /documentos/usuario/{id}.
Map<String, dynamic> _docJson(int id, String titulo) => {
  'id': id,
  'titulo': titulo,
  'archivo_url': 'files/$id.pdf',
  'tipo': 1,
  'usuario_id': 42,
};

Documento _doc(int id, String titulo) =>
    Documento.fromJson(_docJson(id, titulo));

/// Stub de GET con respuestas consecutivas (la última se repite).
void stubUserDocsGet(MockHttpClient mock, List<List<Map<String, dynamic>>> pages) {
  var call = 0;
  when(
    () => mock.get(any(), headers: any(named: 'headers')),
  ).thenAnswer((_) async {
    final page = pages[call < pages.length ? call : pages.length - 1];
    call++;
    return _json(page);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHttpClient mockHttp;
  late ApiClient client;
  late UserDocumentsCacheProvider provider;

  const cacheKey = 'cache_user_documents';
  const ttl = Duration(minutes: 15);
  const token = 'test-jwt';
  const userId = 42;

  Future<List<Documento>?> readCache() => CacheUtils.getList<Documento>(
    key: cacheKey,
    fromJson: Documento.fromJson,
    ttl: ttl,
  );

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://test-api'));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockHttp = MockHttpClient();
    client = ApiClient(
      baseUrl: 'http://test-api/api/v1',
      httpClient: mockHttp,
    );
    provider = UserDocumentsCacheProvider(client: client);
  });

  group('applyUpdate', () {
    test('reemplaza en memoria y re-persiste la caché sin refrescar', () async {
      stubUserDocsGet(mockHttp, [
        [_docJson(1, 'Título viejo'), _docJson(2, 'Otro doc')],
      ]);
      await provider.load(token, userId);
      expect(provider.documentos.map((d) => d.id), [1, 2]);

      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.applyUpdate(
        _doc(1, 'Título editado'),
        token: token,
        userId: userId,
      );

      // Estado en memoria reemplazado en el lugar correcto.
      expect(provider.documentos.map((d) => d.id), [1, 2]);
      expect(provider.documentos[0].titulo, 'Título editado');
      // La caché persistida refleja la edición (leer dentro del TTL
      // devuelve el valor nuevo, no el viejo).
      final cached = await readCache();
      expect(cached, isNotNull);
      expect(
        cached!.firstWhere((d) => d.id == 1).titulo,
        'Título editado',
      );
      // Mutación local: no debe disparar un GET extra.
      verify(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .called(1);
      expect(notifications, greaterThan(0));
    });

    test('id desconocido invalida la caché y refresca del servidor', () async {
      stubUserDocsGet(mockHttp, [
        [_docJson(1, 'Uno')],
        [_docJson(7, 'Servidor gana')],
      ]);
      await provider.load(token, userId);

      await provider.applyUpdate(
        _doc(999, 'No existe localmente'),
        token: token,
        userId: userId,
      );

      // El refresh del servidor manda: el doc desconocido NO se inserta.
      expect(provider.documentos.map((d) => d.id), [7]);
      final cached = await readCache();
      expect(cached!.map((d) => d.id), [7]);
      // Uno de load() y otro del refresh por id desconocido.
      verify(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .called(2);
    });
  });

  group('applyDelete', () {
    test('elimina de memoria y re-persiste la caché sin refrescar', () async {
      stubUserDocsGet(mockHttp, [
        [_docJson(1, 'Uno'), _docJson(2, 'Dos')],
      ]);
      await provider.load(token, userId);

      await provider.applyDelete(1, token: token, userId: userId);

      expect(provider.documentos.map((d) => d.id), [2]);
      final cached = await readCache();
      expect(cached!.map((d) => d.id), [2]);
      verify(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .called(1);
    });

    test('id desconocido invalida la caché y refresca del servidor', () async {
      stubUserDocsGet(mockHttp, [
        [_docJson(1, 'Uno')],
        [_docJson(8, 'Recuperado')],
      ]);
      await provider.load(token, userId);

      await provider.applyDelete(999, token: token, userId: userId);

      expect(provider.documentos.map((d) => d.id), [8]);
      final cached = await readCache();
      expect(cached!.map((d) => d.id), [8]);
      verify(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .called(2);
    });

    test('un id eliminado no resucita en lecturas dentro del TTL', () async {
      // 1er GET: servidor tiene [1, 2]. Tras el DELETE, el servidor ya no
      // devuelve el 1: toda lectura posterior (caché o proveedor nuevo)
      // debe mantenerlo ausente.
      stubUserDocsGet(mockHttp, [
        [_docJson(1, 'Uno'), _docJson(2, 'Dos')],
        [_docJson(2, 'Dos')],
      ]);
      await provider.load(token, userId);
      await provider.applyDelete(1, token: token, userId: userId);

      // Lectura directa de caché dentro del TTL.
      expect((await readCache())!.map((d) => d.id), [2]);
      // Segunda lectura: sigue ausente (la re-persistencia actualizó el
      // timestamp, no quedó la entrada vieja).
      expect((await readCache())!.map((d) => d.id), [2]);
      // Proveedor nuevo leyendo la caché compartida (reapertura de Perfil).
      final reopened = UserDocumentsCacheProvider(client: client);
      await reopened.load(token, userId);
      expect(reopened.documentos.map((d) => d.id), [2]);
      expect(
        reopened.documentos.any((d) => d.id == 1),
        isFalse,
        reason: 'el id eliminado no debe resucitar dentro del TTL',
      );
    });

    test('lista vacía tras eliminar todo: getList retorna null (comportamiento documentado)', () async {
      stubUserDocsGet(mockHttp, [
        [_docJson(1, 'Único')],
      ]);
      await provider.load(token, userId);

      await provider.applyDelete(1, token: token, userId: userId);

      expect(provider.documentos, isEmpty);
      // CacheUtils.getList trata lista vacía como "sin caché" → null,
      // lo que fuerza a load() a ir al servidor en la próxima apertura
      // (carry-forward note #1 del design).
      expect(await readCache(), isNull);
    });
  });
}
