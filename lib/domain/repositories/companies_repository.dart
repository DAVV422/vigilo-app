import 'package:latlong2/latlong.dart';

import '../entities/company.dart';
import '../entities/coverage_zone.dart';

/// Los datos para dar de alta una empresa.
class CompanyInput {
  const CompanyInput({
    required this.legalName,
    required this.displayName,
    required this.type,
    required this.taxId,
    required this.contactPhone,
    required this.contactEmail,
    this.logoUrl,
  });

  final String legalName;
  final String displayName;
  final CompanyType type;

  /// Solo dígitos. El servidor rechaza guiones y espacios, y la columna es
  /// única: con formato libre el mismo identificador entraría dos veces.
  final String taxId;
  final String contactPhone;
  final String contactEmail;
  final String? logoUrl;

  Map<String, dynamic> toJson() => {
        'legalName': legalName,
        'displayName': displayName,
        'type': type.wire,
        'taxId': taxId,
        'contactPhone': contactPhone,
        'contactEmail': contactEmail,
        'logoUrl': ?logoUrl,
      };
}

/// Alta, verificación y territorio de las empresas.
///
/// Desbloquea los cuatro roles que exigen una `company_id` —guardia,
/// recolector de basura, supervisor y gerente— y que hasta ahora no se
/// podían usar porque no había forma de crear una empresa.
abstract class CompaniesRepository {
  Future<List<Company>> getAll();

  Future<Company> getById(String id);

  Future<Company> create(CompanyInput input);

  /// Verificar habilita a la empresa para recibir incidentes asignados
  /// automáticamente. [approved] falso la rechaza.
  ///
  /// No lleva notas: `VerifyCompanyDto` solo acepta el estado, y el pipe de
  /// validación descarta en silencio lo que no declara, así que mandarlas
  /// daría la falsa impresión de que quedaron guardadas.
  Future<Company> verify(String id, {required bool approved});

  /// [includeInactive] para la pantalla de administración: sin eso, una zona
  /// desactivada no se podría volver a activar.
  Future<List<CoverageZone>> getZones(
    String companyId, {
    bool includeInactive = false,
  });

  /// [vertices] va **sin** el punto de cierre: la conversión a GeoJSON lo
  /// agrega, junto con el orden `[longitud, latitud]` que espera PostGIS.
  Future<CoverageZone> createZone({
    required String companyId,
    required String name,
    required List<LatLng> vertices,
  });

  Future<void> setZoneActive({
    required String companyId,
    required String zoneId,
    required bool active,
  });
}
