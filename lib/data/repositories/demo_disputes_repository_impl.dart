import '../../core/network/api_exception.dart';
import '../../domain/entities/dispute.dart';
import '../../domain/repositories/disputes_repository.dart';
import '../demo/demo_state.dart';

/// Disputas en modo demo.
///
/// `DemoState` no modela disputas —el flujo para abrirlas tampoco existe en
/// la demo— así que la bandeja aparece vacía. Es el estado correcto y no un
/// error: sin recojos disputados no hay nada que moderar. La clase existe
/// para que el modo sin red no se caiga al entrar a la sección.
class DemoDisputesRepositoryImpl implements DisputesRepository {
  DemoDisputesRepositoryImpl(this._state);

  // ignore: unused_field — lo necesitará en cuanto la demo modele disputas.
  final DemoState _state;

  @override
  Future<List<Dispute>> getAll({String? status}) async => const [];

  @override
  Future<Dispute> getById(String id) async {
    throw ApiException(statusCode: 404, message: 'Disputa no encontrada.');
  }

  @override
  Future<void> resolve({
    required String id,
    required DisputeAction action,
    required String notes,
    List<AdjustedWeight>? adjustedWeights,
    int? creditPointsAmount,
    String? penaltyInfractionCode,
  }) async {
    throw ApiException(
      statusCode: 404,
      message: 'El modo demo todavía no modela disputas.',
    );
  }
}
