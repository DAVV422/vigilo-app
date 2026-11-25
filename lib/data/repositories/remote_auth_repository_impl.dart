import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/storage/secure_session_storage.dart';
import '../datasources/remote/remote_auth_datasource.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/json_parsing.dart';

class RemoteAuthRepositoryImpl implements AuthRepository {
  RemoteAuthRepositoryImpl(this._datasource, this._sessionStorage);

  final RemoteAuthDatasource _datasource;
  final SecureSessionStorage _sessionStorage;

  static const _roleFromBackend = {
    'CITIZEN': UserRole.normal,
    'RECYCLER_INDIVIDUAL': UserRole.recycling,
    'SECURITY_GUARD': UserRole.security,
    'TRASH_COLLECTOR': UserRole.cleaning,
    'COMPANY_SUPERVISOR': UserRole.companySupervisor,
    'COMPANY_MANAGER': UserRole.companyManager,
    'ADMIN': UserRole.admin,
    'MODERATOR': UserRole.moderator,
  };

  List<UserRole> _mapRoles(List<dynamic> rawRoles) {
    // El login/register devuelven roles como lista plana de strings
    // (['CITIZEN']); /users/me devuelve objetos {role, status, ...} y solo
    // nos interesan los que ya están ACTIVE.
    return rawRoles
        .map((r) {
          if (r is String) return _roleFromBackend[r];
          if (r is Map<String, dynamic>) {
            if (r['status'] != null && r['status'] != 'ACTIVE') return null;
            return _roleFromBackend[r['role']];
          }
          return null;
        })
        .whereType<UserRole>()
        .toList();
  }

  User _userFromAuthResponse(Map<String, dynamic> json) {
    final data = json['user'] as Map<String, dynamic>;
    return User(
      id: data['id'] as String,
      name: data['firstName'] as String,
      lastName: data['lastName'] as String? ?? '',
      username: data['username'] as String? ?? '',
      email: data['email'] as String,
      points: toIntOrNull(data['pointsBalance']) ?? 0,
      trustScore: toDoubleOrNull(data['trustScore']) ?? 5.0,
      // El perfil mostraba "todavía no tienes calificaciones" a gente que sí
      // tenía, hasta que cerraba y reabría la app: recién ahí la sesión se
      // restauraba contra /users/me, que sí traía el dato. Faltaba en las
      // dos puntas — el backend tampoco lo mandaba.
      ratingsCount: toIntOrNull(data['ratingsCount']) ?? 0,
      roles: _mapRoles((data['roles'] as List<dynamic>?) ?? const []),
    );
  }

  User _userFromProfile(Map<String, dynamic> data) {
    return User(
      id: data['id'] as String,
      name: data['firstName'] as String,
      lastName: data['lastName'] as String? ?? '',
      username: data['username'] as String? ?? '',
      email: data['email'] as String,
      phone: data['phone'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      points: toIntOrNull(data['pointsBalance']) ?? 0,
      trustScore: toDoubleOrNull(data['trustScore']) ?? 5.0,
      ratingsCount: toIntOrNull(data['ratingsCount']) ?? 0,
      roles: _mapRoles((data['roles'] as List<dynamic>?) ?? const []),
    );
  }

  Future<void> _persistTokens(Map<String, dynamic> json) async {
    await _sessionStorage.saveSession(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
    String? phone,
  }) async {
    final json = await _datasource.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      username: username,
      phone: phone,
    );
    await _persistTokens(json);
    return _userFromAuthResponse(json);
  }

  @override
  Future<User> login({required String email, required String password}) async {
    final json = await _datasource.login(email: email, password: password);
    await _persistTokens(json);
    return _userFromAuthResponse(json);
  }

  @override
  Future<User?> restoreSession() async {
    if (!await _sessionStorage.hasSession()) return null;
    try {
      final profile = await _datasource.getMe();
      return _userFromProfile(profile);
    } on ApiException catch (e) {
      // Los tokens se borran **solo** si el servidor dijo que no valen.
      //
      // Antes se borraban ante cualquier error, y un fallo de red no es
      // una sesión inválida: abrir la app una vez sin señal dejaba a la
      // persona afuera para siempre, porque tampoco podía volver a iniciar
      // sesión sin conexión. Guardar los tokens existe justamente para
      // evitar eso.
      if (e.isUnauthorized || e.isForbidden) {
        await _sessionStorage.clear();
      }
      return null;
    } catch (_) {
      // Algo inesperado al parsear la respuesta: no es motivo para tirar
      // la sesión.
      return null;
    }
  }

  @override
  Future<void> logout({String? pushToken}) async {
    final refreshToken = await _sessionStorage.getRefreshToken();
    try {
      await _datasource.logout(refreshToken: refreshToken, pushToken: pushToken);
    } finally {
      await _sessionStorage.clear();
    }
  }

  @override
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
  }) async {
    // `PATCH /users/me` devuelve el perfil completo, con la misma forma que
    // `GET`, así que no hace falta una segunda vuelta para releerlo.
    final data = await _datasource.updateProfile({
      'firstName': ?firstName,
      'lastName': ?lastName,
      'phone': ?phone,
      'avatarUrl': ?avatarUrl,
    });
    return _userFromProfile(data);
  }

  @override
  Future<RoleRequestResult> requestRole({
    required String role,
    String? companyId,
    String? idDocumentType,
    String? idDocumentNumber,
  }) async {
    final json = await _datasource.requestRole(
      role: role,
      companyId: companyId,
      idDocumentType: idDocumentType,
      idDocumentNumber: idDocumentNumber,
    );
    return RoleRequestResult(
      role: json['role'] as String,
      status: json['status'] as String,
      message: json['message'] as String? ?? '',
    );
  }
}
