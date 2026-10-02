import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../logging/app_logger.dart';

const _log = AppLogger('Push');

/// Se ejecuta en un isolate aparte cuando llega un push con la app en
/// background o terminada. No tiene acceso a Riverpod ni a la UI — solo
/// puede dejar constancia en los logs del dispositivo.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  _log.info('Push recibido en background: ${message.messageId} (${message.data['type']})');
}

/// Envoltorio delgado sobre `FirebaseMessaging`. No conoce Riverpod ni
/// entidades de dominio — eso lo orquesta `AuthNotifier` (registro/baja de
/// token) y `DashboardScreen` (navegación al tocar una notificación).
class PushNotificationService {
  final _messaging = FirebaseMessaging.instance;

  String get platform => defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID';

  /// Pide permiso de notificaciones y devuelve el token FCM actual, o
  /// `null` si el usuario lo negó o el dispositivo no tiene Google Play
  /// Services (emuladores sin servicios, por ejemplo).
  Future<String?> requestPermissionAndGetToken() async {
    try {
      final settings = await _messaging.requestPermission(alert: true, badge: true, sound: true);
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _log.warning('Permiso de notificaciones denegado por el usuario');
        return null;
      }
      return await _messaging.getToken();
    } catch (e) {
      _log.error('No se pudo obtener el token push', e);
      return null;
    }
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Token actual sin volver a pedir permiso (usado al cerrar sesión, donde
  /// el permiso ya se concedió o negó hace rato).
  Future<String?> getCurrentToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      _log.error('No se pudo leer el token push actual', e);
      return null;
    }
  }

  /// Notificación que abrió la app estando en background.
  Stream<RemoteMessage> get onMessageOpenedApp => FirebaseMessaging.onMessageOpenedApp;

  /// Notificación que abrió la app desde terminada (cold start).
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  /// Push recibido con la app en foreground. Por ahora solo se registra en
  /// el log: la bandeja in-app (`GET /notifications`) ya queda disponible
  /// para que el usuario la consulte sin necesidad de un banner local.
  Stream<RemoteMessage> get onForegroundMessage => FirebaseMessaging.onMessage;
}
