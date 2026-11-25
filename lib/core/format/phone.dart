/// Expresión que el servidor exige en `UpdateProfileDto` y en el registro.
final _telefonoValido = RegExp(r'^\+?[0-9]{7,15}$');

/// Deja solo dígitos, conservando el `+` inicial si lo había.
///
/// El servidor valida `/^\+?[0-9]{7,15}$/`, así que `+591 70011223` —que es
/// como se escribe un número en Bolivia— **no pasa**. Se normaliza en vez
/// de rechazarlo, porque pedirle a alguien que borre los espacios de su
/// propio número es trabajo del programa.
///
/// Los teléfonos ya sembrados tampoco cumplen la expresión: `+591 3 3445566`
/// entró por TypeORM sin tocar el DTO. No rompe nada mientras nadie los
/// edite, pero explica por qué esto existe.
String normalizePhone(String raw) {
  final limpio = raw.trim();
  final masInicial = limpio.startsWith('+') ? '+' : '';
  return '$masInicial${limpio.replaceAll(RegExp(r'\D'), '')}';
}

/// ¿El número, ya normalizado, pasa la validación del servidor?
bool isValidPhone(String normalized) => _telefonoValido.hasMatch(normalized);
