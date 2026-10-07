import '../entities/material_type.dart';
import '../entities/recycling_listing.dart';
import '../entities/recycling_pickup.dart';

class MaterialWeightInput {
  final String materialTypeId;
  final double estimatedWeightGrams;
  MaterialWeightInput({required this.materialTypeId, required this.estimatedWeightGrams});
}

class ActualWeightInput {
  final String materialTypeId;
  final double actualWeightGrams;
  ActualWeightInput({required this.materialTypeId, required this.actualWeightGrams});
}

/// Marketplace de reciclaje: publicación -> descubrimiento -> reclamo ->
/// pesaje -> confirmación/disputa. Ver docs/flujos.md (sección 3 en la
/// planificación original) y backend/docs/03-flujos-sistema.md para el
/// detalle de cada transición de estado.
abstract class RecyclingRepository {
  Future<List<MaterialType>> getMaterials();

  Future<RecyclingListing> createListing({
    required String address,
    required double latitude,
    required double longitude,
    String? notes,
    String? photoMediaId,
    required List<MaterialWeightInput> materials,
    required List<RecyclingAvailabilityWindow> availabilityWindows,
  });

  Future<List<RecyclingListing>> getNearbyListings({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String? materialTypeId,
  });

  Future<RecyclingListing> getListingById(String id);

  /// Publicaciones propias del ciudadano (cualquier estado) — es la única
  /// forma de ubicar cuáles ya están `COMPLETED` y esperando su
  /// confirmación, sin depender únicamente de la notificación push.
  Future<List<RecyclingListing>> getMyListings();

  Future<RecyclingListing> claimListing(String listingId);

  Future<void> cancelListing(String listingId);

  Future<List<RecyclingPickup>> getMyPickups({String? filter});

  Future<RecyclingPickup> getPickupById(String pickupId);

  Future<void> markEnRoute(String pickupId);

  Future<void> markArrived(String pickupId);

  Future<void> cancelPickup({required String pickupId, String? reason});

  Future<CompletePickupResult> completePickup({
    required String pickupId,
    required List<ActualWeightInput> results,
    required String paymentMethod,
    double? grossAmount,
    String? voucherMediaId,
    String? notes,
  });

  /// Devuelve los puntos acreditados y el nuevo saldo total del ciudadano.
  Future<({int pointsAwarded, int newPointsBalance})> confirmPickup(String pickupId);

  Future<void> disputePickup({required String pickupId, required String reason});
}
