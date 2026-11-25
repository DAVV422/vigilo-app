import '../../domain/entities/audit_entry.dart';
import '../../domain/repositories/audit_repository.dart';
import '../datasources/remote/remote_audit_datasource.dart';

class RemoteAuditRepositoryImpl implements AuditRepository {
  RemoteAuditRepositoryImpl(this._datasource);

  final RemoteAuditDatasource _datasource;

  @override
  Future<AuditPage> query({
    int page = 1,
    int limit = 50,
    String? actorId,
    String? action,
    String? entityType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final raw = await _datasource.query({
      'page': page,
      'limit': limit,
      'actorId': ?actorId,
      'action': ?action,
      'entityType': ?entityType,
      'startDate': ?startDate?.toIso8601String(),
      'endDate': ?endDate?.toIso8601String(),
    });
    return AuditPage.fromJson(raw);
  }
}
