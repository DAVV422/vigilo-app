import '../../core/network/json_parsing.dart';

/// Una persona encontrada en la búsqueda de administración.
///
/// Trae lo necesario para elegir a la correcta y para decidir qué hacer con
/// ella. **No trae correo ni teléfono**, a propósito: quien sanciona no
/// necesita el dato de contacto para sancionar.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.status,
    required this.pointsBalance,
    required this.trustScore,
    required this.ratingsCount,
    this.roles = const [],
  });

  final String id;
  final String firstName;
  final String lastName;
  final String username;

  /// `ACTIVE` · `SUSPENDED` · `BANNED`.
  final String status;
  final int pointsBalance;
  final double trustScore;
  final int ratingsCount;
  final List<String> roles;

  String get fullName => '$firstName $lastName'.trim();

  bool get isRecycler => roles.contains('RECYCLER_INDIVIDUAL');

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] as String,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        username: json['username'] as String? ?? '',
        status: json['status'] as String? ?? 'ACTIVE',
        pointsBalance: toIntOrNull(json['pointsBalance']) ?? 0,
        // Columna NUMERIC.
        trustScore: toDoubleOrNull(json['trustScore']) ?? 0,
        ratingsCount: toIntOrNull(json['ratingsCount']) ?? 0,
        roles: ((json['roles'] as List<dynamic>?) ?? const [])
            .map((r) => r.toString())
            .toList(),
      );
}

/// La política de una infracción: cuánto se descuenta y cómo escala.
class PenaltyRule {
  const PenaltyRule({
    required this.id,
    required this.infractionCode,
    required this.description,
    required this.basePointsDeducted,
    required this.escalationMultiplier,
    required this.evaluationWindowDays,
    required this.warningThresholdOccurrences,
    required this.suspensionThresholdOccurrences,
    required this.active,
  });

  final String id;
  final String infractionCode;
  final String description;
  final int basePointsDeducted;

  /// Cada reincidencia multiplica el descuento por este factor.
  final double escalationMultiplier;

  /// Solo cuentan las sanciones del mismo código dentro de esta ventana.
  final int evaluationWindowDays;
  final int warningThresholdOccurrences;

  /// A partir de esta ocurrencia la sanción pasa de advertencia a suspensión.
  final int suspensionThresholdOccurrences;
  final bool active;

  /// Nombre legible. El servidor manda el código en inglés y la descripción
  /// larga; en la pantalla hace falta algo corto.
  String get label => switch (infractionCode) {
        'NO_SHOW_RECYCLER' => 'No se presentó al recojo',
        'LATE_CANCELLATION_CITIZEN' => 'Canceló tarde',
        'FALSE_INCIDENT_REPORT' => 'Reporte falso',
        _ => infractionCode,
      };

  /// Cuántos puntos se descontarían en la ocurrencia [n], con la misma
  /// aritmética que usa el servidor.
  ///
  /// El cálculo vive en el servidor y no vuelve hasta después de aplicar la
  /// sanción. Repetirlo acá es lo que permite decirle a quien sanciona
  /// cuánto va a descontar **antes** de que lo confirme, en vez de
  /// enterarse los dos juntos.
  int pointsForOccurrence(int n) {
    final exponente = n < 1 ? 0 : n - 1;
    var puntos = basePointsDeducted.toDouble();
    for (var i = 0; i < exponente; i++) {
      puntos *= escalationMultiplier;
    }
    return puntos.round();
  }

  bool suspendsAt(int n) => n >= suspensionThresholdOccurrences;

  factory PenaltyRule.fromJson(Map<String, dynamic> json) => PenaltyRule(
        id: json['id'] as String,
        infractionCode: json['infractionCode'] as String,
        description: json['description'] as String? ?? '',
        basePointsDeducted: toInt(json['basePointsDeducted'],
            field: 'basePointsDeducted'),
        // NUMERIC(4,2): el servidor **no** lo normaliza y llega como "1.50".
        escalationMultiplier:
            toDoubleOrNull(json['escalationMultiplier']) ?? 1.0,
        evaluationWindowDays: toIntOrNull(json['evaluationWindowDays']) ?? 30,
        warningThresholdOccurrences:
            toIntOrNull(json['warningThresholdOccurrences']) ?? 3,
        suspensionThresholdOccurrences:
            toIntOrNull(json['suspensionThresholdOccurrences']) ?? 5,
        active: json['active'] as bool? ?? true,
      );
}

