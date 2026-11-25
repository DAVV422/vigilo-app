import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class RemoteSystemConfigDatasource {
  RemoteSystemConfigDatasource(this._client);

  final ApiClient _client;

  Future<List<dynamic>> getAll() async {
    try {
      final res = await _client.raw.get('/admin/system-configurations');
      return res.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> update(String key, String value) async {
    try {
      final res = await _client.raw.patch(
        '/admin/system-configurations/$key',
        data: {'configValue': value},
      );
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<void> setRecyclerLimit(String userId, int? maxActivePickups) async {
    try {
      await _client.raw.patch(
        '/admin/recyclers/$userId/active-pickups-limit',
        // `null` explícito: es «volver al estándar», no «no mandar nada».
        data: {'maxActivePickups': maxActivePickups},
      );
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }
}
