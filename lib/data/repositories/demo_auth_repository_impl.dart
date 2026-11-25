import '../../core/logging/app_logger.dart';
import '../../core/network/api_exception.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local_json_datasource.dart';
import '../demo/demo_state.dart';
import '../models/company_model.dart';
import '../models/incident_model.dart';
import '../models/user_model.dart';

const _log = AppLogger('DemoAuth');

/// Sesión 100% local para el modo demo: autentica contra los usuarios
/// semilla de [LocalJsonDatasource] (ana@gmail.com/12345678, etc. — ver
/// `_seedData()`) o contra cuentas registradas en esta misma sesión. No hay
/// tokens ni refresh: [DemoState.currentUser] es la sesión completa.
class DemoAuthRepositoryImpl implements AuthRepository {
  DemoAuthRepositoryImpl(this._datasource, this._state);

  final LocalJsonDatasource _datasource;
  final DemoState _state;

  @override
  Future<User> login({required String email, required String password}) async {
    final data = await _datasource.readData();
    final users = (data['users'] as List<dynamic>).map((u) => UserModel.fromJson(u)).toList();
    final matches = users.where((u) => u.email == email && u.password == password);

    if (matches.isEmpty) {
      _log.warning('Login demo fallido para "$email"');
      throw ApiException(
        statusCode: 401,
        message: 'Correo o contraseña incorrectos. Prueba con ana@gmail.com / 12345678, o regístrate.',
      );
    }

    _state.currentUser = matches.first;
    _log.info('Login demo exitoso: $email');
    return matches.first;
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
    final data = await _datasource.readData();
    final usersJson = data['users'] as List<dynamic>;
    final incidentsJson = data['incidents'] as List<dynamic>;
    final companiesJson = data['companies'] as List<dynamic>;

    final users = usersJson.map((u) => UserModel.fromJson(u)).toList();
    final incidents = incidentsJson.map((i) => IncidentModel.fromJson(i)).toList();
    final companies = companiesJson.map((c) => CompanyModel.fromJson(c as Map<String, dynamic>)).toList();

    if (users.any((u) => u.email == email)) {
      throw ApiException(statusCode: 409, message: 'Ya existe una cuenta registrada con ese correo.');
    }

    final newUser = UserModel(
      id: _state.newId('demo-user'),
      name: firstName,
      lastName: lastName,
      username: username,
      email: email,
      password: password,
      phone: phone ?? '',
      points: 0,
      roles: const [UserRole.normal],
    );
    users.add(newUser);
    await _datasource.writeData(users, incidents, companies);

    _state.currentUser = newUser;
    _log.info('Registro demo exitoso: $email');
    return newUser;
  }

  @override
  Future<User?> restoreSession() async => _state.currentUser;

  @override
  Future<void> logout({String? pushToken}) async {
    _log.info('Logout demo: ${_state.currentUser?.email}');
    _state.currentUser = null;
  }

  @override
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
  }) async {
    final actual = _state.currentUser;
    if (actual == null) {
      throw ApiException(statusCode: 401, message: 'No hay sesión activa.');
    }
    // Se muta el usuario del estado demo, que es lo que devuelve
    // `restoreSession`: si no, el perfil seguiría mostrando lo viejo.
    final actualizado = actual.copyWith(
      name: firstName,
      lastName: lastName,
      phone: phone,
      avatarUrl: avatarUrl,
    );
    _state.currentUser = actualizado;
    return actualizado;
  }

  @override
  Future<RoleRequestResult> requestRole({
    required String role,
    String? companyId,
    String? idDocumentType,
    String? idDocumentNumber,
  }) async {
    final user = _state.currentUser;
    if (user == null) {
      throw ApiException(statusCode: 401, message: 'No hay sesión activa.');
    }

    if (role != 'RECYCLER_INDIVIDUAL') {
      // Los roles operativos/corporativos requieren aprobación de un admin
      // en el backend real; simularlo no aporta nada a una demo rápida.
      return RoleRequestResult(
        role: role,
        status: 'PENDING',
        message: 'Este rol requiere aprobación y no está disponible en el modo demo.',
      );
    }

    if (!user.roles.contains(UserRole.recycling)) {
      final updated = user.copyWith(roles: [...user.roles, UserRole.recycling]);
      _state.currentUser = updated;
      await _persistRoleChange(updated);
      _log.info('Rol de recolector activado para ${updated.email}');
    }

    return RoleRequestResult(
      role: role,
      status: 'ACTIVE',
      message: 'Rol de recolector individual activado.',
    );
  }

  Future<void> _persistRoleChange(User user) async {
    final data = await _datasource.readData();
    final usersJson = data['users'] as List<dynamic>;
    final incidentsJson = data['incidents'] as List<dynamic>;
    final companiesJson = data['companies'] as List<dynamic>;

    final users = usersJson.map((u) => UserModel.fromJson(u)).toList();
    final incidents = incidentsJson.map((i) => IncidentModel.fromJson(i)).toList();
    final companies = companiesJson.map((c) => CompanyModel.fromJson(c as Map<String, dynamic>)).toList();

    final index = users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      users[index] = UserModel.fromEntity(user);
      await _datasource.writeData(users, incidents, companies);
    }
  }
}
