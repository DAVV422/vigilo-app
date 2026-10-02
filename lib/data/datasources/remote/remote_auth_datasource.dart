import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

/// Llamadas HTTP crudas hacia `AuthModule` y los endpoints de perfil de
/// `UsersModule`. No conoce tokens guardados ni entidades de dominio — eso
/// lo orquesta `RemoteAuthRepositoryImpl`.
class RemoteAuthDatasource {
  RemoteAuthDatasource(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
    String? phone,
  }) async {
    try {
      final res = await _client.raw.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.raw.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<void> logout({String? refreshToken, String? pushToken}) async {
    try {
      await _client.raw.post(
        '/auth/logout',
        data: {
          if (refreshToken != null) 'refreshToken': refreshToken,
          if (pushToken != null) 'pushToken': pushToken,
        },
      );
    } on DioException catch (e) {
      // El logout es best-effort: si el token ya venció o el servidor no
      // responde, igual queremos borrar la sesión local.
      if (e.response?.statusCode != 401) {
        throw _client.toApiException(e);
      }
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final res = await _client.raw.get('/users/me');
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> requestRole({
    required String role,
    String? companyId,
    String? idDocumentType,
    String? idDocumentNumber,
  }) async {
    try {
      final res = await _client.raw.post(
        '/users/me/roles',
        data: {
          'role': role,
          if (companyId != null) 'companyId': companyId,
          if (idDocumentType != null) 'idDocumentType': idDocumentType,
          if (idDocumentNumber != null) 'idDocumentNumber': idDocumentNumber,
        },
      );
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<List<dynamic>> getPointsHistory({int page = 1, int limit = 20}) async {
    try {
      final res = await _client.raw.get(
        '/users/me/points/history',
        queryParameters: {'page': page, 'limit': limit},
      );
      return res.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }
}
