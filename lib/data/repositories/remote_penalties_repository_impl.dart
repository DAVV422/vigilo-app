import '../../domain/entities/penalty.dart';
import '../../domain/repositories/penalties_repository.dart';
import '../datasources/remote/remote_penalties_datasource.dart';

class RemotePenaltiesRepositoryImpl implements PenaltiesRepository {
  RemotePenaltiesRepositoryImpl(this._datasource);

  final RemotePenaltiesDatasource _datasource;

  @override
  Future<List<PenaltyRule>> getRules() async {
    final raw = await _datasource.getRules();
    return raw
        .map((r) => PenaltyRule.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PenaltyRule> updateRule(String id, PenaltyRuleInput input) async {
    return PenaltyRule.fromJson(await _datasource.updateRule(id, input.toJson()));
  }

  @override
  Future<List<Penalty>> getPenalties({
    String? userId,
    String? status,
    String? type,
  }) async {
    final raw = await _datasource.getPenalties(
      userId: userId,
      status: status,
      type: type,
    );
    return raw.map((p) => Penalty.fromJson(p as Map<String, dynamic>)).toList();
  }

  @override
  Future<AppliedPenalty> apply({
    required String userId,
    required String infractionCode,
    required String reason,
    int? customPointsDeducted,
  }) async {
    return AppliedPenalty.fromJson(await _datasource.apply({
      'userId': userId,
      'infractionCode': infractionCode,
      'reason': reason,
      'customPointsDeducted': ?customPointsDeducted,
    }));
  }

  @override
  Future<LiftedPenalty> lift({
    required String id,
    required String reason,
  }) async {
    return LiftedPenalty.fromJson(await _datasource.lift(id, reason));
  }
}
