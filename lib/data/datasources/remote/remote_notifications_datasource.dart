import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

/// Llamadas HTTP crudas hacia `NotificationsModule`.
class RemoteNotificationsDatasource {
  RemoteNotificationsDatasource(this._client);

  final ApiClient _client;

  Future<void> registerPushToken({required String token, required String platform}) async {
    try {
      await _client.raw.post(
        '/notifications/push-tokens',
        data: {'token': token, 'platform': platform},
      );
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<void> removePushToken(String token) async {
    try {
      await _client.raw.delete('/notifications/push-tokens/$token');
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<List<dynamic>> getNotifications({bool? unreadOnly}) async {
    try {
      final res = await _client.raw.get(
        '/notifications',
        queryParameters: {'unreadOnly': ?unreadOnly},
      );
      return res.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _client.raw.patch('/notifications/$id/read');
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _client.raw.patch('/notifications/read-all');
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }
}
