import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class RemoteDisputesDatasource {
  RemoteDisputesDatasource(this._client);

  final ApiClient _client;

  Future<List<dynamic>> getAll({String? status}) async {
    try {
      final res = await _client.raw.get(
        '/disputes',
        queryParameters: {'status': ?status},
      );
      return res.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> getById(String id) async {
    try {
      final res = await _client.raw.get('/disputes/$id');
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<void> resolve(String id, Map<String, dynamic> body) async {
    try {
      await _client.raw.post('/disputes/$id/resolve', data: body);
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }
}
