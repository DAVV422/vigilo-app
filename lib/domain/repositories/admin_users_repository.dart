import '../entities/admin_user.dart';

/// Búsqueda de personas para la administración (`ADMIN`).
///
/// Vive aparte porque la necesitan dos funciones distintas —aplicar una
/// sanción y ajustar el límite de recojos de un recolector— y en ninguna de
/// las dos es el asunto principal. Estuvo un rato dentro del repositorio de
/// sanciones, que fue donde hizo falta primero; la segunda función dejó
/// claro que no pertenecía ahí.
abstract class AdminUsersRepository {
  /// Busca por nombre, apellido, usuario o correo exacto.
  ///
  /// Es una búsqueda, no un listado: el servidor exige al menos 3
  /// caracteres y acota los resultados. No hay forma de pedir la base
  /// entera, y es deliberado.
  Future<List<AdminUser>> search(String query);
}
