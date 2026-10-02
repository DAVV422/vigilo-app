import '../entities/citizen_summary.dart';
import '../entities/platform_impact.dart';

/// Respalda los dashboards (antes 100% datos locales inventados) con
/// agregaciones reales calculadas por el backend.
abstract class AnalyticsRepository {
  Future<CitizenSummary> getCitizenSummary();
  Future<PlatformImpact> getPlatformImpact();
}
