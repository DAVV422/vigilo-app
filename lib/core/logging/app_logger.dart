import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Logger liviano con nombre por módulo. El objetivo es dejar constancia de
/// los pasos fundamentales de cada flujo (red, auth, push) para poder ubicar
/// qué petición u operación causó un error, sin exponer contraseñas ni tokens.
///
/// Emite por dos caminos distintos a propósito:
///
/// - En debug/profile usa `dart:developer.log`, que es lo que entienden
///   DevTools y `flutter logs`, con niveles y stack traces estructurados.
/// - En release usa `print`, porque **`developer.log` es inerte en release**:
///   no escribe nada. Eso significaba que la app compilada —justo la que se
///   instala en un teléfono para probar— no dejaba ni una línea en `logcat`,
///   y diagnosticar un fallo real obligaba a adivinar desde los logs del
///   servidor. Con esto, `adb logcat | grep Vigilo` sirve sobre el APK
///   de release.
///
/// El formato de la línea en release es fijo y parseable:
/// `Vigilo/<NIVEL>/<Módulo>: <mensaje>`.
class AppLogger {
  const AppLogger(this._name);

  final String _name;

  static const _levelInfo = 800;
  static const _levelWarning = 900;
  static const _levelError = 1000;

  void info(String message) => _emit('INFO', _levelInfo, message);

  void warning(String message) => _emit('WARN', _levelWarning, message);

  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _emit('ERROR', _levelError, message, error, stackTrace);

  void _emit(
    String label,
    int level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (kReleaseMode) {
      // ignore: avoid_print — es la única salida que llega a logcat en release.
      print('Vigilo/$label/$_name: $message');
      if (error != null) {
        // ignore: avoid_print
        print('Vigilo/$label/$_name: causa: $error');
      }
      if (stackTrace != null) {
        // ignore: avoid_print
        print('Vigilo/$label/$_name: $stackTrace');
      }
      return;
    }

    developer.log(
      message,
      name: _name,
      level: level,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Oculta valores sensibles (contraseñas, tokens) antes de volcar un mapa
  /// a los logs. No es un deep-clone eficiente, pero los payloads de la app
  /// son siempre pequeños (formularios), así que no es un problema.
  static Map<String, dynamic> redact(
    Map<String, dynamic> data, {
    Set<String> keys = const {
      'password',
      'accessToken',
      'refreshToken',
      'token',
    },
  }) {
    return data.map((key, value) {
      if (keys.contains(key)) return MapEntry(key, '***');
      return MapEntry(key, value);
    });
  }
}
