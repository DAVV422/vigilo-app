import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class RemoteRatingsDatasource {
  RemoteRatingsDatasource(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    try {
      final res = await _client.raw.post('/ratings', data: body);
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      // `toApiException` no es decorativo: traduce el cuerpo de error de
      // NestJS (donde `message` puede ser string o arreglo de
      // class-validator) y adjunta el X-Request-Id, que es lo que permite
      // cruzar un fallo del cliente con la línea exacta del log del servidor.
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> getByUser(String userId) async {
    try {
      final res = await _client.raw.get('/ratings/user/$userId');
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<List<dynamic>> getMine() async {
    try {
      final res = await _client.raw.get('/ratings/mine');
      return res.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }
}
