import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class RemoteMaterialsDatasource {
  RemoteMaterialsDatasource(this._client);

  final ApiClient _client;

  Future<List<dynamic>> getAll({bool includeInactive = false}) async {
    try {
      final res = await _client.raw.get(
        '/materials',
        queryParameters: {if (includeInactive) 'includeInactive': 'true'},
      );
      return res.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> getById(String id) async {
    try {
      final res = await _client.raw.get('/materials/$id');
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> body) async {
    try {
      final res = await _client.raw.patch('/materials/$id', data: body);
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<void> createPrice(String id, Map<String, dynamic> body) async {
    try {
      await _client.raw.post('/materials/$id/prices', data: body);
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }
}
