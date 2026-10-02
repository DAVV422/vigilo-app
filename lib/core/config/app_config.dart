/// Configuración de entorno del backend.
///
/// El valor por defecto apunta al emulador de Android (`10.0.2.2` es el alias
/// que usa el emulador para llegar al `localhost` de la máquina host). Para
/// iOS Simulator, dispositivo físico o un servidor remoto, sobreescribe con:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.50:3000/api/v1
/// ```
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
