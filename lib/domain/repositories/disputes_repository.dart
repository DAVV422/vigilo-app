import '../entities/dispute.dart';

/// Una corrección de peso dentro de una resolución `ADJUST_WEIGHT`.
class AdjustedWeight {
  const AdjustedWeight({required this.materialTypeId, required this.newWeightGrams});

  final String materialTypeId;
  final double newWeightGrams;

  Map<String, dynamic> toJson() => {
        'materialTypeId': materialTypeId,
        'newWeightGrams': newWeightGrams,
      };
}

/// Moderación de disputas de pesaje (`ADMIN`, `MODERATOR`).
///
/// El ciudadano abre la disputa desde el flujo de recojo; acá vive el otro
/// lado, que hasta ahora no existía: se podían abrir y nadie podía cerrarlas.
abstract class DisputesRepository {
  /// [status] nulo trae todas. La bandeja filtra `OPEN` por defecto.
  Future<List<Dispute>> getAll({String? status});

  Future<Dispute> getById(String id);

  /// Resuelve la disputa. Mueve puntos, pesos o reputación según la acción,
  /// y no se deshace.
  ///
  /// Cada acción exige su propio dato: `ADJUST_WEIGHT` necesita
  /// [adjustedWeights], `CREDIT_POINTS` necesita [creditPointsAmount] y
  /// `PENALIZE_RECYCLER` necesita [penaltyInfractionCode]. El DTO del
  /// backend los declara opcionales, pero los valida según la acción.
  Future<void> resolve({
    required String id,
    required DisputeAction action,
    required String notes,
    List<AdjustedWeight>? adjustedWeights,
    int? creditPointsAmount,
    String? penaltyInfractionCode,
  });
}
