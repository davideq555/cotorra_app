import 'package:cotorra_app/screens/gestion/gestion_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests puros de gating de la gestión por rol (spec: gestion-hub).
///
/// No hay harness de widget tests en el proyecto (testing-capabilities),
/// así que solo se cubre el helper puro `GestionScreen.gatedRole`.
/// El mapper `docsFromAdminPage` corresponde a PR #2 (T4.1, SearchProvider)
/// y se prueba allí — no se introduce en este PR.
void main() {
  group('GestionScreen.gatedRole', () {
    test('DOCENTE y COLABORADOR habilitan la gestión', () {
      expect(GestionScreen.gatedRole('DOCENTE'), isTrue);
      expect(GestionScreen.gatedRole('COLABORADOR'), isTrue);
    });

    test('ALUMNO, ADMIN y roles desconocidos quedan fuera', () {
      expect(GestionScreen.gatedRole('ALUMNO'), isFalse);
      expect(GestionScreen.gatedRole('ADMIN'), isFalse);
      expect(GestionScreen.gatedRole('ROBOT'), isFalse);
      expect(GestionScreen.gatedRole(null), isFalse);
      expect(GestionScreen.gatedRole(''), isFalse);
    });

    test('tolera mayúsculas/minúsculas y espacios sobrantes', () {
      expect(GestionScreen.gatedRole('docente'), isTrue);
      expect(GestionScreen.gatedRole(' Colaborador '), isTrue);
      expect(GestionScreen.gatedRole(' admin '), isFalse);
    });
  });
}
