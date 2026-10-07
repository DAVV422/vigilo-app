import 'package:collection/collection.dart';
import '../../domain/entities/citizen_summary.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/platform_impact.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/local_json_datasource.dart';
import '../demo/demo_state.dart';
import '../models/incident_model.dart';

/// Calcula los mismos agregados que el backend real, pero a partir de los
/// incidentes semilla ([LocalJsonDatasource]) y el marketplace en memoria
/// ([DemoState]) — nunca números inventados, para que la demo sea honesta
/// incluso sin servidor: si el presentador reporta algo en vivo, el panel
/// de KPIs lo refleja de inmediato.
class DemoAnalyticsRepositoryImpl implements AnalyticsRepository {
  DemoAnalyticsRepositoryImpl(this._datasource, this._state);

  final LocalJsonDatasource _datasource;
  final DemoState _state;

  @override
  Future<CitizenSummary> getCitizenSummary() async {
    final userId = _state.currentUser?.id ?? '';
    final data = await _datasource.readData();
    final incidents = (data['incidents'] as List<dynamic>)
        .map((i) => IncidentModel.fromJson(i as Map<String, dynamic>))
        .toList();

    final reported = incidents.where((i) => i.reportedByUserId == userId).toList();
    final resolved = reported.where((i) => i.status == IncidentStatus.resolved).length;
    final validated = incidents.where((i) => i.validatorsIds.contains(userId)).length;

    final myListings = _state.listings.where((l) => l.citizen?.id == userId).toList();
    final completedListings = myListings.where((l) => l.status == 'COMPLETED').toList();
    final recycledAsCitizenGrams = completedListings
        .expand((l) => l.materials)
        .fold<double>(0, (sum, m) => sum + m.estimatedWeightGrams);

    final myPickups = _state.pickups.values.where((p) {
      final listing = _state.listings.firstWhereOrNull((l) => l.id == p.listingId);
      return listing?.pickupRecyclerId == userId;
    }).toList();
    final completedPickups = myPickups.where((p) => p.status == 'COMPLETED').toList();
    final recycledAsRecyclerGrams = completedPickups
        .expand((p) => p.results)
        .fold<double>(0, (sum, r) => sum + r.actualWeightGrams);

    final pointsEarned = _state.pointsHistory.where((t) => t.delta > 0).fold<int>(0, (s, t) => s + t.delta);
    final pointsRedeemed = _state.pointsHistory.where((t) => t.delta < 0).fold<int>(0, (s, t) => s - t.delta);

    return CitizenSummary(
      incidentsReported: reported.length,
      incidentsResolved: resolved,
      incidentsValidated: validated,
      listingsPublished: myListings.length,
      listingsCompleted: completedListings.length,
      recycledAsCitizenKg: recycledAsCitizenGrams / 1000,
      pickupsCompletedAsRecycler: completedPickups.length,
      recycledAsRecyclerKg: recycledAsRecyclerGrams / 1000,
      pointsBalance: _state.currentUser?.points ?? 0,
      pointsEarned: pointsEarned,
      pointsRedeemed: pointsRedeemed,
    );
  }

  @override
  Future<PlatformImpact> getPlatformImpact() async {
    final completedListings = _state.listings.where((l) => l.status == 'COMPLETED').toList();

    final totalWeightGrams =
        completedListings.expand((l) => l.materials).fold<double>(0, (sum, m) => sum + m.estimatedWeightGrams);

    final breakdownGrams = <String, double>{};
    double co2Kg = 0;
    for (final listing in completedListings) {
      for (final m in listing.materials) {
        final name = m.materialName ?? 'Otro';
        breakdownGrams[name] = (breakdownGrams[name] ?? 0) + m.estimatedWeightGrams;
        final material = _state.materials.firstWhereOrNull((mt) => mt.id == m.materialId);
        if (material != null) co2Kg += (m.estimatedWeightGrams / 1000) * material.co2FactorPerKg;
      }
    }

    // A nivel plataforma no alcanza con el historial de puntos del usuario
    // logueado (solo refleja "sus" movimientos) — se suma directo desde los
    // recojos confirmados y los canjes, sin importar de quién son.
    final pointsIssued = _state.pickups.values
        .where((p) => p.status == 'COMPLETED')
        .expand((p) => p.results)
        .fold<int>(0, (s, r) => s + r.pointsAwarded);
    final pointsRedeemed = _state.redemptions.fold<int>(0, (s, r) => s + r.pointsSpent);

    final totalListings = _state.listings.length;
    final retrievalRate = totalListings > 0 ? (completedListings.length / totalListings) * 100 : 0.0;

    return PlatformImpact(
      totalWeightKgRecycled: totalWeightGrams / 1000,
      co2AvoidedKg: co2Kg,
      pointsIssued: pointsIssued,
      pointsRedeemed: pointsRedeemed,
      activeRecyclers: _state.listings.map((l) => l.pickupRecyclerId).whereType<String>().toSet().length,
      listingsPublished: totalListings,
      listingsCompleted: completedListings.length,
      retrievalRatePercent: retrievalRate,
      materialBreakdown: breakdownGrams.entries
          .map((e) => MaterialImpactBreakdown(materialName: e.key, category: 'N/A', totalWeightKg: e.value / 1000))
          .toList(),
    );
  }
}
