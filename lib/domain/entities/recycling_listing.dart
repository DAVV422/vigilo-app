class RecyclingListingMaterial {
  final String materialId;
  final String? materialName;
  final String? category;
  final double estimatedWeightGrams;

  RecyclingListingMaterial({
    required this.materialId,
    this.materialName,
    this.category,
    required this.estimatedWeightGrams,
  });

  factory RecyclingListingMaterial.fromJson(Map<String, dynamic> json) {
    return RecyclingListingMaterial(
      materialId: json['materialId'] as String,
      materialName: json['materialName'] as String?,
      category: json['category'] as String?,
      estimatedWeightGrams: (json['estimatedWeightGrams'] as num).toDouble(),
    );
  }
}

class RecyclingAvailabilityWindow {
  final int dayOfWeek; // 0 (domingo) .. 6 (sábado), ISO-like usado por el backend
  final String startTime; // 'HH:mm:ss'
  final String endTime;

  RecyclingAvailabilityWindow({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory RecyclingAvailabilityWindow.fromJson(Map<String, dynamic> json) {
    return RecyclingAvailabilityWindow(
      dayOfWeek: json['dayOfWeek'] as int,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'endTime': endTime,
  };
}

class RecyclingListingCitizen {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final double? trustScore;

  RecyclingListingCitizen({
    required this.id,
    this.firstName,
    this.lastName,
    this.phone,
    this.trustScore,
  });

  factory RecyclingListingCitizen.fromJson(Map<String, dynamic> json) {
    return RecyclingListingCitizen(
      id: json['id'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phone: json['phone'] as String?,
      trustScore: (json['trustScore'] as num?)?.toDouble(),
    );
  }
}

/// Publicación de material reciclable. Mientras está `PENDING` (abierta, sin
/// reclamar), el backend aplica geofuzzing: [latitude]/[longitude] son
/// aproximados y [address] viene `null` (solo [approximateAddress] existe).
/// La ubicación y dirección exactas solo llegan si [isExactLocation] es
/// `true` (el dueño de la publicación, o el recolector que ya la reclamó).
class RecyclingListing {
  final String id;
  final String status; // PENDING | CLAIMED | COMPLETED | CANCELLED | EXPIRED
  final String? address;
  final String? approximateAddress;
  final double latitude;
  final double longitude;
  final bool isExactLocation;
  final String? notes;
  final String? photoMediaId;
  final RecyclingListingCitizen? citizen;
  final String? pickupId;
  final String? pickupRecyclerId;
  final String? pickupStatus;
  final List<RecyclingListingMaterial> materials;
  final List<RecyclingAvailabilityWindow> availabilityWindows;
  final DateTime createdAt;

  RecyclingListing({
    required this.id,
    required this.status,
    this.address,
    this.approximateAddress,
    required this.latitude,
    required this.longitude,
    required this.isExactLocation,
    this.notes,
    this.photoMediaId,
    this.citizen,
    this.pickupId,
    this.pickupRecyclerId,
    this.pickupStatus,
    this.materials = const [],
    this.availabilityWindows = const [],
    required this.createdAt,
  });

  factory RecyclingListing.fromJson(Map<String, dynamic> json) {
    final pickup = json['pickup'] as Map<String, dynamic>?;
    return RecyclingListing(
      id: json['id'] as String,
      status: json['status'] as String,
      address: json['address'] as String?,
      approximateAddress: json['approximateAddress'] as String?,
      latitude: ((json['latitude'] ?? json['fuzzedLatitude']) as num).toDouble(),
      longitude: ((json['longitude'] ?? json['fuzzedLongitude']) as num).toDouble(),
      isExactLocation: json['isExactLocation'] as bool? ?? false,
      notes: json['notes'] as String?,
      photoMediaId: json['photoMediaId'] as String?,
      citizen: json['citizen'] != null
          ? RecyclingListingCitizen.fromJson(json['citizen'] as Map<String, dynamic>)
          : null,
      pickupId: pickup?['id'] as String?,
      pickupRecyclerId: pickup?['recyclerId'] as String?,
      pickupStatus: pickup?['status'] as String?,
      materials: ((json['materials'] as List<dynamic>?) ?? [])
          .map((m) => RecyclingListingMaterial.fromJson(m as Map<String, dynamic>))
          .toList(),
      availabilityWindows: ((json['availabilityWindows'] as List<dynamic>?) ?? [])
          .map((w) => RecyclingAvailabilityWindow.fromJson(w as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
