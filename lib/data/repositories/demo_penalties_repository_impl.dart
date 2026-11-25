import '../../core/network/api_exception.dart';
import '../../domain/entities/penalty.dart';
import '../../domain/repositories/penalties_repository.dart';

/// Sanciones en modo demo.
///
/// Las tres reglas son las que siembra el servidor, para que la pantalla de
/// políticas se vea igual sin red. Las sanciones viven en memoria y se
/// pierden al cerrar la app, que en una presentación es una ventaja: se
/// puede sancionar para mostrar el flujo sin dejar rastro.
class DemoPenaltiesRepositoryImpl implements PenaltiesRepository {
  DemoPenaltiesRepositoryImpl();

  late final List<PenaltyRule> _rules = [
    const PenaltyRule(
      id: 'demo-regla-no-show',
      infractionCode: 'NO_SHOW_RECYCLER',
      description:
          'El recolector no se presentó al recojo que había reclamado.',
      basePointsDeducted: 10,
      escalationMultiplier: 2.0,
      evaluationWindowDays: 30,
      warningThresholdOccurrences: 3,
      suspensionThresholdOccurrences: 5,
      active: true,
    ),
    const PenaltyRule(
      id: 'demo-regla-cancelacion',
      infractionCode: 'LATE_CANCELLATION_CITIZEN',
      description:
          'El ciudadano canceló el recojo cuando el recolector ya iba en camino.',
      basePointsDeducted: 5,
      escalationMultiplier: 2.0,
      evaluationWindowDays: 30,
      warningThresholdOccurrences: 3,
      suspensionThresholdOccurrences: 5,
      active: true,
    ),
    const PenaltyRule(
      id: 'demo-regla-reporte-falso',
      infractionCode: 'FALSE_INCIDENT_REPORT',
      description: 'El incidente reportado no existía.',
      basePointsDeducted: 5,
      escalationMultiplier: 1.5,
      evaluationWindowDays: 30,
      warningThresholdOccurrences: 3,
      suspensionThresholdOccurrences: 4,
      active: true,
    ),
  ];

  final List<Penalty> _penalties = [];
  int _counter = 0;

  @override
  Future<List<PenaltyRule>> getRules() async => List.unmodifiable(_rules);

  @override
  Future<PenaltyRule> updateRule(String id, PenaltyRuleInput input) async {
    final i = _rules.indexWhere((r) => r.id == id);
    if (i < 0) {
      throw ApiException(statusCode: 404, message: 'Regla no encontrada.');
    }
    final r = _rules[i];
    final actualizada = PenaltyRule(
      id: r.id,
      infractionCode: r.infractionCode,
      description: input.description ?? r.description,
      basePointsDeducted: input.basePointsDeducted ?? r.basePointsDeducted,
      escalationMultiplier:
          input.escalationMultiplier ?? r.escalationMultiplier,
      evaluationWindowDays:
          input.evaluationWindowDays ?? r.evaluationWindowDays,
      warningThresholdOccurrences:
          input.warningThresholdOccurrences ?? r.warningThresholdOccurrences,
      suspensionThresholdOccurrences: input.suspensionThresholdOccurrences ??
          r.suspensionThresholdOccurrences,
      active: input.active ?? r.active,
    );
    _rules[i] = actualizada;
    return actualizada;
  }

  @override
  Future<List<Penalty>> getPenalties({
    String? userId,
    String? status,
    String? type,
  }) async {
    return _penalties
        .where((p) =>
            (userId == null || p.userId == userId) &&
            (status == null || p.status == status) &&
            (type == null || p.type == type))
        .toList();
  }

  /// El modo demo no tiene una base de usuarios que recorrer: el estado
  /// local solo conoce a quien inició sesión. Devolver una lista vacía es
  /// la respuesta honesta, y la pantalla lo explica.
  @override
  Future<List<AdminUser>> searchUsers(String query) async => const [];

  @override
  Future<AppliedPenalty> apply({
    required String userId,
    required String infractionCode,
    required String reason,
    int? customPointsDeducted,
  }) async {
    final regla = _rules.firstWhere(
      (r) => r.infractionCode == infractionCode && r.active,
      orElse: () => throw ApiException(
        statusCode: 404,
        message: 'No hay una regla activa para esa infracción.',
      ),
    );

    final ocurrencia = _penalties
            .where((p) =>
                p.userId == userId && p.infractionCode == infractionCode)
            .length +
        1;
    final puntos =
        customPointsDeducted ?? regla.pointsForOccurrence(ocurrencia);
    final tipo =
        regla.suspendsAt(ocurrencia) ? 'TEMP_SUSPENSION' : 'WARNING';

    final sancion = Penalty(
      id: 'demo-sancion-${++_counter}',
      userId: userId,
      infractionCode: infractionCode,
      type: tipo,
      status: 'ACTIVE',
      pointsDeducted: puntos,
      occurrenceNumber: ocurrencia,
      reason: reason,
      startsAt: DateTime.now(),
    );
    _penalties.add(sancion);

    return AppliedPenalty(
      penaltyId: sancion.id,
      type: tipo,
      occurrenceNumber: ocurrencia,
      pointsDeducted: puntos,
      remainingBalance: 0,
    );
  }

  @override
  Future<LiftedPenalty> lift({
    required String id,
    required String reason,
  }) async {
    final i = _penalties.indexWhere((p) => p.id == id);
    if (i < 0) {
      throw ApiException(statusCode: 404, message: 'Sanción no encontrada.');
    }
    final p = _penalties[i];
    if (p.isLifted) {
      throw ApiException(
        statusCode: 400,
        message: 'Esta sanción ya fue levantada.',
      );
    }
    _penalties[i] = Penalty(
      id: p.id,
      userId: p.userId,
      infractionCode: p.infractionCode,
      type: p.type,
      status: 'LIFTED',
      pointsDeducted: p.pointsDeducted,
      occurrenceNumber: p.occurrenceNumber,
      reason: p.reason,
      startsAt: p.startsAt,
      endsAt: DateTime.now(),
      userName: p.userName,
    );
    return LiftedPenalty(
      pointsRestored: p.pointsDeducted,
      roleRestored: false,
      remainingBalance: 0,
    );
  }
}
