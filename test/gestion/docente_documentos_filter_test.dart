import 'package:cotorra_app/screens/gestion/docente_documentos_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests puros del mapeo chip → query param `estado` server-side.
///
/// No hay harness de widget tests en el proyecto (testing-capabilities):
/// la pantalla construye su propio ApiClient desde el token de sesión y no
/// expone costura de inyección, así que solo se cubre el helper puro
/// `DocenteDocumentosScreen.estadoParam`.
void main() {
  group('DocenteDocumentosScreen.estadoParam', () {
    test('Pendientes mapea al valor de wire pendientes', () {
      expect(
        DocenteDocumentosScreen.estadoParam(DocenteFiltroDocumentos.pendientes),
        'pendientes',
      );
    });

    test('Aprobados mapea al valor de wire aprobados', () {
      expect(
        DocenteDocumentosScreen.estadoParam(DocenteFiltroDocumentos.aprobados),
        'aprobados',
      );
    });

    test('Todos omite el param (null: nunca el literal no documentado)', () {
      expect(
        DocenteDocumentosScreen.estadoParam(DocenteFiltroDocumentos.todos),
        isNull,
      );
    });
  });
}
