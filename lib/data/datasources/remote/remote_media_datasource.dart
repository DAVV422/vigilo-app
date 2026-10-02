import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class RemoteMediaDatasource {
  RemoteMediaDatasource(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> upload(String filePath, String folder) async {
    try {
      final formData = FormData.fromMap({
        'folder': folder,
        'file': await MultipartFile.fromFile(filePath),
      });
      final res = await _client.raw.post('/media/upload', data: formData);
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }
}
