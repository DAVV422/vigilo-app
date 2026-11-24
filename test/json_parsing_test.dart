import 'package:flutter_test/flutter_test.dart';
import 'package:vigilo/core/network/json_parsing.dart';

void main() {
  group('tolera el tipo que manda el backend', () {
    test('acepta números', () {
      expect(toDouble(4.5), 4.5);
      expect(toInt(7), 7);
      expect(toDoubleOrNull(1), 1.0);
      expect(toIntOrNull(2), 2);
    });

    // Las columnas NUMERIC de Postgres llegan como texto por el driver pg.
    test('acepta números serializados como texto', () {
      expect(toDouble('4.50'), 4.5);
      expect(toInt('7'), 7);
      expect(toDoubleOrNull('5.00'), 5.0);
      expect(toIntOrNull('  12  '), 12);
    });
  });

  group('no inventa valores', () {
    test('los opcionales degradan a null', () {
      expect(toDoubleOrNull(null), isNull);
      expect(toIntOrNull(null), isNull);
      expect(toDoubleOrNull('no es un numero'), isNull);
      expect(toIntOrNull(<String, dynamic>{}), isNull);
    });

    test('los obligatorios lanzan nombrando el campo', () {
      expect(
        () => toDouble(null, field: 'totalWeightKg'),
        throwsA(isA<JsonFieldFormatException>().having(
          (e) => e.toString(), 'mensaje', contains('totalWeightKg'))),
      );
      expect(
        () => toInt('abc', field: 'pointsAwarded'),
        throwsA(isA<JsonFieldFormatException>().having(
          (e) => e.toString(), 'mensaje', contains('pointsAwarded'))),
      );
    });
  });
}
