import '../../domain/entities/points_transaction.dart';
import '../../domain/repositories/points_repository.dart';
import '../demo/demo_state.dart';

class DemoPointsRepositoryImpl implements PointsRepository {
  DemoPointsRepositoryImpl(this._state);

  final DemoState _state;

  @override
  Future<List<PointsTransactionEntry>> getHistory({int page = 1, int limit = 20}) async {
    final start = (page - 1) * limit;
    if (start >= _state.pointsHistory.length) return [];
    final end = (start + limit).clamp(0, _state.pointsHistory.length);
    return _state.pointsHistory.sublist(start, end);
  }
}
