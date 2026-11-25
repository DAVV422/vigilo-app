import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:vigilo/core/geo/polygon_validation.dart';

/// El anillo real de la zona "Casco Viejo y 1er Anillo", tal como lo guarda
/// el servidor: longitud primero y con el punto de cierre repetido.
const _cascoViejo = <List<double>>[
  [-63.1925, -17.7925],
  [-63.1720, -17.7925],
  [-63.1720, -17.7762],
  [-63.1925, -17.7762],
  [-63.1925, -17.7925],
];

void main() {
  group('cuántos puntos hacen una zona', () {
    test('tres alcanzan', () {
      expect(
        validateRing([
          const LatLng(-17.79, -63.19),
          const LatLng(-17.79, -63.17),
          const LatLng(-17.77, -63.18),
        ]),
        isNull,
      );
    });

    test('dos no, y lo dice', () {
      final problema = validateRing([
        const LatLng(-17.79, -63.19),
        const LatLng(-17.79, -63.17),
      ]);
      expect(problema, isNotNull);
      expect(problema, contains('tres'));
    });
  });

  group('contornos que se pisan', () {
    test('un reloj de arena se detecta', () {
      // Los lados opuestos se cruzan en el medio.
      final relojDeArena = [
        const LatLng(-17.79, -63.19),
        const LatLng(-17.77, -63.17),
        const LatLng(-17.79, -63.17),
        const LatLng(-17.77, -63.19),
      ];
      expect(hasSelfIntersection(relojDeArena), isTrue);
      expect(validateRing(relojDeArena), contains('cruzan'));
    });

    test('un rectángulo no se pisa', () {
      final rect = fromGeoJsonRing(_cascoViejo);
      expect(hasSelfIntersection(rect), isFalse);
      expect(validateRing(rect), isNull);
    });
  });

  // El error silencioso de toda la función: si esto se invierte, el polígono
  // queda en medio de Somalia y nada falla hasta que la asignación
  // automática de incidentes deja de encontrar empresas.
  group('orden de las coordenadas', () {
    test('emite longitud primero, no latitud', () {
      final ring = toGeoJsonRing([
        const LatLng(-17.7925, -63.1925),
        const LatLng(-17.7925, -63.1720),
        const LatLng(-17.7762, -63.1720),
      ]);

      expect(ring.first[0], -63.1925, reason: 'el primer número es longitud');
      expect(ring.first[1], -17.7925, reason: 'el segundo número es latitud');

      // Santa Cruz: longitud cerca de -63, latitud cerca de -17.
      for (final par in ring) {
        expect(par[0], lessThan(-60));
        expect(par[1], greaterThan(-20));
      }
    });

    test('al leer, la latitud vuelve a quedar primero', () {
      final puntos = fromGeoJsonRing(_cascoViejo);
      expect(puntos.first.latitude, -17.7925);
      expect(puntos.first.longitude, -63.1925);
    });
  });

  group('cierre del anillo', () {
    test('el último punto repite el primero', () {
      final ring = toGeoJsonRing([
        const LatLng(-17.79, -63.19),
        const LatLng(-17.79, -63.17),
        const LatLng(-17.77, -63.18),
      ]);
      expect(ring.length, 4, reason: 'tres vértices más el de cierre');
      expect(ring.last, equals(ring.first));
    });

    test('no agrega un cierre si ya venía cerrado', () {
      final ring = toGeoJsonRing(fromGeoJsonRing(_cascoViejo));
      expect(ring.length, _cascoViejo.length);
    });

    test('menos de tres vértices no produce un anillo', () {
      expect(
        () => toGeoJsonRing([const LatLng(-17.79, -63.19)]),
        throwsArgumentError,
      );
    });
  });

  test('la zona del servidor sobrevive la ida y la vuelta', () {
    final ring = toGeoJsonRing(fromGeoJsonRing(_cascoViejo));
    expect(ring, equals(_cascoViejo));
  });

  group('tamaño de la zona', () {
    test('el Casco Viejo mide unos pocos km²', () {
      final km2 = approximateAreaKm2(fromGeoJsonRing(_cascoViejo));
      // ~2,2 km × ~1,8 km.
      expect(km2, greaterThan(2));
      expect(km2, lessThan(8));
      expect(areaWarning(fromGeoJsonRing(_cascoViejo)), isNull);
    });

    test('una zona del tamaño de un departamento avisa', () {
      final enorme = [
        const LatLng(-18.5, -64.0),
        const LatLng(-18.5, -62.5),
        const LatLng(-17.0, -62.5),
        const LatLng(-17.0, -64.0),
      ];
      expect(areaWarning(enorme), contains('km²'));
    });
  });
}
