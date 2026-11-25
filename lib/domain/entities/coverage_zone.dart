import 'package:latlong2/latlong.dart';

import '../../core/geo/polygon_validation.dart';

/// El territorio que atiende una empresa.
///
/// No es decorativo: `IncidentsService` busca con `ST_Contains` qué zona
/// contiene el punto de un incidente nuevo y se lo asigna a esa empresa.
/// Un polígono mal dibujado no falla, manda incidentes a quien no
/// corresponde.
class CoverageZone {
  const CoverageZone({
    required this.id,
    required this.companyId,
    required this.name,
    required this.vertices,
    required this.active,
    this.createdAt,
  });

  final String id;
  final String companyId;
  final String name;

  /// Vértices en el orden en que se dibujan, **sin** el punto de cierre:
  /// `PolygonLayer` cierra solo y un vértice repetido se vería doble.
  final List<LatLng> vertices;

  /// Una zona inactiva deja de recibir asignaciones pero no se borra: el
  /// historial de incidentes ya asignados tiene que seguir explicándose.
  final bool active;
  final DateTime? createdAt;

  double get areaKm2 => approximateAreaKm2(vertices);

  factory CoverageZone.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    var vertices = <LatLng>[];

    if (geometry is Map<String, dynamic>) {
      final rings = geometry['coordinates'];
      if (rings is List && rings.isNotEmpty && rings.first is List) {
        // Solo el anillo exterior: la UI no genera agujeros y dibujarlos
        // como si fueran el contorno sería peor que ignorarlos.
        vertices = fromGeoJsonRing(rings.first as List<dynamic>);
      }
    }

    return CoverageZone(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      name: json['name'] as String? ?? 'Zona',
      vertices: vertices,
      active: json['active'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}
