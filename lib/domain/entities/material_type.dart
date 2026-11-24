import '../../core/network/json_parsing.dart';
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
      pointsPerKg: toDouble(json['pointsPerKg'], field: 'pointsPerKg'),
      minPayoutThreshold: toDoubleOrNull(json['minPayoutThreshold']) ?? 0,
      co2FactorPerKg: toDoubleOrNull(json['co2FactorPerKg']) ?? 0,
    );
  }
}
