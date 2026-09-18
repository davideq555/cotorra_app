import 'package:cotorra_app/screens/gestion/colaborador_documentos_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests puros del mapeo chip → query param `estado` server-side del listado
/// de documentos del COLABORADOR (GET /admin/documentos).
///
/// No hay harness de widget tests en el proyecto (testing-capabilities):
/// la pantalla construye su propio ApiClient desde el token de sesión y no
/// expone costura de inyección, así que solo se cubre el helper puro
/// `ColaboradorDocumentosScreen.estadoParam`.
///
/// Diferencia deliberada con el listado docente: acá los tres valores están
/// documentados por el pattern de `estado`, así que `todos` se envía (no se
/// omite). `eliminados` existe en el wire pero no se expone en la UI.
void main() {
  group('ColaboradorDocumentosScreen.estadoParam', () {
    test('Pendientes mapea al valor de wire pendientes', () {
      expect(
        ColaboradorDocumentosScreen.estadoParam(
          ColaboradorFiltroDocumentos.pendientes,
        ),
        'pendientes',
      );
    });

    test('Aprobados mapea al valor de wire aprobados', () {
      expect(
        ColaboradorDocumentosScreen.estadoParam(
          ColaboradorFiltroDocumentos.aprobados,
        ),
        'aprobados',
      );
    });

    test('Todos SÍ se envía: el pattern del contrato lo documenta', () {
      expect(
        ColaboradorDocumentosScreen.estadoParam(
          ColaboradorFiltroDocumentos.todos,
        ),
        'todos',
      );
    });
  });
}
