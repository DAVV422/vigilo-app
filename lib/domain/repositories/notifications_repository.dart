import '../entities/app_notification.dart';

/// Registro de push tokens (FCM) y bandeja de notificaciones contra
/// `NotificationsModule` del backend.
abstract class NotificationsRepository {
  Future<void> registerPushToken({required String token, required String platform});

  Future<void> removePushToken(String token);

  Future<List<AppNotification>> getNotifications({bool? unreadOnly});

  Future<void> markAsRead(String id);

  Future<void> markAllAsRead();
}
