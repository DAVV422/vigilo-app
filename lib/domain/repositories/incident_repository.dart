import '../entities/incident.dart';

enum IncidentVote { stillPresent, falseReport }

abstract class IncidentRepository {
  Future<List<Incident>> getIncidents();
  Future<void> addIncident(Incident incident);

  /// [vote] solo lo usa la implementación remota (el backend distingue
  /// "sigue vigente" de "reporte falso"); la local lo ignora y siempre
  /// suma a `validatorsIds` para no cambiar su comportamiento ya probado.
  Future<void> validateIncident(
    String incidentId,
    String userId, {
    IncidentVote vote = IncidentVote.stillPresent,
  });

  /// [companyId]/[companyName] solo los usa la implementación local, que
  /// denormaliza el nombre de la empresa resolutora. El backend real infiere
  /// el usuario resolutor del token de autenticación y en cambio exige
  /// [resolutionMediaId] (evidencia fotográfica obligatoria) — si se omite,
  /// la llamada remota fallará con un error 400 explícito.
  Future<void> resolveIncident({
    required String incidentId,
    required String userId,
    String? companyId,
    String? companyName,
    required String comment,
    String? resolutionMediaId,
  });
}
