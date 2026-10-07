import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../demo/demo_state.dart';

/// Sin backend ni FCM en modo demo: no hay token que registrar. La bandeja
/// in-app sigue funcionando contra las notificaciones semilla de [DemoState].
class DemoNotificationsRepositoryImpl implements NotificationsRepository {
  DemoNotificationsRepositoryImpl(this._state);

  final DemoState _state;

  @override
  Future<void> registerPushToken({required String token, required String platform}) async {}

  @override
  Future<void> removePushToken(String token) async {}

  @override
  Future<List<AppNotification>> getNotifications({bool? unreadOnly}) async {
    if (unreadOnly == true) {
      return _state.notifications.where((n) => !n.isRead).toList();
    }
    return _state.notifications;
  }

  @override
  Future<void> markAsRead(String id) async {
    final index = _state.notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    final n = _state.notifications[index];
    _state.notifications[index] = AppNotification(
      id: n.id,
      type: n.type,
      title: n.title,
      body: n.body,
      data: n.data,
      isRead: true,
      createdAt: n.createdAt,
    );
  }

  @override
  Future<void> markAllAsRead() async {
    for (var i = 0; i < _state.notifications.length; i++) {
      final n = _state.notifications[i];
      _state.notifications[i] = AppNotification(
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body,
        data: n.data,
        isRead: true,
        createdAt: n.createdAt,
      );
    }
  }
}
