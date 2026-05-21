import '../entities/incident.dart';

abstract class IncidentRepository {
  Future<List<Incident>> getIncidents();
  Future<void> addIncident(Incident incident);
  Future<void> validateIncident(String incidentId, String userId);
  Future<void> resolveIncident({
    required String incidentId,
    required String userId,
    required String companyId,
    required String companyName,
    required String comment,
  });
}
