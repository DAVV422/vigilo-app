import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class RemoteCompaniesDatasource {
  RemoteCompaniesDatasource(this._client);

  final ApiClient _client;

  Future<List<dynamic>> getAll() async {
    try {
      final res = await _client.raw.get('/companies');
      return res.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> getById(String id) async {
    try {
      final res = await _client.raw.get('/companies/$id');
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    try {
      final res = await _client.raw.post('/companies', data: body);
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> verify(String id, String status) async {
    try {
      final res = await _client.raw.post(
        '/companies/$id/verify',
        data: {'status': status},
      );
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<List<dynamic>> getZones(
    String companyId, {
    bool includeInactive = false,
  }) async {
    try {
      final res = await _client.raw.get(
        '/companies/$companyId/coverage-zones',
        queryParameters: {if (includeInactive) 'includeInactive': 'true'},
      );
      return res.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> createZone(
    String companyId,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _client.raw.post(
        '/companies/$companyId/coverage-zones',
        data: body,
      );
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<void> updateZone(
    String companyId,
    String zoneId,
    Map<String, dynamic> body,
  ) async {
    try {
      await _client.raw.patch(
        '/companies/$companyId/coverage-zones/$zoneId',
        data: body,
      );
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }
}
