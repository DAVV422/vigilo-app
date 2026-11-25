import '../../domain/entities/system_config.dart';
import '../../domain/repositories/system_config_repository.dart';
import '../datasources/remote/remote_system_config_datasource.dart';

class RemoteSystemConfigRepositoryImpl implements SystemConfigRepository {
  RemoteSystemConfigRepositoryImpl(this._datasource);

  final RemoteSystemConfigDatasource _datasource;

  @override
  Future<List<SystemConfig>> getAll() async {
    final raw = await _datasource.getAll();
    return raw
        .map((c) => SystemConfig.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SystemConfig> update(String key, String value) async {
    return SystemConfig.fromJson(await _datasource.update(key, value));
  }

  @override
  Future<void> setRecyclerPickupLimit(String userId, int? maxActivePickups) {
    return _datasource.setRecyclerLimit(userId, maxActivePickups);
  }
}
