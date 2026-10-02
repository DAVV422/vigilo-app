import '../../domain/entities/citizen_summary.dart';
import '../../domain/entities/platform_impact.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/remote/remote_analytics_datasource.dart';

class RemoteAnalyticsRepositoryImpl implements AnalyticsRepository {
  RemoteAnalyticsRepositoryImpl(this._datasource);

  final RemoteAnalyticsDatasource _datasource;

  @override
  Future<CitizenSummary> getCitizenSummary() async {
    final json = await _datasource.getCitizenSummary();
    return CitizenSummary.fromJson(json);
  }

  @override
  Future<PlatformImpact> getPlatformImpact() async {
    final json = await _datasource.getImpact();
    return PlatformImpact.fromJson(json);
  }
}
