import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

/// Llama directamente a los endpoints de `IncidentsModule` del backend.
/// Devuelve los mapas JSON tal como vienen del servidor (el mapeo a
/// [Incident] vive en `RemoteIncidentRepositoryImpl`, para mantener esta
/// clase enfocada solo en construir las peticiones HTTP correctas).
class RemoteIncidentDatasource {
  RemoteIncidentDatasource(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> create({
    required String type,
    required String severity,
    required String title,
    String? description,
    required double latitude,
    required double longitude,
    String? addressText,
    List<String>? mediaUrls,
  }) async {
    try {
      final res = await _client.raw.post(
        '/incidents',
        data: {
          'type': type,
          'severity': severity,
          'title': title,
          if (description != null && description.isNotEmpty) 'description': description,
          'latitude': latitude,
          'longitude': longitude,
          if (addressText != null && addressText.isNotEmpty) 'addressText': addressText,
          if (mediaUrls != null && mediaUrls.isNotEmpty) 'mediaUrls': mediaUrls,
        },
      );
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<List<dynamic>> findNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String? type,
    String? status,
  }) async {
    try {
      final res = await _client.raw.get(
        '/incidents/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radiusKm': radiusKm,
          'type': ?type,
          'status': ?status,
        },
      );
      return res.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> getById(String id) async {
    try {
      final res = await _client.raw.get('/incidents/$id');
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<void> validate({
    required String incidentId,
    required String vote,
    String? comment,
  }) async {
    try {
      await _client.raw.post(
        '/incidents/$incidentId/validate',
        data: {'vote': vote, 'comment': ?comment},
      );
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<void> resolve({
    required String incidentId,
    required String resolutionComment,
    required String resolutionMediaId,
  }) async {
    try {
      await _client.raw.post(
        '/incidents/$incidentId/resolve',
        data: {
          'resolutionComment': resolutionComment,
          'resolutionMediaId': resolutionMediaId,
        },
      );
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }
}
