import 'recycling_listing.dart' show RecyclingListingMaterial;
import '../../core/network/json_parsing.dart';

class RecyclingPickupResult {
  final String materialId;
  final String? materialName;
  final double actualWeightGrams;
  final int pointsAwarded;

  RecyclingPickupResult({
    required this.materialId,
    this.materialName,
    required this.actualWeightGrams,
    required this.pointsAwarded,
  });

  factory RecyclingPickupResult.fromJson(Map<String, dynamic> json) {
    return RecyclingPickupResult(
      materialId: json['materialId'] as String,
      materialName: json['materialName'] as String?,
      actualWeightGrams: (json['actualWeightGrams'] as num).toDouble(),
      pointsAwarded: (json['pointsAwarded'] as num).toInt(),
    );
  }
}

class PickupCompensation {
  final String id;
  final String paymentMethod;
  final double grossAmount;
  final String? voucherMediaId;
  final String status; // PENDING_CONFIRMATION | CONFIRMED | DISPUTED

  PickupCompensation({
    required this.id,
    required this.paymentMethod,
    required this.grossAmount,
    this.voucherMediaId,
    required this.status,
  });

  factory PickupCompensation.fromJson(Map<String, dynamic> json) {
    return PickupCompensation(
      id: json['id'] as String,
      paymentMethod: json['paymentMethod'] as String,
      grossAmount: (json['grossAmount'] as num).toDouble(),
      voucherMediaId: json['voucherMediaId'] as String?,
      status: json['status'] as String,
    );
  }
}

/// Recojo operativo de campo asociado a una [RecyclingListing] reclamada.
class RecyclingPickup {
  final String id;
  final String status; // CLAIMED | EN_ROUTE | ARRIVED | COMPLETED | CANCELLED
  final DateTime? claimedAt;
  final DateTime? arrivedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? notes;
  final String? listingId;
  final String? listingAddress;
  final String? citizenId;
  final String? citizenName;
  final String? citizenPhone;
  final double? citizenTrustScore;
  final List<RecyclingPickupResult> results;
  final PickupCompensation? compensation;
  /// Materiales/pesos *estimados* por el ciudadano al publicar — es la
  /// referencia que el recolector usa para saber qué pesar al completar.
  final List<RecyclingListingMaterial> listingMaterials;

  RecyclingPickup({
    required this.id,
    required this.status,
    this.claimedAt,
    this.arrivedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.notes,
    this.listingId,
    this.listingAddress,
    this.citizenId,
    this.citizenName,
    this.citizenPhone,
    this.citizenTrustScore,
    this.results = const [],
    this.compensation,
    this.listingMaterials = const [],
  });

  factory RecyclingPickup.fromJson(Map<String, dynamic> json) {
    final listing = json['listing'] as Map<String, dynamic>?;
    final citizen = listing?['citizen'] as Map<String, dynamic>?;
    return RecyclingPickup(
      id: json['id'] as String,
      status: json['status'] as String,
      claimedAt: json['claimedAt'] != null ? DateTime.parse(json['claimedAt'] as String) : null,
      arrivedAt: json['arrivedAt'] != null ? DateTime.parse(json['arrivedAt'] as String) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt'] as String) : null,
      cancellationReason: json['cancellationReason'] as String?,
      notes: json['notes'] as String?,
      listingId: listing?['id'] as String?,
      listingAddress: listing?['address'] as String?,
      citizenId: citizen?['id'] as String?,
      citizenName: citizen?['name'] as String?,
      citizenPhone: citizen?['phone'] as String?,
      citizenTrustScore: toDoubleOrNull(citizen?['trustScore']),
      results: ((json['results'] as List<dynamic>?) ?? [])
          .map((r) => RecyclingPickupResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      compensation: json['compensation'] != null
          ? PickupCompensation.fromJson(json['compensation'] as Map<String, dynamic>)
          : null,
      listingMaterials: ((listing?['materials'] as List<dynamic>?) ?? [])
          .map((m) => RecyclingListingMaterial.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Resultado de registrar el pesaje (`POST /recycling/pickups/:id/complete`).
/// Tiene una forma distinta a [RecyclingPickup] porque el endpoint devuelve
/// un resumen de la liquidación recién calculada, no el recojo completo.
class CompletePickupResult {
  final String pickupId;
  final String status;
  final int totalPointsCalculated;
  final double grossAmount;
  final String paymentMethod;

  CompletePickupResult({
    required this.pickupId,
    required this.status,
    required this.totalPointsCalculated,
    required this.grossAmount,
    required this.paymentMethod,
  });

  factory CompletePickupResult.fromJson(Map<String, dynamic> json) {
    return CompletePickupResult(
      pickupId: json['pickupId'] as String,
      status: json['status'] as String,
      totalPointsCalculated: (json['totalPointsCalculated'] as num).toInt(),
      grossAmount: (json['grossAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] as String,
    );
  }
}
