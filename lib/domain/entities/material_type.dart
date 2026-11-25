import '../../core/network/json_parsing.dart';

/// Un precio por kilo con su vigencia.
///
/// `material_prices` es un histórico, no una fila que se edita: fijar un
/// precio inserta uno nuevo y marca el anterior como no vigente. Eso es lo
/// correcto —hay que poder reconstruir cuánto valía el PET el mes pasado—
/// y es la razón de que esta clase exista en vez de un simple `double`.
class MaterialPrice {
  const MaterialPrice({
    required this.id,
    required this.pricePerKg,
    required this.effectiveDate,
    required this.isCurrent,
    this.companyId,
    this.createdAt,
  });

  final String id;
  final double pricePerKg;
  final DateTime effectiveDate;
  final bool isCurrent;

  /// Nulo es el precio de plataforma. Los precios por empresa existen en el
  /// modelo pero todavía no se fijan desde ninguna pantalla.
  final String? companyId;
  final DateTime? createdAt;

  factory MaterialPrice.fromJson(Map<String, dynamic> json) => MaterialPrice(
        id: json['id'] as String,
        // Columna NUMERIC: puede llegar como texto.
        pricePerKg: toDouble(json['pricePerKg'], field: 'pricePerKg'),
        effectiveDate: DateTime.parse(json['effectiveDate'] as String),
        isCurrent: json['isCurrent'] as bool? ?? false,
        companyId: json['companyId'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}

class MaterialType {
  MaterialType({
    required this.id,
    required this.name,
    required this.category,
    required this.unitOfMeasure,
    required this.pointsPerKg,
    required this.minPayoutThreshold,
    required this.co2FactorPerKg,
    this.currentPricePerKg = 0,
    this.isActive = true,
    this.priceHistory = const [],
  });

  final String id;
  final String name;
  final String category;
  final String unitOfMeasure;

  /// Puntos que gana el ciudadano por kilo entregado.
  final double pointsPerKg;
  final double minPayoutThreshold;
  final double co2FactorPerKg;

  /// Precio de plataforma vigente, por kilo. Cero cuando nunca se fijó uno.
  final double currentPricePerKg;

  /// Un material inactivo no se ofrece al publicar, pero no rompe las
  /// publicaciones abiertas que ya lo usan.
  final bool isActive;

  /// Solo lo trae `GET /materials/:id`; en la lista viene vacío.
  final List<MaterialPrice> priceHistory;

  factory MaterialType.fromJson(Map<String, dynamic> json) {
    return MaterialType(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'OTHER',
      unitOfMeasure: json['unitOfMeasure'] as String? ?? 'GRAMS',
      pointsPerKg: toDouble(json['pointsPerKg'], field: 'pointsPerKg'),
      minPayoutThreshold: toDoubleOrNull(json['minPayoutThreshold']) ?? 0,
      co2FactorPerKg: toDoubleOrNull(json['co2FactorPerKg']) ?? 0,
      currentPricePerKg: toDoubleOrNull(json['currentPricePerKg']) ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      priceHistory: ((json['priceHistory'] as List<dynamic>?) ?? const [])
          .map((p) => MaterialPrice.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  MaterialType copyWith({
    double? pointsPerKg,
    double? minPayoutThreshold,
    double? co2FactorPerKg,
    double? currentPricePerKg,
    bool? isActive,
    List<MaterialPrice>? priceHistory,
  }) {
    return MaterialType(
      id: id,
      name: name,
      category: category,
      unitOfMeasure: unitOfMeasure,
      pointsPerKg: pointsPerKg ?? this.pointsPerKg,
      minPayoutThreshold: minPayoutThreshold ?? this.minPayoutThreshold,
      co2FactorPerKg: co2FactorPerKg ?? this.co2FactorPerKg,
      currentPricePerKg: currentPricePerKg ?? this.currentPricePerKg,
      isActive: isActive ?? this.isActive,
      priceHistory: priceHistory ?? this.priceHistory,
    );
  }
}
