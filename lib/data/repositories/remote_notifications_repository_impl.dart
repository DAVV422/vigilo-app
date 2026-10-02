import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/remote/remote_notifications_datasource.dart';

class RemoteNotificationsRepositoryImpl implements NotificationsRepository {
  RemoteNotificationsRepositoryImpl(this._datasource);

  final RemoteNotificationsDatasource _datasource;

  AppNotification _fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: (json['data'] as Map<String, dynamic>?) ?? const {},
      isRead: json['readAt'] != null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  Future<void> registerPushToken({required String token, required String platform}) {
    return _datasource.registerPushToken(token: token, platform: platform);
  }

  @override
  Future<void> removePushToken(String token) {
    return _datasource.removePushToken(token);
  }

  @override
  Future<List<AppNotification>> getNotifications({bool? unreadOnly}) async {
    final raw = await _datasource.getNotifications(unreadOnly: unreadOnly);
    return raw.map((j) => _fromJson(j as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> markAsRead(String id) {
    return _datasource.markAsRead(id);
  }

  @override
  Future<void> markAllAsRead() {
    return _datasource.markAllAsRead();
  }
}
