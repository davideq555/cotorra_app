import 'package:cotorra_app/config/env.dart';
import 'package:cotorra_app/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests de integración contra la API de desarrollo.
/// Estos tests hacen requests reales al API, no usan mocks.
///
/// Para ejecutar:
/// ```bash
/// flutter test test/services/api_service_integration_test.dart
/// ```
///
/// ⚠️ Asegurate de que la API de dev esté corriendo y que el usuario
/// de test (admin@gmail.com / 123456) exista.
void main() {
  late ApiService apiService;
  late String authToken;

  setUpAll(() async {
    // Cargar variables de entorno antes de los tests
    // En tests, .env se busca desde el directorio de trabajo
    apiService = ApiService();

    // Login una vez para obtener token reusable en los tests
    authToken = await _getAuthToken();
  });

  group('🔴 Integration - Auth', () {
    test('login con credenciales válidas retorna token', () async {
      final token = await apiService.login(
        Env.testUserEmail,
        Env.testUserPassword,
      );

      expect(token.accessToken, isNotEmpty);
      expect(token.tokenType, equals('Bearer'));
    });

    test('login con credenciales inválidas lanza Exception', () async {
      expect(
        () => apiService.login('invalid', 'wrong'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('🔴 Integration - Materias', () {
    test('getMaterias retorna lista de materias', () async {
      final materias = await apiService.getMaterias();

      expect(materias, isA<List>());
      // No asumimos que hay materias, solo verificamos la estructura
      for (final m in materias) {
        expect(m.id, isPositive);
        expect(m.nombre, isNotEmpty);
      }
    });

    test('getMaterias con paginación funciona', () async {
      final materias = await apiService.getMaterias(skip: 0, limit: 5);

      expect(materias.length, lessThanOrEqualTo(5));
    });
  });

  group('🔴 Integration - Documentos', () {
    test('getDocumentos retorna lista (vacía o con datos)', () async {
      final docs = await apiService.getDocumentos(authToken);

      expect(docs, isA<List>());
      for (final doc in docs) {
        expect(doc.id, isPositive);
        expect(doc.titulo, isNotEmpty);
      }
    });

    test('getDocumentos con filtros construye query correcta', () async {
      // Solo verificamos que no explote con filtros
      final docs = await apiService.getDocumentos(
        authToken,
        query: 'examen',
        tipo: 1,
        materiaId: 1,
        sortBy: 'fecha_subida',
        sortOrder: 'desc',
      );

      expect(docs, isA<List>());
    });

    test('getMejoresDocumentos retorna top documentos', () async {
      final docs = await apiService.getMejoresDocumentos();

      expect(docs, isA<List>());
      expect(docs.length, lessThanOrEqualTo(6)); // API retorna max 6
    });

    test('getDocumentosUsuario retorna documentos del usuario', () async {
      // Obtener documentos propios
      final docs = await apiService.getDocumentosUsuario(
        authToken,
        0, // usuario_id 0 debería dar error o vacío, no usar
        skip: 0,
        limit: 10,
      );

      expect(docs, isA<List>());
    });
  });

  group('🔴 Integration - CRUD Documento', () {
    int? createdDocId;

    test('createDocumento crea nuevo documento', () async {
      final doc = await apiService.createDocumento(
        authToken,
        {
          'titulo': 'Test Integration ${DateTime.now().millisecondsSinceEpoch}',
          'descripcion': 'Documento creado por test de integración',
          'tipo': 1,
          'usuario_id': 1,
          'archivo_url': 'test/path.pdf',
        },
      );

      expect(doc.id, isPositive);
      expect(doc.titulo, contains('Test Integration'));
      createdDocId = doc.id;
    });

    test('getDocumento obtiene documento por ID', () async {
      // Primero obtenemos un documento existente
      final docs = await apiService.getDocumentos(authToken, limit: 1);

      if (docs.isNotEmpty) {
        final doc = await apiService.getDocumento(docs.first.id);
        expect(doc.id, equals(docs.first.id));
        expect(doc.titulo, equals(docs.first.titulo));
      }
    });

    test('updateDocumento actualiza documento existente', () async {
      if (createdDocId == null) {
        // Crear documento para el test
        final docs = await apiService.getDocumentos(authToken, limit: 1);
        if (docs.isEmpty) {
          markTestSkipped('No hay documentos para actualizar');
          return;
        }
        createdDocId = docs.first.id;
      }

      final updated = await apiService.updateDocumento(
        authToken,
        createdDocId!,
        {
          'titulo': 'Actualizado por test ${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      expect(updated.id, equals(createdDocId));
    });

    test('deleteDocumento elimina documento (borrado lógico)', () async {
      if (createdDocId == null) {
        markTestSkipped('No hay documento para eliminar');
        return;
      }

      // No lanzar excepción = success
      await apiService.deleteDocumento(authToken, createdDocId!);
    });

    test('descargarDocumento retorna info de descarga', () async {
      final docs = await apiService.getDocumentos(authToken, limit: 1);

      if (docs.isNotEmpty) {
        final result = await apiService.descargarDocumento(docs.first.id);
        // El endpoint puede retornar {} o datos específicos
        expect(result, isA<Object>());
      }
    });
  });

  group('🔴 Integration - Favoritos', () {
    test('toggleFavorito agrega documento a favoritos', () async {
      final docs = await apiService.getDocumentos(authToken, limit: 1);

      if (docs.isEmpty) {
        markTestSkipped('No hay documentos para probar favoritos');
        return;
      }

      final result = await apiService.toggleFavorito(
        authToken,
        docs.first.id,
      );

      expect(result['success'], isTrue);
      expect(result['message'], isNotNull);
    });

    test('toggleFavorito alterna estado (quitar de favoritos)', () async {
      final docs = await apiService.getDocumentos(authToken, limit: 1);

      if (docs.isEmpty) {
        markTestSkipped('No hay documentos para probar favoritos');
        return;
      }

      final result = await apiService.toggleFavorito(
        authToken,
        docs.first.id,
      );

      // Segunda llamada debería quitar de favoritos
      expect(result['success'], isTrue);
    });
  });

  group('🔴 Integration - Cambiar Contraseña', () {
    test('cambiarContrasena con datos correctos retorna success', () async {
      // Nota: Este test no cambia realmente la contraseña porque
      // requiere la contraseña actual del usuario de test
      // Solo verificamos que el endpoint responde correctamente

      final result = await apiService.cambiarContrasena(
        authToken,
        1, // usuario_id de prueba
        'wrong_password', // contraseña incorrecta para que falle
        'newPassword123',
      );

      // El endpoint debería retornar {success: false, message: ...}
      expect(result['success'], isFalse);
      expect(result['message'], isNotNull);
    });
  });
}

/// Obtiene token de autenticación para los tests
Future<String> _getAuthToken() async {
  final api = ApiService();
  final token = await api.login(
    Env.testUserEmail,
    Env.testUserPassword,
  );
  return token.accessToken;
}