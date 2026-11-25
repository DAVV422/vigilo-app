import '../../domain/entities/admin_user.dart';
import '../../domain/repositories/admin_users_repository.dart';

/// Búsqueda de usuarios en modo demo.
///
/// El estado local solo conoce a quien inició sesión: no hay padrón que
/// recorrer. Devolver una lista vacía es la respuesta correcta, y las
/// pantallas que la usan lo explican en lugar de decir «nadie coincide»,
/// que sugeriría que el nombre está mal escrito.
class DemoAdminUsersRepositoryImpl implements AdminUsersRepository {
  const DemoAdminUsersRepositoryImpl();

  @override
  Future<List<AdminUser>> search(String query) async => const [];
}
