import 'package:latlong2/latlong.dart';
import '../../domain/entities/incident.dart';
import '../../domain/repositories/incident_repository.dart';
import '../datasources/remote/remote_incident_datasource.dart';

/// Centro usado por [getIncidents] mientras no exista un flujo que pase la
/// ubicación real del usuario a esta capa (el backend no tiene un endpoint
/// "todos los incidentes", solo búsqueda por radio geográfico). Coincide con
/// el centro simulado por defecto de `currentLocationProvider`.
const _defaultCenter = LatLng(-17.783327, -63.182141);

class RemoteIncidentRepositoryImpl implements IncidentRepository {
  RemoteIncidentRepositoryImpl(this._datasource);

  final RemoteIncidentDatasource _datasource;

  Incident _fromJson(Map<String, dynamic> json) {
    final type = IncidentType.values.firstWhere(
      (e) => _typeToBackend(e) == json['type'],
      orElse: () => IncidentType.other,
    );
    final severity = IncidentSeverity.values.firstWhere(
      (e) => e.name.toUpperCase() == json['severity'],
      orElse: () => IncidentSeverity.medium,
    );
    final backendStatus = json['status'] as String?;
    final isClosed = backendStatus == 'RESOLVED' ||
        backendStatus == 'REJECTED' ||
        backendStatus == 'EXPIRED';

    final mediaUrls = ((json['media'] as List<dynamic>?) ?? [])
        .map((m) => (m as Map<String, dynamic>)['url'] as String)
        .toList();

    return Incident(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      location: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      type: type,
      severity: severity,
      reportedAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      reportedByUserId: (json['reporter'] as Map<String, dynamic>?)?['id'] as String? ?? '',
      validatorsIds: const [],
      imageUrl: mediaUrls.isNotEmpty ? mediaUrls.first : '',
      mediaUrls: mediaUrls,
      status: isClosed ? IncidentStatus.resolved : IncidentStatus.active,
      backendStatus: backendStatus,
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt'] as String) : null,
      resolutionComment: json['resolutionComment'] as String?,
    );
  }

  String _typeToBackend(IncidentType type) {
    switch (type) {
      case IncidentType.insecurity:
        return 'INSECURITY';
      case IncidentType.trash:
        return 'TRASH';
      case IncidentType.weeds:
        return 'WEEDS';
      case IncidentType.streetLight:
        return 'STREET_LIGHT';
      case IncidentType.pothole:
        return 'POTHOLE';
      case IncidentType.recycling:
      case IncidentType.other:
        return 'OTHER';
    }
  }

  String _severityToBackend(IncidentSeverity severity) => severity.name.toUpperCase();

  @override
  Future<List<Incident>> getIncidents() async {
    final raw = await _datasource.findNearby(
      latitude: _defaultCenter.latitude,
      longitude: _defaultCenter.longitude,
      radiusKm: 30,
    );
    return raw.map((json) => _fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Incident>> getNearbyIncidents({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    final raw = await _datasource.findNearby(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
    return raw.map((json) => _fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> addIncident(Incident incident) async {
    if (incident.type == IncidentType.recycling) {
      throw ArgumentError(
        'El reciclaje ya no se reporta como Incident — usa RecyclingRepository.createListing().',
      );
    }

    await _datasource.create(
      type: _typeToBackend(incident.type),
      severity: _severityToBackend(incident.severity),
      title: incident.title,
      description: incident.description,
      latitude: incident.location.latitude,
      longitude: incident.location.longitude,
      mediaUrls: incident.mediaUrls.isNotEmpty ? incident.mediaUrls : null,
    );
  }

  @override
  Future<void> validateIncident(
    String incidentId,
    String userId, {
    IncidentVote vote = IncidentVote.stillPresent,
  }) async {
    await _datasource.validate(
      incidentId: incidentId,
      vote: vote == IncidentVote.stillPresent ? 'STILL_PRESENT' : 'FALSE_REPORT',
    );
  }

  @override
  Future<void> resolveIncident({
    required String incidentId,
    required String userId,
    String? companyId,
    String? companyName,
    required String comment,
    String? resolutionMediaId,
  }) async {
    if (resolutionMediaId == null || resolutionMediaId.isEmpty) {
      throw ArgumentError(
        'El backend exige una foto de evidencia (resolutionMediaId) para resolver un incidente.',
      );
    }
    await _datasource.resolve(
      incidentId: incidentId,
      resolutionComment: comment,
      resolutionMediaId: resolutionMediaId,
    );
  }
}
