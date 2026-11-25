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

  /// `activeOnly=false` es lo que distingue la vista de administración de
  /// la del ciudadano: sin eso, los productos desactivados no vuelven.
  Future<List<dynamic>> getAllProducts() async {
    try {
      final res = await _client.raw.get(
        '/store/products',
        queryParameters: {'activeOnly': false},
      );
      return res.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> body) async {
    try {
      final res = await _client.raw.post('/store/products', data: body);
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> updateProduct(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _client.raw.patch('/store/products/$id', data: body);
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> findRedemptionByCode(String code) async {
    try {
      final res = await _client.raw.get(
        '/store/redemptions',
        queryParameters: {'code': code},
      );
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<void> fulfillRedemption(String id) async {
    try {
      await _client.raw.post('/store/redemptions/$id/fulfill');
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
