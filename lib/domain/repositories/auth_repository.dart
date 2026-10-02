import '../entities/user.dart';

class RoleRequestResult {
  final String role;
  final String status; // 'ACTIVE' | 'PENDING'
  final String message;

  RoleRequestResult({required this.role, required this.status, required this.message});

  bool get isActive => status == 'ACTIVE';
}

/// Sesión del usuario contra el backend real: registro, login, renovación y
/// cierre de sesión. Separado de `UserRepository` (que modela el mock local
/// con un contrato mucho más simple, sin tokens ni KYC) para no forzar esas
/// operaciones dentro de una interfaz que nunca fue pensada para ellas.
abstract class AuthRepository {
  Future<User> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
    String? phone,
  });

  Future<User> login({required String email, required String password});

  /// Intenta restaurar la sesión guardada (refresh token en secure storage)
  /// sin pedir credenciales. Devuelve `null` si no hay sesión o ya no es
  /// válida — la UI debe tratarlo como "ir al login", nunca fabricar un
  /// usuario de relleno como hacía el mock anterior.
  Future<User?> restoreSession();

  Future<void> logout();

  Future<RoleRequestResult> requestRole({
    required String role,
    String? companyId,
    String? idDocumentType,
    String? idDocumentNumber,
  });
}
