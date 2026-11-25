import '../entities/system_config.dart';

/// Parámetros globales del sistema y límites por recolector (`ADMIN`).
abstract class SystemConfigRepository {
  Future<List<SystemConfig>> getAll();

  /// El valor viaja como texto porque la columna lo es. La validación del
  /// tipo es del cliente: el servidor acepta cualquier cadena.
  Future<SystemConfig> update(String key, String value);

  /// Límite individual de recojos activos de un recolector.
  ///
  /// `null` **restablece el estándar global**, no significa cero. El
  /// servidor responde 404 si la persona no tiene el rol de recolector.
  Future<void> setRecyclerPickupLimit(String userId, int? maxActivePickups);
}
