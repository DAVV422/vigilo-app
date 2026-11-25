import '../entities/penalty.dart';

/// Los parámetros editables de una regla de penalización.
///
/// Todos opcionales: el servidor aplica solo lo que llega, y mandar el
/// objeto entero sobreescribiría lo que nadie tocó.
class PenaltyRuleInput {
  const PenaltyRuleInput({
    this.description,
    this.basePointsDeducted,
    this.escalationMultiplier,
    this.evaluationWindowDays,
    this.warningThresholdOccurrences,
    this.suspensionThresholdOccurrences,
    this.active,
  });

  final String? description;
  final int? basePointsDeducted;
  final double? escalationMultiplier;
  final int? evaluationWindowDays;
  final int? warningThresholdOccurrences;
  final int? suspensionThresholdOccurrences;
  final bool? active;

  Map<String, dynamic> toJson() => {
        'description': ?description,
        'basePointsDeducted': ?basePointsDeducted,
        'escalationMultiplier': ?escalationMultiplier,
        'evaluationWindowDays': ?evaluationWindowDays,
        'warningThresholdOccurrences': ?warningThresholdOccurrences,
        'suspensionThresholdOccurrences': ?suspensionThresholdOccurrences,
        'active': ?active,
      };
}

/// Reglas de penalización y sanciones (`ADMIN`).
///
/// Es, junto con la resolución de disputas, lo que más consecuencias tiene
/// de todo lo que hace un administrador: aplicar una sanción descuenta
/// puntos del saldo de otra persona y puede revocarle el rol.
abstract class PenaltiesRepository {
  Future<List<PenaltyRule>> getRules();

  Future<PenaltyRule> updateRule(String id, PenaltyRuleInput input);

  /// [status] y [type] filtran del lado del servidor; nulos traen todo.
  Future<List<Penalty>> getPenalties({
    String? userId,
    String? status,
    String? type,
  });

  /// Busca personas por nombre, usuario o correo exacto.
  ///
  /// Exige al menos 3 caracteres: es una búsqueda, no un listado. Sin esto
  /// no habría forma de obtener el `userId` que piden [apply] y el ajuste
  /// de límites.
  Future<List<AdminUser>> searchUsers(String query);

  /// Descuenta puntos, escala por reincidencia, puede revocar el rol de
  /// recolector y notifica. [customPointsDeducted] saltea el cálculo.
  Future<AppliedPenalty> apply({
    required String userId,
    required String infractionCode,
    required String reason,
    int? customPointsDeducted,
  });

  /// Devuelve los puntos, restaura el rol si corresponde y deja la sanción
  /// marcada como levantada. No la borra.
  Future<LiftedPenalty> lift({required String id, required String reason});
}
