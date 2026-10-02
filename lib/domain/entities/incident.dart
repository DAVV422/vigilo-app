import 'package:latlong2/latlong.dart';

// streetLight/pothole/other existen en el backend real (IncidentType) pero
// todavía no tienen UI propia en el mobile; se agregan igual para que
// deserializar un incidente con ese tipo nunca falle.
enum IncidentType { insecurity, trash, weeds, recycling, streetLight, pothole, other }
enum IncidentStatus { active, resolved }
enum IncidentSeverity { low, medium, high, critical }

class Incident {
  final String id;
  final String title;
  final String description;
  final LatLng location;
  final IncidentType type;
  final IncidentSeverity severity;
  final DateTime reportedAt;
  final String reportedByUserId;
  final List<String> validatorsIds;
  final String imageUrl;
  final List<String> mediaUrls;
  final IncidentStatus status;
  // Estado textual tal como lo devuelve el backend real (PENDING, VALIDATED,
  // IN_PROGRESS, RESOLVED, REJECTED, EXPIRED). `status` arriba sigue siendo
  // el binario simplificado activo/resuelto que ya usa toda la UI existente;
  // este campo es aditivo para no romper esa UI y queda disponible para
  // cuando se quiera mostrar el estado real con más detalle.
  final String? backendStatus;
  final String? resolvedByUserId;
  final String? resolvedByCompany;
  final DateTime? resolvedAt;
  final String? resolutionComment;

  Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.type,
    this.severity = IncidentSeverity.medium,
    required this.reportedAt,
    required this.reportedByUserId,
    required this.validatorsIds,
    this.imageUrl = '',
    this.mediaUrls = const [],
    this.status = IncidentStatus.active,
    this.backendStatus,
    this.resolvedByUserId,
    this.resolvedByCompany,
    this.resolvedAt,
    this.resolutionComment,
  });

  Incident copyWith({
    String? id,
    String? title,
    String? description,
    LatLng? location,
    IncidentType? type,
    IncidentSeverity? severity,
    DateTime? reportedAt,
    String? reportedByUserId,
    List<String>? validatorsIds,
    String? imageUrl,
    List<String>? mediaUrls,
    IncidentStatus? status,
    String? backendStatus,
    String? resolvedByUserId,
    String? resolvedByCompany,
    DateTime? resolvedAt,
    String? resolutionComment,
  }) {
    return Incident(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      reportedAt: reportedAt ?? this.reportedAt,
      reportedByUserId: reportedByUserId ?? this.reportedByUserId,
      validatorsIds: validatorsIds ?? this.validatorsIds,
      imageUrl: imageUrl ?? this.imageUrl,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      status: status ?? this.status,
      backendStatus: backendStatus ?? this.backendStatus,
      resolvedByUserId: resolvedByUserId ?? this.resolvedByUserId,
      resolvedByCompany: resolvedByCompany ?? this.resolvedByCompany,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionComment: resolutionComment ?? this.resolutionComment,
    );
  }
}
