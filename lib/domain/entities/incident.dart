import 'package:latlong2/latlong.dart';

enum IncidentType { insecurity, trash, weeds, recycling }
enum IncidentStatus { active, resolved }

class Incident {
  final String id;
  final String title;
  final String description;
  final LatLng location;
  final IncidentType type;
  final DateTime reportedAt;
  final String reportedByUserId;
  final List<String> validatorsIds;
  final String imageUrl;
  final IncidentStatus status;
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
    required this.reportedAt,
    required this.reportedByUserId,
    required this.validatorsIds,
    this.imageUrl = '',
    this.status = IncidentStatus.active,
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
    DateTime? reportedAt,
    String? reportedByUserId,
    List<String>? validatorsIds,
    String? imageUrl,
    IncidentStatus? status,
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
      reportedAt: reportedAt ?? this.reportedAt,
      reportedByUserId: reportedByUserId ?? this.reportedByUserId,
      validatorsIds: validatorsIds ?? this.validatorsIds,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      resolvedByUserId: resolvedByUserId ?? this.resolvedByUserId,
      resolvedByCompany: resolvedByCompany ?? this.resolvedByCompany,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionComment: resolutionComment ?? this.resolutionComment,
    );
  }
}
