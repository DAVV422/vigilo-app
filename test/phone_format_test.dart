import 'package:flutter_test/flutter_test.dart';
import 'package:vigilo/core/format/phone.dart';

void main() {
  group('normalizePhone', () {
    // El caso que motiva la función: así se escribe un número en Bolivia,
    // y la expresión del servidor lo rechaza.
    test('quita los espacios de un número boliviano', () {
      expect(normalizePhone('+591 70011223'), '+59170011223');
      expect(normalizePhone('+591 3 3445566'), '+59133445566');
    });

    test('quita guiones y paréntesis', () {
      expect(normalizePhone('+591-700-11223'), '+59170011223');
      expect(normalizePhone('(591) 70011223'), '59170011223');
    });

    test('conserva el + solo si estaba al principio', () {
      expect(normalizePhone('+59170011223'), '+59170011223');
      expect(normalizePhone('59170011223'), '59170011223');
      // Un + en el medio no es un prefijo internacional.
      expect(normalizePhone('591+70011223'), '59170011223');
    });

    test('tolera espacios alrededor', () {
      expect(normalizePhone('  70011223  '), '70011223');
    });

    test('una cadena vacía sigue vacía', () {
      expect(normalizePhone(''), '');
      expect(normalizePhone('   '), '');
    });

    test('no inventa un número a partir de puro texto', () {
      expect(normalizePhone('no tengo'), '');
    });
  });

  group('isValidPhone', () {
    test('acepta lo que acepta el servidor', () {
      expect(isValidPhone('+59170011223'), isTrue);
      expect(isValidPhone('70011223'), isTrue);
      // Siete dígitos es el mínimo.
      expect(isValidPhone('1234567'), isTrue);
      // Quince, el máximo.
      expect(isValidPhone('123456789012345'), isTrue);
    });

    test('rechaza lo que el servidor rechaza', () {
      expect(isValidPhone('123456'), isFalse, reason: 'seis dígitos');
      expect(isValidPhone('1234567890123456'), isFalse, reason: 'dieciséis');
      expect(isValidPhone('+591 70011223'), isFalse, reason: 'con espacio');
      expect(isValidPhone(''), isFalse);
    });

    test('normalizar vuelve válido lo que no lo era', () {
      const comoLoEscribeLaGente = '+591 700 11223';
      expect(isValidPhone(comoLoEscribeLaGente), isFalse);
      expect(isValidPhone(normalizePhone(comoLoEscribeLaGente)), isTrue);
    });
  });
}
