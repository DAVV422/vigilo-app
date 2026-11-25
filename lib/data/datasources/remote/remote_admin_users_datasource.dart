import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class RemoteAdminUsersDatasource {
  RemoteAdminUsersDatasource(this._client);

  final ApiClient _client;

  Future<List<dynamic>> search(String query) async {
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
}
