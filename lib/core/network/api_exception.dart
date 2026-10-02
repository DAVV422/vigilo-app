/// Error normalizado desde una respuesta HTTP del backend, para que las
/// pantallas no tengan que conocer la forma exacta del envoltorio de error
/// de NestJS (`{statusCode, message, error}`, donde `message` puede ser un
/// string o un arreglo de errores de validación de `class-validator`).
class ApiException implements Exception {
  ApiException({required this.statusCode, required this.message, this.cause});

  final int statusCode;
  final String message;
  final Object? cause;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isConflict => statusCode == 409;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => statusCode == 400;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// La sesión ya no es válida (refresh token vencido o revocado) — la capa de
/// presentación debe interpretarlo como "cerrar sesión y volver al login".
class SessionExpiredException extends ApiException {
  SessionExpiredException() : super(statusCode: 401, message: 'Tu sesión expiró. Vuelve a iniciar sesión.');
}
