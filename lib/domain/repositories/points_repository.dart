import '../entities/points_transaction.dart';

/// Historial de puntos del usuario (ledger `points_transactions` del
/// backend). Es de solo lectura por diseño: el balance y cada movimiento los
/// calcula siempre el servidor (ver docs/reglas-negocio.md — "el cliente
/// nunca debe calcular ni aplicar puntos").
abstract class PointsRepository {
  Future<List<PointsTransactionEntry>> getHistory({int page = 1, int limit = 20});
}
