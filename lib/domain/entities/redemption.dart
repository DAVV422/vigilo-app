import '../../core/network/json_parsing.dart';
class Redemption {
  final String id;
  final String productId;
  final String? productName;
  final String? productImageUrl;
  final int pointsSpent;
  final String code;
  final String status; // 'PENDING' | 'FULFILLED' | 'CANCELLED'
  final DateTime createdAt;
  final DateTime? fulfilledAt;

  Redemption({
    required this.id,
    required this.productId,
    this.productName,
    this.productImageUrl,
    required this.pointsSpent,
    required this.code,
    required this.status,
    required this.createdAt,
    this.fulfilledAt,
  });

  factory Redemption.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return Redemption(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: product?['name'] as String?,
      productImageUrl: product?['imageUrl'] as String?,
      pointsSpent: toInt(json['pointsSpent'], field: 'pointsSpent'),
      code: json['code'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      fulfilledAt: json['fulfilledAt'] != null ? DateTime.parse(json['fulfilledAt'] as String) : null,
    );
  }
}
