import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Reemplaza el almacenamiento en texto plano de credenciales en
/// `shared_preferences` por el keychain/keystore nativo del dispositivo.
/// Solo guarda los tokens de sesión (JWT) — nunca la contraseña del usuario.
class SecureSessionStorage {
  SecureSessionStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'vigilo_access_token';
  static const _refreshTokenKey = 'vigilo_refresh_token';

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> updateAccessToken(String accessToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
  }

  Future<bool> hasSession() async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
