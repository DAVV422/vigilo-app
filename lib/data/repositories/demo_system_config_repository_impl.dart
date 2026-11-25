import '../../core/network/api_exception.dart';
import '../../domain/entities/system_config.dart';
import '../../domain/repositories/system_config_repository.dart';

/// Configuración del sistema en modo demo.
///
/// Las dos claves son las que siembra el servidor, con sus mismos valores,
/// para que la pantalla no se vea vacía en una presentación sin red.
class DemoSystemConfigRepositoryImpl implements SystemConfigRepository {
  DemoSystemConfigRepositoryImpl();

  final List<SystemConfig> _configs = [
    const SystemConfig(
      key: 'max_active_pickups_default',
      value: '5',
      description:
          'Límite estándar de recojos activos concurrentes por recolector.',
    ),
    const SystemConfig(
      key: 'pickup_auto_confirm_hours',
      value: '48',
      description:
          'Plazo en horas para la auto-confirmación de un recojo sin respuesta.',
    ),
  ];

  @override
  Future<List<SystemConfig>> getAll() async => List.unmodifiable(_configs);

  @override
  Future<SystemConfig> update(String key, String value) async {
    final i = _configs.indexWhere((c) => c.key == key);
    if (i < 0) {
      // Igual que el servidor: una clave desconocida no se crea.
      throw ApiException(
        statusCode: 404,
        message: 'No existe una configuración con la clave «$key».',
      );
    }
    final actualizada = SystemConfig(
      key: _configs[i].key,
      value: value,
      description: _configs[i].description,
      updatedAt: DateTime.now(),
    );
    _configs[i] = actualizada;
    return actualizada;
  }

  @override
  Future<void> setRecyclerPickupLimit(
    String userId,
    int? maxActivePickups,
  ) async {
    // Sin padrón de usuarios en modo demo no hay a quién ajustarle el
    // límite; la pantalla lo explica antes de llegar acá.
    throw ApiException(
      statusCode: 404,
      message: 'El modo demo no tiene un padrón de usuarios.',
    );
  }
}
