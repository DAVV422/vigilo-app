import 'package:collection/collection.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/api_exception.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/material_type.dart';
import '../../domain/entities/recycling_listing.dart';
import '../../domain/entities/recycling_pickup.dart';
import '../../domain/repositories/recycling_repository.dart';
import '../demo/demo_state.dart';

const _log = AppLogger('DemoRecycling');

/// Marketplace de reciclaje simulado en memoria (ver [DemoState]). No hay
/// geofuzzing ni radios reales de búsqueda más allá de un filtro simple por
/// distancia — es una demo, no una reimplementación del backend.
class DemoRecyclingRepositoryImpl implements RecyclingRepository {
  DemoRecyclingRepositoryImpl(this._state);

  final DemoState _state;

  String get _currentUserId {
    final user = _state.currentUser;
    if (user == null) throw ApiException(statusCode: 401, message: 'No hay sesión activa.');
    return user.id;
  }

  RecyclingListing _findListing(String id) {
    return _state.listings.firstWhere(
      (l) => l.id == id,
      orElse: () => throw ApiException(statusCode: 404, message: 'Publicación no encontrada.'),
    );
  }

  void _replaceListing(RecyclingListing updated) {
    final index = _state.listings.indexWhere((l) => l.id == updated.id);
    if (index != -1) _state.listings[index] = updated;
  }

  RecyclingPickup _findPickup(String id) {
    final pickup = _state.pickups[id];
    if (pickup == null) throw ApiException(statusCode: 404, message: 'Recojo no encontrado.');
    return pickup;
  }

  @override
  Future<List<MaterialType>> getMaterials() async => _state.materials;

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
    final user = _state.currentUser;
    if (user == null) throw ApiException(statusCode: 401, message: 'No hay sesión activa.');

    final listing = RecyclingListing(
      id: _state.newId('demo-listing'),
      status: 'PENDING',
      address: address,
      latitude: latitude,
      longitude: longitude,
      isExactLocation: true,
      notes: notes,
      photoMediaId: photoMediaId,
      citizen: RecyclingListingCitizen(
        id: user.id,
        firstName: user.name,
        lastName: user.lastName,
        phone: user.phone,
        trustScore: user.trustScore,
      ),
      materials: materials
          .map((m) => RecyclingListingMaterial(
                materialId: m.materialTypeId,
                materialName: _state.materials.where((mt) => mt.id == m.materialTypeId).firstOrNull?.name,
                estimatedWeightGrams: m.estimatedWeightGrams,
              ))
          .toList(),
      availabilityWindows: availabilityWindows,
      createdAt: DateTime.now(),
    );

