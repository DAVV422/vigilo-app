import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class RemoteAnalyticsDatasource {
  RemoteAnalyticsDatasource(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> getCitizenSummary() async {
    try {
      final res = await _client.raw.get('/analytics/citizen-summary');
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> getImpact() async {
    try {
      final res = await _client.raw.get('/analytics/impact');
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }
}
