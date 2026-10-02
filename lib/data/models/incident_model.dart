import 'package:latlong2/latlong.dart';
import '../../domain/entities/incident.dart';

class IncidentModel extends Incident {
  IncidentModel({
    required super.id,
    required super.title,
    required super.description,
    required super.location,
    required super.type,
    required super.reportedAt,
    required super.reportedByUserId,
    required super.validatorsIds,
    super.severity = IncidentSeverity.medium,
    super.imageUrl = '',
    super.mediaUrls = const [],
    super.status = IncidentStatus.active,
    super.backendStatus,
    super.resolvedByUserId,
    super.resolvedByCompany,
    super.resolvedAt,
    super.resolutionComment,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      location: LatLng(json['lat'], json['lng']),
      type: IncidentType.values.firstWhere(
        (e) => e.toString() == 'IncidentType.${json['type']}',
        orElse: () => IncidentType.insecurity,
      ),
      severity: IncidentSeverity.values.firstWhere(
        (e) => e.name == (json['severity'] as String?)?.toLowerCase(),
        orElse: () => IncidentSeverity.medium,
      ),
      reportedAt: DateTime.parse(json['reportedAt']),
      reportedByUserId: json['reportedByUserId'],
      validatorsIds: List<String>.from(json['validatorsIds'] ?? []),
      imageUrl: json['imageUrl'] ?? '',
      mediaUrls: List<String>.from(json['mediaUrls'] ?? []),
      status: json['status'] == 'resolved' ? IncidentStatus.resolved : IncidentStatus.active,
      backendStatus: json['backendStatus'],
      resolvedByUserId: json['resolvedByUserId'],
      resolvedByCompany: json['resolvedByCompany'],
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      resolutionComment: json['resolutionComment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'lat': location.latitude,
      'lng': location.longitude,
      'type': type.toString().split('.').last,
      'reportedAt': reportedAt.toIso8601String(),
      'reportedByUserId': reportedByUserId,
      'validatorsIds': validatorsIds,
      'severity': severity.name,
      'imageUrl': imageUrl,
      'mediaUrls': mediaUrls,
      'status': status == IncidentStatus.resolved ? 'resolved' : 'active',
      'backendStatus': backendStatus,
      'resolvedByUserId': resolvedByUserId,
      'resolvedByCompany': resolvedByCompany,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolutionComment': resolutionComment,
    };
  }

  factory IncidentModel.fromEntity(Incident entity) {
    return IncidentModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      location: entity.location,
      type: entity.type,
      reportedAt: entity.reportedAt,
      reportedByUserId: entity.reportedByUserId,
      validatorsIds: entity.validatorsIds,
      severity: entity.severity,
      imageUrl: entity.imageUrl,
      mediaUrls: entity.mediaUrls,
      status: entity.status,
      backendStatus: entity.backendStatus,
      resolvedByUserId: entity.resolvedByUserId,
      resolvedByCompany: entity.resolvedByCompany,
      resolvedAt: entity.resolvedAt,
      resolutionComment: entity.resolutionComment,
    );
  }
}
