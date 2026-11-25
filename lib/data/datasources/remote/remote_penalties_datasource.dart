import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class RemotePenaltiesDatasource {
  RemotePenaltiesDatasource(this._client);

  final ApiClient _client;

  Future<List<dynamic>> getRules() async {
    try {
      final res = await _client.raw.get('/admin/penalty-rules');
      return res.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> updateRule(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _client.raw.patch('/admin/penalty-rules/$id', data: body);
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<List<dynamic>> getPenalties({
    String? userId,
    String? status,
    String? type,
  }) async {
    try {
      final res = await _client.raw.get(
        '/admin/penalties',
        queryParameters: {
          'userId': ?userId,
          'status': ?status,
          'type': ?type,
        },
      );
      return res.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<List<dynamic>> searchUsers(String query) async {
    try {
      final res = await _client.raw.get(
        '/admin/users',
        queryParameters: {'q': query},
      );
      return res.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> apply(Map<String, dynamic> body) async {
    try {
      final res = await _client.raw.post('/admin/penalties/apply', data: body);
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> lift(String id, String reason) async {
    try {
      final res = await _client.raw.patch(
        '/admin/penalties/$id/lift',
        data: {'reason': reason},
      );
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }
}
