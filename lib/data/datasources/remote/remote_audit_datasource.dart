import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class RemoteAuditDatasource {
  RemoteAuditDatasource(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> query(Map<String, dynamic> params) async {
    try {
      final res = await _client.raw.get(
        '/admin/audit-logs',
        queryParameters: params,
      );
      // Se devuelve la respuesta entera: la paginación viene en `meta`,
      // fuera de `data`.
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }
}
