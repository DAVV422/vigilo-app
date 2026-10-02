import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class RemoteStoreDatasource {
  RemoteStoreDatasource(this._client);

  final ApiClient _client;

  Future<List<dynamic>> getProducts() async {
    try {
      final res = await _client.raw.get('/store/products');
      return res.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> redeem(String productId) async {
    try {
      final res = await _client.raw.post('/store/products/$productId/redeem');
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<List<dynamic>> getMyRedemptions() async {
    try {
      final res = await _client.raw.get('/store/my-redemptions');
      return res.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }
}
