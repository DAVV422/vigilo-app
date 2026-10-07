import '../../domain/entities/material_type.dart';
import '../../domain/entities/recycling_listing.dart';
import '../../domain/entities/recycling_pickup.dart';
import '../../domain/repositories/recycling_repository.dart';
import '../datasources/remote/remote_recycling_datasource.dart';

class RemoteRecyclingRepositoryImpl implements RecyclingRepository {
  RemoteRecyclingRepositoryImpl(this._datasource);

  final RemoteRecyclingDatasource _datasource;

  @override
  Future<List<MaterialType>> getMaterials() async {
    final raw = await _datasource.getMaterials();
    return raw.map((json) => MaterialType.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<RecyclingListing> createListing({
    required String address,
    required double latitude,
    required double longitude,
    String? notes,
    String? photoMediaId,
    required List<MaterialWeightInput> materials,
    required List<RecyclingAvailabilityWindow> availabilityWindows,
  }) async {
    final json = await _datasource.createListing({
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (photoMediaId != null) 'photoMediaId': photoMediaId,
      'materials': materials
          .map((m) => {
                'materialTypeId': m.materialTypeId,
                'estimatedWeightGrams': m.estimatedWeightGrams,
              })
          .toList(),
      'availabilityWindows': availabilityWindows.map((w) => w.toJson()).toList(),
    });
    return RecyclingListing.fromJson(json);
  }

  @override
  Future<List<RecyclingListing>> getNearbyListings({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String? materialTypeId,
  }) async {
    final raw = await _datasource.findNearby(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      materialTypeId: materialTypeId,
    );
    return raw.map((json) => RecyclingListing.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<RecyclingListing> getListingById(String id) async {
    final json = await _datasource.getListingById(id);
    return RecyclingListing.fromJson(json);
  }

  @override
  Future<List<RecyclingListing>> getMyListings() async {
    final raw = await _datasource.getMine();
    return raw.map((json) => RecyclingListing.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<RecyclingListing> claimListing(String listingId) async {
    final json = await _datasource.claim(listingId);
    return RecyclingListing.fromJson(json);
  }

  @override
  Future<void> cancelListing(String listingId) => _datasource.cancelListing(listingId);

  @override
  Future<List<RecyclingPickup>> getMyPickups({String? filter}) async {
    final raw = await _datasource.getMyPickups(filter: filter);
    return raw.map((json) => RecyclingPickup.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<RecyclingPickup> getPickupById(String pickupId) async {
    final json = await _datasource.getPickupById(pickupId);
    return RecyclingPickup.fromJson(json);
  }

  @override
  Future<void> markEnRoute(String pickupId) async {
    await _datasource.updatePickupStatus(pickupId: pickupId, status: 'EN_ROUTE');
  }

  @override
  Future<void> markArrived(String pickupId) async {
    await _datasource.updatePickupStatus(pickupId: pickupId, status: 'ARRIVED');
  }

  @override
  Future<void> cancelPickup({required String pickupId, String? reason}) async {
    await _datasource.updatePickupStatus(
      pickupId: pickupId,
      status: 'CANCELLED',
      cancellationReason: reason,
    );
  }

  @override
  Future<CompletePickupResult> completePickup({
    required String pickupId,
    required List<ActualWeightInput> results,
    required String paymentMethod,
    double? grossAmount,
    String? voucherMediaId,
    String? notes,
  }) async {
    final json = await _datasource.completePickup(
      pickupId: pickupId,
      results: results
          .map((r) => {
                'materialTypeId': r.materialTypeId,
                'actualWeightGrams': r.actualWeightGrams,
              })
          .toList(),
      paymentMethod: paymentMethod,
      grossAmount: grossAmount,
      voucherMediaId: voucherMediaId,
      notes: notes,
    );
    return CompletePickupResult.fromJson(json);
  }

  @override
  Future<({int pointsAwarded, int newPointsBalance})> confirmPickup(String pickupId) async {
    final json = await _datasource.confirmPickup(pickupId);
    return (
      pointsAwarded: (json['pointsAwarded'] as num).toInt(),
      newPointsBalance: (json['newPointsBalance'] as num).toInt(),
    );
  }

  @override
  Future<void> disputePickup({required String pickupId, required String reason}) {
    return _datasource.disputePickup(pickupId: pickupId, reason: reason);
  }
}
