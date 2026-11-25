import '../../core/logging/app_logger.dart';
import '../../core/network/api_exception.dart';
import '../../domain/entities/rating.dart';
import '../../domain/repositories/ratings_repository.dart';
import '../demo/demo_state.dart';

const _log = AppLogger('DemoRatings');

/// Calificaciones en modo demo, contra [DemoState].
///
/// Reproduce las dos reglas del backend que la UI realmente observa: no se
/// puede calificar dos veces la misma interacción (el servidor lo garantiza
/// con el índice único `uq_rating_context_rater` y responde 409), y el
/// `trustScore` es el promedio corrido de las notas recibidas. Si acá se
/// calcularan distinto, una demostración sin red mostraría una reputación
/// que no coincide con la que daría el servidor.
class DemoRatingsRepositoryImpl implements RatingsRepository {
  DemoRatingsRepositoryImpl(this._state);

  final DemoState _state;

  @override
  Future<({double rateeTrustScore, int rateeRatingsCount})> rate({
    required String pickupId,
    required String rateeId,
    required int score,
    List<String> tags = const [],
    String? comment,
  }) async {
    final user = _state.currentUser;
    if (user == null) {
      throw ApiException(statusCode: 401, message: 'No hay sesión activa.');
    }
    if (user.id == rateeId) {
      throw ApiException(statusCode: 400, message: 'No puedes calificarte a ti mismo');
    }

    final alreadyRated = _state.ratings.any(
      (r) => r.contextId == pickupId && r.raterId == user.id,
    );
    if (alreadyRated) {
      throw ApiException(
        statusCode: 409,
        message: 'Ya has calificado esta interacción previamente',
      );
    }

    _state.ratings.insert(
      0,
      DemoRating(
        id: _state.newId('demo-rating'),
        contextId: pickupId,
        raterId: user.id,
        rateeId: rateeId,
        score: score,
        tags: tags,
        comment: (comment == null || comment.trim().isEmpty) ? null : comment.trim(),
        raterFirstName: user.name,
        raterLastName: user.lastName,
      ),
    );

    final summary = _summaryFor(rateeId);
    _log.info('Calificación demo: $score estrellas a $rateeId por el recojo $pickupId');
    return (rateeTrustScore: summary.$1, rateeRatingsCount: summary.$2);
  }

  @override
  Future<UserRatings> getUserRatings(String userId) async {
    final received = _received(userId);
    final summary = _summaryFor(userId);
    return UserRatings(
      userId: userId,
      trustScore: summary.$1,
      ratingsCount: summary.$2,
      ratings: received.map((r) => r.toRating()).toList(),
    );
  }

  @override
  Future<List<EmittedRating>> getMyRatings() async {
    final user = _state.currentUser;
    if (user == null) return const [];
    return _state.ratings
        .where((r) => r.raterId == user.id)
        .map((r) => r.toEmitted())
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<DemoRating> _received(String userId) {
    final list = _state.ratings.where((r) => r.rateeId == userId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Promedio y conteo, con el mismo redondeo a dos decimales que usa
  /// `RatingsService`. Sin calificaciones devuelve 5.0, que es el valor por
  /// defecto de la columna en la base.
  (double, int) _summaryFor(String userId) {
    final scores = _state.ratings
        .where((r) => r.rateeId == userId)
        .map((r) => r.score)
        .toList();
    if (scores.isEmpty) return (5.0, 0);
    final average = scores.reduce((a, b) => a + b) / scores.length;
    return (double.parse(average.toStringAsFixed(2)), scores.length);
  }
}