    _state.listings.insert(0, listing);
    _log.info('Publicación demo creada: ${listing.id}');
    return listing;
  }

  @override
  Future<List<RecyclingListing>> getNearbyListings({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String? materialTypeId,
  }) async {
    return _state.listings.where((l) {
      if (l.status != 'PENDING') return false;
      if (materialTypeId != null && !l.materials.any((m) => m.materialId == materialTypeId)) return false;
      final distanceMeters = Geolocator.distanceBetween(latitude, longitude, l.latitude, l.longitude);
      return distanceMeters <= radiusKm * 1000;
    }).toList();
  }

  @override
  Future<RecyclingListing> getListingById(String id) async => _findListing(id);

  @override
  Future<List<RecyclingListing>> getMyListings() async {
    final userId = _currentUserId;
    final mine = _state.listings.where((l) => l.citizen?.id == userId).toList();
    mine.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }

  @override
  Future<RecyclingPickup> getPickupById(String pickupId) async => _findPickup(pickupId);

  @override
  Future<RecyclingListing> claimListing(String listingId) async {
    final listing = _findListing(listingId);
    if (listing.status != 'PENDING') {
      throw ApiException(statusCode: 409, message: 'Esta publicación ya no está disponible.');
    }
    if (listing.citizen?.id == _currentUserId) {
      throw ApiException(statusCode: 403, message: 'No puedes reclamar tu propia publicación de reciclaje.');
    }

    final pickup = RecyclingPickup(
      id: _state.newId('demo-pickup'),
      status: 'CLAIMED',
      claimedAt: DateTime.now(),
      listingId: listing.id,
      listingAddress: listing.address,
      citizenId: listing.citizen?.id,
      citizenName: '${listing.citizen?.firstName ?? ''} ${listing.citizen?.lastName ?? ''}'.trim(),
      citizenPhone: listing.citizen?.phone,
      citizenTrustScore: listing.citizen?.trustScore,
      listingMaterials: listing.materials,
    );
    _state.pickups[pickup.id] = pickup;

    final updatedListing = _copyListing(
      listing,
      status: 'CLAIMED',
      pickupId: pickup.id,
      pickupRecyclerId: _currentUserId,
      pickupStatus: pickup.status,
    );
    _replaceListing(updatedListing);
    _log.info('Publicación demo reclamada: $listingId por $_currentUserId');
    return updatedListing;
  }

  @override
  Future<void> cancelListing(String listingId) async {
    final listing = _findListing(listingId);
    if (listing.citizen?.id != _currentUserId) {
      throw ApiException(statusCode: 403, message: 'No puedes cancelar una publicación que no es tuya.');
    }
    _replaceListing(_copyListing(listing, status: 'CANCELLED'));
  }

  RecyclingListing _copyListing(
    RecyclingListing listing, {
    String? status,
    Object? pickupId = _unset,
    Object? pickupRecyclerId = _unset,
    Object? pickupStatus = _unset,
    Object? pickupCompensationStatus = _unset,
  }) {
    return RecyclingListing(
      id: listing.id,
      status: status ?? listing.status,
      address: listing.address,
      approximateAddress: listing.approximateAddress,
      latitude: listing.latitude,
      longitude: listing.longitude,
      isExactLocation: listing.isExactLocation,
      notes: listing.notes,
      photoMediaId: listing.photoMediaId,
      citizen: listing.citizen,
      pickupId: pickupId == _unset ? listing.pickupId : pickupId as String?,
      pickupRecyclerId: pickupRecyclerId == _unset ? listing.pickupRecyclerId : pickupRecyclerId as String?,
      pickupStatus: pickupStatus == _unset ? listing.pickupStatus : pickupStatus as String?,
      pickupCompensationStatus: pickupCompensationStatus == _unset
          ? listing.pickupCompensationStatus
          : pickupCompensationStatus as String?,
      materials: listing.materials,
      availabilityWindows: listing.availabilityWindows,
      createdAt: listing.createdAt,
    );
  }

  @override
  Future<List<RecyclingPickup>> getMyPickups({String? filter}) async {
    final mine = _state.pickups.values.where((p) => p.listingId != null).where((p) {
      final listing = _state.listings.where((l) => l.id == p.listingId).firstOrNull;
      return listing?.pickupRecyclerId == _currentUserId;
    });

    if (filter == 'active') {
      return mine.where((p) => p.status != 'COMPLETED' && p.status != 'CANCELLED').toList();
    }
    return mine.toList();
  }

  RecyclingPickup _withPickupStatus(RecyclingPickup pickup, String status, {DateTime? arrivedAt}) {
    return RecyclingPickup(
      id: pickup.id,
      status: status,
      claimedAt: pickup.claimedAt,
      arrivedAt: arrivedAt ?? pickup.arrivedAt,
      completedAt: pickup.completedAt,
      cancelledAt: status == 'CANCELLED' ? DateTime.now() : pickup.cancelledAt,
      cancellationReason: pickup.cancellationReason,
      notes: pickup.notes,
      listingId: pickup.listingId,
      listingAddress: pickup.listingAddress,
      citizenId: pickup.citizenId,
      citizenName: pickup.citizenName,
      citizenPhone: pickup.citizenPhone,
      citizenTrustScore: pickup.citizenTrustScore,
      results: pickup.results,
      compensation: pickup.compensation,
      listingMaterials: pickup.listingMaterials,
    );
  }

  @override
  Future<void> markEnRoute(String pickupId) async {
    final pickup = _findPickup(pickupId);
    _state.pickups[pickupId] = _withPickupStatus(pickup, 'EN_ROUTE');
    _updateLinkedListingPickupStatus(pickup.listingId, 'EN_ROUTE');
  }

  @override
  Future<void> markArrived(String pickupId) async {
    final pickup = _findPickup(pickupId);
    _state.pickups[pickupId] = _withPickupStatus(pickup, 'ARRIVED', arrivedAt: DateTime.now());
    _updateLinkedListingPickupStatus(pickup.listingId, 'ARRIVED');
  }

  void _updateLinkedListingPickupStatus(String? listingId, String pickupStatus) {
    if (listingId == null) return;
    final listing = _state.listings.where((l) => l.id == listingId).firstOrNull;
    if (listing != null) _replaceListing(_copyListing(listing, pickupStatus: pickupStatus));
  }

  @override
  Future<void> cancelPickup({required String pickupId, String? reason}) async {
    final pickup = _findPickup(pickupId);
    _state.pickups[pickupId] = _withPickupStatus(pickup, 'CANCELLED');
    if (pickup.listingId != null) {
      final listing = _state.listings.where((l) => l.id == pickup.listingId).firstOrNull;
      if (listing != null) {
        _replaceListing(_copyListing(
          listing,
          status: 'PENDING',
          pickupId: null,
          pickupRecyclerId: null,
          pickupStatus: null,
        ));
      }
    }
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
    final pickup = _findPickup(pickupId);

    final pickupResults = results.map((r) {
      final material = _state.materials.where((m) => m.id == r.materialTypeId).firstOrNull;
      final points = material == null ? 0 : ((r.actualWeightGrams / 1000) * material.pointsPerKg).round();
      return RecyclingPickupResult(
        materialId: r.materialTypeId,
        materialName: material?.name,
        actualWeightGrams: r.actualWeightGrams,
        pointsAwarded: points,
      );
    }).toList();

    final totalPoints = pickupResults.fold<int>(0, (sum, r) => sum + r.pointsAwarded);

    final compensation = PickupCompensation(
      id: _state.newId('demo-compensation'),
      paymentMethod: paymentMethod,
      grossAmount: grossAmount ?? 0,
      voucherMediaId: voucherMediaId,
      status: 'PENDING_CONFIRMATION',
    );

    final completed = RecyclingPickup(
      id: pickup.id,
      status: 'COMPLETED',
      claimedAt: pickup.claimedAt,
      arrivedAt: pickup.arrivedAt,
      completedAt: DateTime.now(),
      notes: notes ?? pickup.notes,
      listingId: pickup.listingId,
      listingAddress: pickup.listingAddress,
      citizenId: pickup.citizenId,
      citizenName: pickup.citizenName,
      citizenPhone: pickup.citizenPhone,
      citizenTrustScore: pickup.citizenTrustScore,
      results: pickupResults,
      compensation: compensation,
      listingMaterials: pickup.listingMaterials,
    );
    _state.pickups[pickupId] = completed;

    if (pickup.listingId != null) {
      final listing = _state.listings.where((l) => l.id == pickup.listingId).firstOrNull;
      if (listing != null) {
        _replaceListing(_copyListing(
          listing,
          status: 'COMPLETED',
          pickupStatus: 'COMPLETED',
          pickupCompensationStatus: 'PENDING_CONFIRMATION',
        ));
      }
    }

    if (pickup.citizenId != null) {
      _state.notifications.insert(
        0,
        AppNotification(
          id: _state.newId('demo-notif'),
          type: 'PICKUP_PENDING_CONFIRMATION',
          title: 'Pesaje registrado, confirma tu recojo',
          body: 'El recolector registró el pesaje de tu material (+$totalPoints puntos estimados). '
              'Revisa el detalle en "Mis publicaciones" y confirma o disputa el recojo.',
          data: {'pickupId': pickupId, 'totalPointsCalculated': totalPoints},
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );
    }

    return CompletePickupResult(
      pickupId: pickup.id,
      status: 'COMPLETED',
      totalPointsCalculated: totalPoints,
      grossAmount: grossAmount ?? 0,
      paymentMethod: paymentMethod,
    );
  }

  @override
  Future<({int pointsAwarded, int newPointsBalance})> confirmPickup(String pickupId) async {
    final pickup = _findPickup(pickupId);
    final totalPoints = pickup.results.fold<int>(0, (sum, r) => sum + r.pointsAwarded);

    _state.creditPoints(
      delta: totalPoints,
      reason: 'Recojo de reciclaje confirmado',
      referenceType: 'RECYCLING_PICKUP',
      referenceId: pickupId,
    );

    _setCompensationStatus(pickup, 'CONFIRMED');

    return (pointsAwarded: totalPoints, newPointsBalance: _state.currentUser?.points ?? 0);
  }

  @override
  Future<void> disputePickup({required String pickupId, required String reason}) async {
    final pickup = _findPickup(pickupId);
    _setCompensationStatus(pickup, 'DISPUTED');
  }

  void _setCompensationStatus(RecyclingPickup pickup, String status) {
    if (pickup.compensation != null) {
      _state.pickups[pickup.id] = RecyclingPickup(
        id: pickup.id,
        status: pickup.status,
        claimedAt: pickup.claimedAt,
        arrivedAt: pickup.arrivedAt,
        completedAt: pickup.completedAt,
        notes: pickup.notes,
        listingId: pickup.listingId,
        listingAddress: pickup.listingAddress,
        citizenId: pickup.citizenId,
        citizenName: pickup.citizenName,
        citizenPhone: pickup.citizenPhone,
        citizenTrustScore: pickup.citizenTrustScore,
        results: pickup.results,
        listingMaterials: pickup.listingMaterials,
        compensation: PickupCompensation(
          id: pickup.compensation!.id,
          paymentMethod: pickup.compensation!.paymentMethod,
          grossAmount: pickup.compensation!.grossAmount,
          voucherMediaId: pickup.compensation!.voucherMediaId,
          status: status,
        ),
      );
    }

    if (pickup.listingId != null) {
      final listing = _state.listings.where((l) => l.id == pickup.listingId).firstOrNull;
      if (listing != null) {
        _replaceListing(_copyListing(listing, pickupCompensationStatus: status));
      }
    }
  }
}

/// Centinela para distinguir "no pasaron este parámetro" de "lo pasaron
/// explícitamente como null" en `_copyListing` (todos sus campos opcionales
/// son nullable de por sí).
const Object _unset = Object();
