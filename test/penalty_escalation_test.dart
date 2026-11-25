import 'package:flutter_test/flutter_test.dart';
import 'package:vigilo/domain/entities/penalty.dart';

/// Las tres reglas tal como las siembra el servidor.
PenaltyRule _regla({
  required String code,
  required int base,
  required double mult,
  int suspension = 5,
}) =>
    PenaltyRule(
      id: 'r',
      infractionCode: code,
      description: '',
      basePointsDeducted: base,
      escalationMultiplier: mult,
      evaluationWindowDays: 30,
      warningThresholdOccurrences: 3,
      suspensionThresholdOccurrences: suspension,
      active: true,
    );

void main() {
  // El cálculo real vive en el servidor y no vuelve hasta después de aplicar
  // la sanción. La pantalla lo repite para poder decir cuántos puntos se van
  // a descontar ANTES de confirmar. Si las dos aritméticas se separan, la
  // confirmación miente y nadie se entera.
  group('la escala repite la aritmética del servidor', () {
    test('NO_SHOW_RECYCLER: base 10, multiplicador 2', () {
      final r = _regla(code: 'NO_SHOW_RECYCLER', base: 10, mult: 2.0);
      // Las dos primeras están comprobadas contra el servidor real.
      expect(r.pointsForOccurrence(1), 10);
      expect(r.pointsForOccurrence(2), 20);
      expect(r.pointsForOccurrence(3), 40);
      expect(r.pointsForOccurrence(4), 80);
      expect(r.pointsForOccurrence(5), 160);
    });

    test('FALSE_INCIDENT_REPORT: base 5, multiplicador 1,5 con redondeo', () {
      final r =
          _regla(code: 'FALSE_INCIDENT_REPORT', base: 5, mult: 1.5, suspension: 4);
      expect(r.pointsForOccurrence(1), 5);
      // 7,5 redondea a 8, igual que Math.round en el servidor.
      expect(r.pointsForOccurrence(2), 8);
      // 11,25 → 11
      expect(r.pointsForOccurrence(3), 11);
      // 16,875 → 17
      expect(r.pointsForOccurrence(4), 17);
    });

    test('un multiplicador de 1 no escala', () {
      final r = _regla(code: 'X', base: 7, mult: 1.0);
      expect(r.pointsForOccurrence(1), 7);
      expect(r.pointsForOccurrence(4), 7);
    });

    test('la ocurrencia 0 o negativa se trata como la primera', () {
      final r = _regla(code: 'X', base: 10, mult: 2.0);
      expect(r.pointsForOccurrence(0), 10);
      expect(r.pointsForOccurrence(-3), 10);
    });
  });

  group('cuándo deja de ser una advertencia', () {
    test('suspende a partir del umbral, no antes', () {
      final r = _regla(code: 'NO_SHOW_RECYCLER', base: 10, mult: 2.0);
      expect(r.suspendsAt(4), isFalse);
      expect(r.suspendsAt(5), isTrue);
      expect(r.suspendsAt(6), isTrue);
    });
  });

  group('lo que llega del servidor', () {
    // NUMERIC(4,2) y el servidor NO lo normaliza: llega como "2.00".
    test('el multiplicador se parsea aunque venga como texto', () {
      final r = PenaltyRule.fromJson({
        'id': 'r1',
        'infractionCode': 'NO_SHOW_RECYCLER',
        'description': 'No se presentó',
        'basePointsDeducted': 10,
        'escalationMultiplier': '2.00',
        'evaluationWindowDays': 30,
        'warningThresholdOccurrences': 3,
        'suspensionThresholdOccurrences': 5,
        'active': true,
      });
      expect(r.escalationMultiplier, 2.0);
      expect(r.pointsForOccurrence(2), 20);
    });

    test('también si llega como número', () {
      final r = PenaltyRule.fromJson({
        'id': 'r2',
        'infractionCode': 'X',
        'description': '',
        'basePointsDeducted': 5,
        'escalationMultiplier': 1.5,
        'evaluationWindowDays': 30,
        'warningThresholdOccurrences': 3,
        'suspensionThresholdOccurrences': 4,
        'active': true,
      });
      expect(r.escalationMultiplier, 1.5);
    });

    test('una sanción aplicada se parsea con el nombre de la persona', () {
      final p = Penalty.fromJson({
        'id': 'p1',
        'userId': 'u1',
        'infractionCode': 'NO_SHOW_RECYCLER',
        'type': 'WARNING',
        'status': 'ACTIVE',
        'pointsDeducted': 20,
        'occurrenceNumber': 2,
        'reason': 'No se presentó al recojo del 14/11',
        'startsAt': '2026-11-25T10:00:00.000Z',
        'endsAt': null,
        'user': {'firstName': 'Julio', 'lastName': 'Vargas Cuéllar'},
      });
      expect(p.userName, 'Julio Vargas Cuéllar');
      expect(p.isActive, isTrue);
      expect(p.infractionLabel, 'No se presentó al recojo');
      expect(p.typeLabel, 'Advertencia');
    });

    test('un estado desconocido se muestra en vez de romper', () {
      final p = Penalty.fromJson({
        'id': 'p2',
        'userId': 'u1',
        'infractionCode': 'OTRA_COSA',
        'type': 'ALGO_NUEVO',
        'status': 'ALGO_NUEVO',
        'pointsDeducted': 0,
        'occurrenceNumber': 1,
        'reason': '',
        'startsAt': '2026-11-25T10:00:00.000Z',
      });
      expect(p.statusLabel, 'ALGO_NUEVO');
      expect(p.typeLabel, 'ALGO_NUEVO');
      expect(p.infractionLabel, 'OTRA_COSA');
    });
  });

  group('la búsqueda de usuarios', () {
    test('parsea la reputación aunque venga como texto', () {
      final u = AdminUser.fromJson({
        'id': 'u1',
        'firstName': 'Rosa',
        'lastName': 'Ticona Flores',
        'username': 'rosa.ticona',
        'status': 'ACTIVE',
        'pointsBalance': 256,
        'trustScore': '4.67',
        'ratingsCount': 3,
        'roles': ['CITIZEN', 'RECYCLER_INDIVIDUAL'],
      });
      expect(u.trustScore, 4.67);
      expect(u.fullName, 'Rosa Ticona Flores');
      expect(u.isRecycler, isTrue);
    });

    test('no expone datos de contacto aunque el servidor los mandara', () {
      // El endpoint no los devuelve; esto fija que la entidad tampoco los
      // modela, para que nadie los agregue sin pensarlo.
      final u = AdminUser.fromJson({
        'id': 'u1',
        'firstName': 'Rosa',
        'lastName': 'Ticona',
        'username': 'rosa.ticona',
        'status': 'ACTIVE',
        'pointsBalance': 0,
        'trustScore': 5,
        'ratingsCount': 0,
        'email': 'no.deberia.estar@ejemplo.bo',
        'phone': '+59170000000',
      });
      expect(u.fullName, 'Rosa Ticona');
      expect(
        AdminUser.fromJson({
          'id': 'u2',
          'firstName': 'A',
          'lastName': 'B',
          'username': 'ab',
          'status': 'ACTIVE',
          'pointsBalance': 0,
          'trustScore': 5,
          'ratingsCount': 0,
        }).isRecycler,
        isFalse,
      );
    });
  });
}
