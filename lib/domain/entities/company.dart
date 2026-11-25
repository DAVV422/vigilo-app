import 'coverage_zone.dart';

/// Las cuatro clases de empresa que define el backend.
enum CompanyType { security, cleaningTrash, recyclingPlant, municipality }

extension CompanyTypeX on CompanyType {
  String get wire => switch (this) {
        CompanyType.security => 'SECURITY',
        CompanyType.cleaningTrash => 'CLEANING_TRASH',
        CompanyType.recyclingPlant => 'RECYCLING_PLANT',
        CompanyType.municipality => 'MUNICIPALITY',
      };

  String get label => switch (this) {
        CompanyType.security => 'Seguridad',
        CompanyType.cleaningTrash => 'Limpieza y basura',
        CompanyType.recyclingPlant => 'Planta de reciclaje',
        CompanyType.municipality => 'Municipio',
      };

  /// Qué incidentes termina atendiendo. Importa al darla de alta: el tipo
  /// decide qué se le asigna automáticamente después.
  String get help => switch (this) {
        CompanyType.security => 'Robos, vandalismo y hechos de inseguridad.',
        CompanyType.cleaningTrash => 'Basura acumulada y limpieza de la vía pública.',
        CompanyType.recyclingPlant => 'Recepción y procesamiento de material reciclable.',
        CompanyType.municipality => 'Alumbrado, baches y servicios municipales.',
      };

  static CompanyType? fromWire(String? wire) => switch (wire) {
        'SECURITY' => CompanyType.security,
        'CLEANING_TRASH' => CompanyType.cleaningTrash,
        'RECYCLING_PLANT' => CompanyType.recyclingPlant,
        'MUNICIPALITY' => CompanyType.municipality,
        _ => null,
      };
}

/// Una empresa de la plataforma.
///
/// Los campos opcionales son los que solo trae la API real. El camino
/// heredado de JSON local construye esta misma clase con `id` y `name` y
/// nada más, y se eligió extenderla en vez de crear una segunda `Company`
/// para no terminar con dos tipos que significan lo mismo.
class Company {
  Company({
    required this.id,
    required this.name,
    this.logoUrl,
    this.legalName,
    this.type,
    this.verificationStatus,
    this.taxId,
    this.contactPhone,
    this.contactEmail,
    this.coverageZones = const [],
    this.createdAt,
  });

  final String id;

  /// Nombre comercial (`displayName` en la API). Es el que se muestra.
  final String name;
  final String? logoUrl;

  final String? legalName;
  final CompanyType? type;

  /// `PENDING` · `VERIFIED` · `REJECTED`. Texto y no enum para que un estado
  /// nuevo del servidor se muestre en vez de romper la pantalla.
  final String? verificationStatus;
  final String? taxId;
  final String? contactPhone;
  final String? contactEmail;
  final List<CoverageZone> coverageZones;
  final DateTime? createdAt;

  bool get isPending => verificationStatus == 'PENDING';
  bool get isVerified => verificationStatus == 'VERIFIED';

  String get verificationLabel => switch (verificationStatus) {
        'VERIFIED' => 'Verificada',
        'PENDING' => 'Pendiente',
        'REJECTED' => 'Rechazada',
        _ => verificationStatus ?? 'Sin estado',
      };

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String,
      name: (json['displayName'] ?? json['name']) as String? ?? 'Empresa',
      logoUrl: json['logoUrl'] as String?,
      legalName: json['legalName'] as String?,
      type: CompanyTypeX.fromWire(json['type'] as String?),
      verificationStatus: json['verificationStatus'] as String?,
      taxId: json['taxId'] as String?,
      contactPhone: json['contactPhone'] as String?,
      contactEmail: json['contactEmail'] as String?,
      coverageZones: ((json['coverageZones'] as List<dynamic>?) ?? const [])
          .map((z) => CoverageZone.fromJson(z as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Company copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? verificationStatus,
    List<CoverageZone>? coverageZones,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      legalName: legalName,
      type: type,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      taxId: taxId,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
      coverageZones: coverageZones ?? this.coverageZones,
      createdAt: createdAt,
    );
  }
}
