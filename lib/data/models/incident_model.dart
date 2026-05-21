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
    super.imageUrl = '',
    super.status = IncidentStatus.active,
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
      reportedAt: DateTime.parse(json['reportedAt']),
      reportedByUserId: json['reportedByUserId'],
      validatorsIds: List<String>.from(json['validatorsIds'] ?? []),
      imageUrl: json['imageUrl'] ?? '',
      status: json['status'] == 'resolved' ? IncidentStatus.resolved : IncidentStatus.active,
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
      'imageUrl': imageUrl,
      'status': status == IncidentStatus.resolved ? 'resolved' : 'active',
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
      imageUrl: entity.imageUrl,
      status: entity.status,
      resolvedByUserId: entity.resolvedByUserId,
      resolvedByCompany: entity.resolvedByCompany,
      resolvedAt: entity.resolvedAt,
      resolutionComment: entity.resolutionComment,
    );
  }
}
