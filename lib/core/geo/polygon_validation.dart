import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Validación y conversión de los polígonos de cobertura.
///
/// Vive acá, separado de la pantalla, porque es lógica pura: se prueba sin
/// levantar un mapa y es donde esta función se rompe en silencio.
///
/// **El error que importa es el orden de las coordenadas.** `LatLng` guarda
/// latitud primero; GeoJSON —y por lo tanto PostGIS y el backend— espera
/// longitud primero. Invertirlo no falla: produce un polígono válido en
/// medio de Somalia, y lo único que se nota es que la asignación automática
/// de incidentes deja de encontrar empresas, semanas después.
class PolygonValidation {
  PolygonValidation._();

  /// Menos de tres vértices no encierran ningún área.
  static const int minVertices = 3;

  /// Avisos, no bloqueos: una zona puede legítimamente ser rara.
  static const double maxReasonableAreaKm2 = 300;
  static const double minReasonableAreaKm2 = 0.01;
}

/// Convierte los vértices dibujados al anillo que espera el backend.
///
/// Hace las dos cosas que el servidor exige y la persona no debería tener
/// que hacer: emite `[longitud, latitud]` y **cierra el anillo** repitiendo
/// el primer punto al final.
List<List<double>> toGeoJsonRing(List<LatLng> vertices) {
  if (vertices.length < PolygonValidation.minVertices) {
    throw ArgumentError(
      'Un anillo necesita al menos ${PolygonValidation.minVertices} vértices; '
      'llegaron ${vertices.length}.',
    );
  }

  final ring = <List<double>>[
    for (final v in vertices) [v.longitude, v.latitude],
  ];

  final first = ring.first;
  final last = ring.last;
  if (first[0] != last[0] || first[1] != last[1]) {
    ring.add([first[0], first[1]]);
  }
  return ring;
}

/// El camino inverso: el anillo que devuelve el servidor, listo para dibujar.
///
/// Descarta el punto de cierre, porque `PolygonLayer` cierra solo y un
/// vértice repetido se vería como un punto doble encima de otro.
List<LatLng> fromGeoJsonRing(List<dynamic> ring) {
  final points = <LatLng>[];
  for (final raw in ring) {
    final pair = (raw as List<dynamic>).map((n) => (n as num).toDouble()).toList();
    points.add(LatLng(pair[1], pair[0]));
  }

  if (points.length > 1 &&
      points.first.latitude == points.last.latitude &&
      points.first.longitude == points.last.longitude) {
    points.removeLast();
  }
  return points;
}

/// Devuelve el motivo por el que el polígono no se puede guardar, o `null`.
///
/// Se valida acá y no en el servidor porque PostGIS rechaza una geometría
/// inválida con un error que no le dice nada a nadie.
String? validateRing(List<LatLng> vertices) {
  if (vertices.length < PolygonValidation.minVertices) {
    final faltan = PolygonValidation.minVertices - vertices.length;
    return faltan == 1
        ? 'Falta un punto: una zona necesita al menos tres.'
        : 'Faltan $faltan puntos: una zona necesita al menos tres.';
  }

  for (final v in vertices) {
    if (v.latitude < -90 ||
        v.latitude > 90 ||
        v.longitude < -180 ||
        v.longitude > 180) {
      return 'Hay un punto fuera del mapa.';
    }
  }

  if (hasSelfIntersection(vertices)) {
    return 'Los lados de la zona se cruzan. Movelos para que el contorno '
        'no se pise a sí mismo.';
  }

  return null;
}

/// Aviso opcional sobre el tamaño. Nunca bloquea: devuelve `null` si está bien.
String? areaWarning(List<LatLng> vertices) {
  if (vertices.length < PolygonValidation.minVertices) return null;
  final km2 = approximateAreaKm2(vertices);

  if (km2 > PolygonValidation.maxReasonableAreaKm2) {
    return 'La zona cubre ${km2.toStringAsFixed(0)} km², más que toda la '
        'ciudad. Revisá que sea lo que querés.';
  }
  if (km2 < PolygonValidation.minReasonableAreaKm2) {
    return 'La zona es más chica que una manzana. Revisá que sea lo que querés.';
  }
  return null;
}

/// ¿Hay dos lados no contiguos que se cruzan?
///
/// Con la cantidad de vértices que se dibujan con el dedo, comparar todos
/// los pares es instantáneo y no justifica nada más sofisticado.
bool hasSelfIntersection(List<LatLng> v) {
  final n = v.length;
  if (n < 4) return false;

  for (var i = 0; i < n; i++) {
    final a1 = v[i];
    final a2 = v[(i + 1) % n];

    for (var j = i + 1; j < n; j++) {
      // Los lados contiguos comparten un vértice: tocarse es normal.
      if (j == i) continue;
      if ((j + 1) % n == i || (i + 1) % n == j) continue;

      final b1 = v[j];
      final b2 = v[(j + 1) % n];
      if (_segmentsCross(a1, a2, b1, b2)) return true;
    }
  }
  return false;
}

/// Área aproximada en km².
///
/// Proyección plana local: a escala de una ciudad el error es despreciable
/// y lo que se busca es que un cero de más salte a la vista, no exactitud
/// cartográfica.
double approximateAreaKm2(List<LatLng> v) {
  if (v.length < 3) return 0;

  final meanLat =
      v.map((p) => p.latitude).reduce((a, b) => a + b) / v.length;
  final cosLat = math.cos(meanLat * math.pi / 180);

  const metersPerDegreeLat = 110540.0;
  const metersPerDegreeLng = 111320.0;

  double sum = 0;
  for (var i = 0; i < v.length; i++) {
    final p = v[i];
    final q = v[(i + 1) % v.length];
    final px = p.longitude * metersPerDegreeLng * cosLat;
    final py = p.latitude * metersPerDegreeLat;
    final qx = q.longitude * metersPerDegreeLng * cosLat;
    final qy = q.latitude * metersPerDegreeLat;
    sum += px * qy - qx * py;
  }

  return (sum.abs() / 2) / 1000000;
}

double _cross(LatLng o, LatLng a, LatLng b) =>
    (a.longitude - o.longitude) * (b.latitude - o.latitude) -
    (a.latitude - o.latitude) * (b.longitude - o.longitude);

bool _onSegment(LatLng a, LatLng b, LatLng p) =>
    math.min(a.longitude, b.longitude) <= p.longitude &&
    p.longitude <= math.max(a.longitude, b.longitude) &&
    math.min(a.latitude, b.latitude) <= p.latitude &&
    p.latitude <= math.max(a.latitude, b.latitude);

bool _segmentsCross(LatLng a1, LatLng a2, LatLng b1, LatLng b2) {
  final d1 = _cross(a1, a2, b1);
  final d2 = _cross(a1, a2, b2);
  final d3 = _cross(b1, b2, a1);
  final d4 = _cross(b1, b2, a2);

  if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
      ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
    return true;
  }

  // Colineales que se solapan: también es un contorno que se pisa.
  if (d1 == 0 && _onSegment(a1, a2, b1)) return true;
  if (d2 == 0 && _onSegment(a1, a2, b2)) return true;
  if (d3 == 0 && _onSegment(b1, b2, a1)) return true;
  if (d4 == 0 && _onSegment(b1, b2, a2)) return true;

  return false;
}
