import 'package:latlong2/latlong.dart';

import '../../core/geo/polygon_validation.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/coverage_zone.dart';
import '../../domain/repositories/companies_repository.dart';
import '../datasources/remote/remote_companies_datasource.dart';

class RemoteCompaniesRepositoryImpl implements CompaniesRepository {
  RemoteCompaniesRepositoryImpl(this._datasource);

  final RemoteCompaniesDatasource _datasource;

  @override
  Future<List<Company>> getAll() async {
    final raw = await _datasource.getAll();
    return raw.map((c) => Company.fromJson(c as Map<String, dynamic>)).toList();
  }

  @override
  Future<Company> getById(String id) async {
    return Company.fromJson(await _datasource.getById(id));
  }

  @override
  Future<Company> create(CompanyInput input) async {
    return Company.fromJson(await _datasource.create(input.toJson()));
  }

  @override
  Future<Company> verify(String id, {required bool approved}) async {
    final status = approved ? 'VERIFIED' : 'REJECTED';
    return Company.fromJson(await _datasource.verify(id, status));
  }

  @override
  Future<List<CoverageZone>> getZones(
    String companyId, {
    bool includeInactive = false,
  }) async {
    final raw = await _datasource.getZones(
      companyId,
      includeInactive: includeInactive,
    );
    return raw
        .map((z) => CoverageZone.fromJson(z as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CoverageZone> createZone({
    required String companyId,
    required String name,
    required List<LatLng> vertices,
  }) async {
    final created = await _datasource.createZone(companyId, {
      'name': name,
      // Un solo anillo: la UI no genera polígonos con agujeros.
      'coordinates': [toGeoJsonRing(vertices)],
    });

    // La respuesta del alta no devuelve la geometría, así que se reusan los
    // vértices que se acaban de enviar en vez de pedir la zona de nuevo.
    return CoverageZone(
      id: created['id'] as String,
      companyId: created['companyId'] as String? ?? companyId,
      name: created['name'] as String? ?? name,
      vertices: vertices,
      active: created['active'] as bool? ?? true,
      createdAt: created['createdAt'] != null
          ? DateTime.parse(created['createdAt'] as String)
          : null,
    );
  }

  @override
  Future<void> setZoneActive({
    required String companyId,
    required String zoneId,
    required bool active,
  }) {
    return _datasource.updateZone(companyId, zoneId, {'active': active});
  }
}
