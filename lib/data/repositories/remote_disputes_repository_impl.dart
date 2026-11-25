import '../../domain/entities/dispute.dart';
import '../../domain/repositories/disputes_repository.dart';
import '../datasources/remote/remote_disputes_datasource.dart';

class RemoteDisputesRepositoryImpl implements DisputesRepository {
  RemoteDisputesRepositoryImpl(this._datasource);

  final RemoteDisputesDatasource _datasource;

  @override
  Future<List<Dispute>> getAll({String? status}) async {
    final raw = await _datasource.getAll(status: status);
    return raw.map((d) => Dispute.fromJson(d as Map<String, dynamic>)).toList();
  }

  @override
  Future<Dispute> getById(String id) async {
    return Dispute.fromJson(await _datasource.getById(id));
  }

  @override
  Future<void> resolve({
    required String id,
    required DisputeAction action,
    required String notes,
    List<AdjustedWeight>? adjustedWeights,
    int? creditPointsAmount,
    String? penaltyInfractionCode,
  }) {
    return _datasource.resolve(id, {
      'action': action.wire,
      'resolutionNotes': notes,
      if (adjustedWeights != null)
        'adjustedWeights': adjustedWeights.map((w) => w.toJson()).toList(),
      'creditPointsAmount': ?creditPointsAmount,
      'penaltyInfractionCode': ?penaltyInfractionCode,
    });
  }
}
