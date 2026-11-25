import 'package:latlong2/latlong.dart';

import '../../core/network/api_exception.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/coverage_zone.dart';
import '../../domain/repositories/companies_repository.dart';

/// Empresas en modo demo.
///
/// Arranca con las tres de Santa Cruz y sus zonas reales, para que la
/// pantalla no se vea vacía en una presentación sin red. Vive en memoria:
/// lo que se cree acá se pierde al cerrar la app, que para una demostración
/// es una ventaja.
class DemoCompaniesRepositoryImpl implements CompaniesRepository {
  DemoCompaniesRepositoryImpl();

  static const _idSeguridad = 'demo-empresa-seguridad';
  static const _idLimpieza = 'demo-empresa-limpieza';
  static const _idReciclaje = 'demo-empresa-reciclaje';

  late final List<Company> _companies = [
    Company(
      id: _idSeguridad,
      name: 'Seguridad Total SCZ',
      legalName: 'Seguridad Total Santa Cruz S.R.L.',
      type: CompanyType.security,
      verificationStatus: 'VERIFIED',
      taxId: '1028374016',
      contactPhone: '+591 3 3445566',
      contactEmail: 'contacto@seguridadtotalscz.bo',
    ),
    Company(
      id: _idLimpieza,
      name: 'EcoLimpia Bolivia',
      legalName: 'EcoLimpia Bolivia S.A.',
      type: CompanyType.cleaningTrash,
      verificationStatus: 'VERIFIED',
      taxId: '2039485127',
      contactPhone: '+591 3 3556677',
      contactEmail: 'contacto@ecolimpia.bo',
    ),
    Company(
      id: _idReciclaje,
      name: 'Recicladora Oriental',
      legalName: 'Recicladora Oriental S.R.L.',
      type: CompanyType.recyclingPlant,
      verificationStatus: 'VERIFIED',
      taxId: '3041596238',
      contactPhone: '+591 3 3667788',
      contactEmail: 'contacto@recicladoraoriental.bo',
    ),
  ];

  /// Los mismos rectángulos que siembra el servidor.
  late final List<CoverageZone> _zones = [
    CoverageZone(
      id: 'demo-zona-1',
      companyId: _idSeguridad,
      name: 'Casco Viejo y 1er Anillo',
      vertices: const [
        LatLng(-17.7925, -63.1925),
        LatLng(-17.7925, -63.1720),
        LatLng(-17.7762, -63.1720),
        LatLng(-17.7762, -63.1925),
      ],
      active: true,
    ),
    CoverageZone(
      id: 'demo-zona-2',
      companyId: _idLimpieza,
      name: 'Zona Norte: Equipetrol y Av. Banzer',
      vertices: const [
        LatLng(-17.7762, -63.2100),
        LatLng(-17.7762, -63.1600),
        LatLng(-17.7500, -63.1600),
        LatLng(-17.7500, -63.2100),
      ],
      active: true,
    ),
  ];

  int _counter = 0;

  int _indexOf(String id) {
    final i = _companies.indexWhere((c) => c.id == id);
    if (i < 0) {
      throw ApiException(statusCode: 404, message: 'Empresa no encontrada.');
    }
    return i;
  }

  @override
  Future<List<Company>> getAll() async => List.unmodifiable(_companies);

  @override
  Future<Company> getById(String id) async {
    final c = _companies[_indexOf(id)];
    return c.copyWith(
      coverageZones: _zones.where((z) => z.companyId == id).toList(),
    );
  }

  @override
  Future<Company> create(CompanyInput input) async {
    final taxId = input.taxId.replaceAll(RegExp(r'\D'), '');
    if (_companies.any((c) => c.taxId == taxId)) {
      throw ApiException(
        statusCode: 409,
        message: 'Ya existe una empresa con el identificador tributario $taxId.',
      );
    }

    final nueva = Company(
      id: 'demo-empresa-${++_counter}',
      name: input.displayName,
      legalName: input.legalName,
      type: input.type,
      verificationStatus: 'PENDING',
      taxId: taxId,
      contactPhone: input.contactPhone,
      contactEmail: input.contactEmail,
      logoUrl: input.logoUrl,
      createdAt: DateTime.now(),
    );
    _companies.add(nueva);
    return nueva;
  }

  @override
  Future<Company> verify(String id, {required bool approved}) async {
    final i = _indexOf(id);
    final actualizada = _companies[i].copyWith(
      verificationStatus: approved ? 'VERIFIED' : 'REJECTED',
    );
    _companies[i] = actualizada;
    return actualizada;
  }

  @override
  Future<List<CoverageZone>> getZones(
    String companyId, {
    bool includeInactive = false,
  }) async {
    return _zones
        .where((z) => z.companyId == companyId && (includeInactive || z.active))
        .toList();
  }

  @override
  Future<CoverageZone> createZone({
    required String companyId,
    required String name,
    required List<LatLng> vertices,
  }) async {
    _indexOf(companyId);
    final zona = CoverageZone(
      id: 'demo-zona-${++_counter}',
      companyId: companyId,
      name: name,
      vertices: vertices,
      active: true,
      createdAt: DateTime.now(),
    );
    _zones.add(zona);
    return zona;
  }

  @override
  Future<void> setZoneActive({
    required String companyId,
    required String zoneId,
    required bool active,
  }) async {
    final i = _zones.indexWhere((z) => z.id == zoneId);
    if (i < 0) {
      throw ApiException(statusCode: 404, message: 'Zona no encontrada.');
    }
    final z = _zones[i];
    _zones[i] = CoverageZone(
      id: z.id,
      companyId: z.companyId,
      name: z.name,
      vertices: z.vertices,
      active: active,
      createdAt: z.createdAt,
    );
  }
}
