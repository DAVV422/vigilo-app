import '../../core/network/json_parsing.dart';
class MaterialImpactBreakdown {
  final String materialName;
  final String category;
  final double totalWeightKg;

  MaterialImpactBreakdown({
    required this.materialName,
    required this.category,
    required this.totalWeightKg,
  });

  factory MaterialImpactBreakdown.fromJson(Map<String, dynamic> json) {
    return MaterialImpactBreakdown(
      materialName: json['materialName'] as String,
      category: json['category'] as String,
      totalWeightKg: toDouble(json['totalWeightKg'], field: 'totalWeightKg'),
    );
  }
}

class PlatformImpact {
  final double totalWeightKgRecycled;
  final double co2AvoidedKg;
  final int pointsIssued;
  final int pointsRedeemed;
  final int activeRecyclers;
  final int listingsPublished;
  final int listingsCompleted;
  final double retrievalRatePercent;
  final List<MaterialImpactBreakdown> materialBreakdown;

  PlatformImpact({
    required this.totalWeightKgRecycled,
    required this.co2AvoidedKg,
    required this.pointsIssued,
    required this.pointsRedeemed,
    required this.activeRecyclers,
    required this.listingsPublished,
    required this.listingsCompleted,
    required this.retrievalRatePercent,
    required this.materialBreakdown,
  });

  factory PlatformImpact.fromJson(Map<String, dynamic> json) {
    return PlatformImpact(
      totalWeightKgRecycled: toDouble(json['totalWeightKgRecycled'], field: 'totalWeightKgRecycled'),
      co2AvoidedKg: toDouble(json['co2AvoidedKg'], field: 'co2AvoidedKg'),
      pointsIssued: json['pointsIssued'] as int,
      pointsRedeemed: json['pointsRedeemed'] as int,
      activeRecyclers: json['activeRecyclers'] as int,
      listingsPublished: json['listingsPublished'] as int,
      listingsCompleted: json['listingsCompleted'] as int,
      retrievalRatePercent: toDouble(json['retrievalRatePercent'], field: 'retrievalRatePercent'),
      materialBreakdown: (json['materialBreakdown'] as List<dynamic>)
          .map((m) => MaterialImpactBreakdown.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
