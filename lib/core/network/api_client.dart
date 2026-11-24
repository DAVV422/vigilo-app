import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../logging/app_logger.dart';
import '../storage/secure_session_storage.dart';
import 'api_exception.dart';

const _log = AppLogger('HTTP');

/// Rutas que nunca deben disparar el flujo de refresh (evita bucles: un 401
/// en el propio login/registro/refresh no significa "sesión vencida").
const _authRoutesExemptFromRefresh = ['/auth/login', '/auth/register', '/auth/refresh'];

/// Cliente HTTP único hacia el backend de Vigilo. Adjunta el access token a
/// cada petición y, ante un 401, intenta renovar la sesión una sola vez con
/// el refresh token antes de reintentar la petición original.
///
/// Si la renovación también falla, limpia la sesión guardada y notifica vía
/// [onSessionExpired] para que la capa de presentación pueda llevar al
/// usuario de vuelta al login — el cliente HTTP no conoce de Riverpod ni de
/// navegación, solo expone este callback.
class ApiClient {
  ApiClient({required SecureSessionStorage sessionStorage, this.onSessionExpired})
    : _sessionStorage = sessionStorage,
      _dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: AppConfig.connectTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
          contentType: 'application/json',
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onResponse: _onResponse, onError: _onError),
    );
  }

  final SecureSessionStorage _sessionStorage;
  final Dio _dio;
  final Future<void> Function()? onSessionExpired;

  Future<String>? _refreshing;

  Dio get raw => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _sessionStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    _log.info('-> ${options.method} ${options.path}');
    handler.next(options);
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    _log.info(
      '<- ${response.requestOptions.method} ${response.requestOptions.path} ${response.statusCode}',
    );
    handler.next(response);
  }

  Future<void> _onError(DioException error, ErrorInterceptorHandler handler) async {
    final isUnauthorized = error.response?.statusCode == 401;
    final path = error.requestOptions.path;
    final isExempt = _authRoutesExemptFromRefresh.any(path.endsWith);

    final requestId = _requestIdOf(error.response);
    _log.warning(
      '<- ${error.requestOptions.method} $path '
      '${error.response?.statusCode ?? '(sin respuesta)'}'
      '${requestId != null ? ' [req $requestId]' : ''}: ${error.message}',
    );

    if (!isUnauthorized || isExempt) {
      handler.next(error);
      return;
    }

    try {
      final newAccessToken = await _refreshSession();
      final retryOptions = error.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final response = await _dio.fetch(retryOptions);
      handler.resolve(response);
    } catch (_) {
      _log.error('Refresh de sesión fallido tras un 401 en $path; cerrando sesión local');
      await _sessionStorage.clear();
      await onSessionExpired?.call();
      handler.reject(
        DioException(
          requestOptions: error.requestOptions,
          error: SessionExpiredException(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  /// Coalesce: si ya hay un refresh en vuelo (varias llamadas 401 casi
  /// simultáneas), todas esperan al mismo Future en vez de disparar
  /// múltiples refresh contra el backend.
  Future<String> _refreshSession() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<String> _doRefresh() async {
    final refreshToken = await _sessionStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw SessionExpiredException();
    }

    final plainDio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
    final response = await plainDio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );

    final data = response.data['data'] ?? response.data;
    final newAccessToken = data['accessToken'] as String;
    final newRefreshToken = data['refreshToken'] as String? ?? refreshToken;

    await _sessionStorage.saveSession(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    );

    return newAccessToken;
  }

  /// Identificador que el backend devuelve en `X-Request-Id`, para poder
  /// cruzar el error del cliente con la línea exacta del log del servidor.
  static String? _requestIdOf(Response<dynamic>? response) {
    final value = response?.headers.value('x-request-id');
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Traduce un [DioException] a [ApiException], extrayendo el mensaje del
  /// envoltorio de error de NestJS (`message` puede ser string o un arreglo
  /// de errores de `class-validator`).
  ApiException toApiException(DioException error) {
    if (error.error is SessionExpiredException) {
      return error.error as SessionExpiredException;
    }

    final statusCode = error.response?.statusCode ?? 0;
    final body = error.response?.data;
    final requestId = _requestIdOf(error.response);
    String message = error.message ?? 'Error de conexión con el servidor';

    if (body is Map) {
      final rawMessage = body['message'];
      if (rawMessage is String) {
        message = rawMessage;
      } else if (rawMessage is List && rawMessage.isNotEmpty) {
        message = rawMessage.join('. ');
      }
    }

    return ApiException(
      statusCode: statusCode,
      message: message,
      cause: error,
      requestId: requestId,
    );
  }
}
