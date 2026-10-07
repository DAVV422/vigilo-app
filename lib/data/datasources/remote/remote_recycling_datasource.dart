import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class RemoteRecyclingDatasource {
  RemoteRecyclingDatasource(this._client);

  final ApiClient _client;

  Future<List<dynamic>> getMaterials() async {
    try {
      final res = await _client.raw.get('/materials');
      return res.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> createListing(Map<String, dynamic> body) async {
    try {
      final res = await _client.raw.post('/recycling/listings', data: body);
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<List<dynamic>> findNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String? materialTypeId,
  }) async {
    try {
      final res = await _client.raw.get(
        '/recycling/listings/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radiusKm': radiusKm,
          if (materialTypeId != null) 'materialTypeId': materialTypeId,
        },
      );
      return res.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> getListingById(String id) async {
    try {
      final res = await _client.raw.get('/recycling/listings/$id');
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<List<dynamic>> getMine() async {
    try {
      final res = await _client.raw.get('/recycling/listings/mine');
      return res.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> claim(String listingId) async {
    try {
      final res = await _client.raw.post('/recycling/listings/$listingId/claim');
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<void> cancelListing(String listingId) async {
    try {
      await _client.raw.post('/recycling/listings/$listingId/cancel');
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<List<dynamic>> getMyPickups({String? filter}) async {
    try {
      final res = await _client.raw.get(
        '/recycling/pickups/my-pickups',
        queryParameters: {if (filter != null) 'filter': filter},
      );
      return res.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> getPickupById(String id) async {
    try {
      final res = await _client.raw.get('/recycling/pickups/$id');
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> updatePickupStatus({
    required String pickupId,
    required String status,
    String? cancellationReason,
  }) async {
    try {
      final res = await _client.raw.patch(
        '/recycling/pickups/$pickupId/status',
        data: {
          'status': status,
          if (cancellationReason != null) 'cancellationReason': cancellationReason,
        },
      );
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> completePickup({
    required String pickupId,
    required List<Map<String, dynamic>> results,
    required String paymentMethod,
    double? grossAmount,
    String? voucherMediaId,
    String? notes,
  }) async {
    try {
      final res = await _client.raw.post(
        '/recycling/pickups/$pickupId/complete',
        data: {
          'results': results,
          'paymentMethod': paymentMethod,
          if (grossAmount != null) 'grossAmount': grossAmount,
          if (voucherMediaId != null) 'voucherMediaId': voucherMediaId,
          if (notes != null) 'notes': notes,
        },
      );
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<Map<String, dynamic>> confirmPickup(String pickupId) async {
    try {
      final res = await _client.raw.post('/recycling/pickups/$pickupId/confirm');
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }

  Future<void> disputePickup({required String pickupId, required String reason}) async {
    try {
      await _client.raw.post(
        '/recycling/pickups/$pickupId/dispute',
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      throw _client.toApiException(e);
    }
  }
}
