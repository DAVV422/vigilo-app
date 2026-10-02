import 'dart:developer' as developer;

/// Logger liviano con nombre por módulo, sobre `dart:developer.log` (visible
/// en `flutter logs`/DevTools sin sumar una dependencia nueva). El objetivo
/// es dejar constancia de los pasos fundamentales de cada flujo (red, auth,
/// push) para poder ubicar en los logs correctos qué request u operación
/// causó un error, sin exponer contraseñas ni tokens completos.
class AppLogger {
  const AppLogger(this._name);

  final String _name;

  static const _levelInfo = 800;
  static const _levelWarning = 900;
  static const _levelError = 1000;

  void info(String message) => developer.log(message, name: _name, level: _levelInfo);

  void warning(String message) => developer.log(message, name: _name, level: _levelWarning);

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(message, name: _name, level: _levelError, error: error, stackTrace: stackTrace);
  }

  /// Oculta valores sensibles (contraseñas, tokens) antes de volcar un mapa
  /// a los logs. No es un deep-clone eficiente, pero los payloads de la app
  /// son siempre pequeños (formularios), así que no es un problema.
  static Map<String, dynamic> redact(Map<String, dynamic> data, {Set<String> keys = const {'password', 'accessToken', 'refreshToken', 'token'}}) {
    return data.map((key, value) {
      if (keys.contains(key)) return MapEntry(key, '***');
      return MapEntry(key, value);
    });
  }
}
