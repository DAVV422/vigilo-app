/// Un movimiento del ledger de puntos (`points_transactions` en el backend).
/// Es de solo lectura: el cliente nunca calcula ni escribe puntos, solo
/// refleja lo que el servidor ya acreditó o descontó.
class PointsTransactionEntry {
  final String id;
  final int delta;
  final String reason;
  final String referenceType;
  final String referenceId;
  final int balanceAfter;
  final DateTime createdAt;

  PointsTransactionEntry({
    required this.id,
    required this.delta,
    required this.reason,
    required this.referenceType,
    required this.referenceId,
    required this.balanceAfter,
    required this.createdAt,
  });

  factory PointsTransactionEntry.fromJson(Map<String, dynamic> json) {
    return PointsTransactionEntry(
      id: json['id'] as String,
      delta: json['delta'] as int,
      reason: json['reason'] as String,
      referenceType: json['referenceType'] as String? ?? '',
      referenceId: json['referenceId'] as String? ?? '',
      balanceAfter: json['balanceAfter'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