/// Una sanción aplicada.
class Penalty {
  const Penalty({
    required this.id,
    required this.userId,
    required this.infractionCode,
    required this.type,
    required this.status,
    required this.pointsDeducted,
    required this.occurrenceNumber,
    required this.reason,
    required this.startsAt,
    this.endsAt,
    this.userName,
  });

  final String id;
  final String userId;
  final String infractionCode;

  /// `WARNING` · `TEMP_SUSPENSION` · `BAN`.
  final String type;

  /// `ACTIVE` · `LIFTED` · `EXPIRED`. Texto y no enum: un estado nuevo del
  /// servidor tiene que mostrarse, no romper la pantalla.
  final String status;
  final int pointsDeducted;
  final int occurrenceNumber;
  final String reason;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? userName;

  bool get isActive => status == 'ACTIVE';
  bool get isLifted => status == 'LIFTED';

  String get typeLabel => switch (type) {
        'WARNING' => 'Advertencia',
        'TEMP_SUSPENSION' => 'Suspensión temporal',
        'BAN' => 'Expulsión',
        _ => type,
      };

  String get statusLabel => switch (status) {
        'ACTIVE' => 'Vigente',
        'LIFTED' => 'Levantada',
        'EXPIRED' => 'Vencida',
        _ => status,
      };

  String get infractionLabel => switch (infractionCode) {
        'NO_SHOW_RECYCLER' => 'No se presentó al recojo',
        'LATE_CANCELLATION_CITIZEN' => 'Canceló tarde',
        'FALSE_INCIDENT_REPORT' => 'Reporte falso',
        _ => infractionCode,
      };

  factory Penalty.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return Penalty(
      id: json['id'] as String,
      userId: json['userId'] as String,
      infractionCode: json['infractionCode'] as String? ?? '',
      type: json['type'] as String? ?? 'WARNING',
      status: json['status'] as String? ?? 'ACTIVE',
      pointsDeducted: toIntOrNull(json['pointsDeducted']) ?? 0,
      occurrenceNumber: toIntOrNull(json['occurrenceNumber']) ?? 1,
      reason: json['reason'] as String? ?? '',
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: json['endsAt'] != null
          ? DateTime.parse(json['endsAt'] as String)
          : null,
      userName: user == null
          ? null
          : '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim(),
    );
  }
}

/// Lo que devuelve el servidor al aplicar una sanción.
///
/// Importa porque los puntos efectivamente descontados pueden ser menos de
/// los calculados: el saldo tiene piso en cero.
class AppliedPenalty {
  const AppliedPenalty({
    required this.penaltyId,
    required this.type,
    required this.occurrenceNumber,
    required this.pointsDeducted,
    required this.remainingBalance,
  });

  final String penaltyId;
  final String type;
  final int occurrenceNumber;
  final int pointsDeducted;
  final int remainingBalance;

  bool get isSuspension => type == 'TEMP_SUSPENSION';

  factory AppliedPenalty.fromJson(Map<String, dynamic> json) => AppliedPenalty(
        penaltyId: json['penaltyId'] as String,
        type: json['type'] as String? ?? 'WARNING',
        occurrenceNumber: toIntOrNull(json['occurrenceNumber']) ?? 1,
        pointsDeducted: toIntOrNull(json['pointsDeducted']) ?? 0,
        remainingBalance: toIntOrNull(json['remainingBalance']) ?? 0,
      );
}

/// Lo que devuelve el servidor al levantar una sanción.
class LiftedPenalty {
  const LiftedPenalty({
    required this.pointsRestored,
    required this.roleRestored,
    required this.remainingBalance,
  });

  final int pointsRestored;
  final bool roleRestored;
  final int remainingBalance;

  factory LiftedPenalty.fromJson(Map<String, dynamic> json) => LiftedPenalty(
        pointsRestored: toIntOrNull(json['pointsRestored']) ?? 0,
        roleRestored: json['roleRestored'] as bool? ?? false,
        remainingBalance: toIntOrNull(json['remainingBalance']) ?? 0,
      );
}
