import '../../domain/entities/points_transaction.dart';
import '../../domain/repositories/points_repository.dart';
import '../datasources/remote/remote_auth_datasource.dart';

/// El endpoint de historial de puntos vive bajo `UsersModule`
/// (`GET /users/me/points/history`), así que reutiliza el mismo datasource
/// HTTP que la autenticación/perfil en vez de duplicar el cliente Dio.
class RemotePointsRepositoryImpl implements PointsRepository {
  RemotePointsRepositoryImpl(this._datasource);

  final RemoteAuthDatasource _datasource;

  @override
  Future<List<PointsTransactionEntry>> getHistory({int page = 1, int limit = 20}) async {
    final raw = await _datasource.getPointsHistory(page: page, limit: limit);
    return raw
        .map((json) => PointsTransactionEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
