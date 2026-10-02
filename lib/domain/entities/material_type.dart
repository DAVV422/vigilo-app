class MaterialType {
  final String id;
  final String name;
  final String category;
  final String unitOfMeasure;
  final double pointsPerKg;
  final double minPayoutThreshold;
  final double co2FactorPerKg;

  MaterialType({
    required this.id,
    required this.name,
    required this.category,
    required this.unitOfMeasure,
    required this.pointsPerKg,
    required this.minPayoutThreshold,
    required this.co2FactorPerKg,
  });

  factory MaterialType.fromJson(Map<String, dynamic> json) {
    return MaterialType(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'OTHER',
      unitOfMeasure: json['unitOfMeasure'] as String? ?? 'GRAMS',
      pointsPerKg: (json['pointsPerKg'] as num).toDouble(),
      minPayoutThreshold: (json['minPayoutThreshold'] as num?)?.toDouble() ?? 0,
      co2FactorPerKg: (json['co2FactorPerKg'] as num?)?.toDouble() ?? 0,
    );
  }
}
