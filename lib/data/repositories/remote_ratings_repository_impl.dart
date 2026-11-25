import '../../core/network/json_parsing.dart';
import '../../domain/entities/rating.dart';
import '../../domain/repositories/ratings_repository.dart';
import '../datasources/remote/remote_ratings_datasource.dart';

/// Único contexto de calificación que existe hoy. Si aparece otro (calificar
/// la resolución de un incidente, por ejemplo), este valor deja de ser una
/// constante y pasa a la firma del método.
const _contextRecyclingPickup = 'RECYCLING_PICKUP';

class RemoteRatingsRepositoryImpl implements RatingsRepository {
  RemoteRatingsRepositoryImpl(this._datasource);

  final RemoteRatingsDatasource _datasource;

  @override
  Future<({double rateeTrustScore, int rateeRatingsCount})> rate({
    required String pickupId,
    required String rateeId,
    required int score,
    List<String> tags = const [],
    String? comment,
  }) async {
    final data = await _datasource.create({
      'contextType': _contextRecyclingPickup,
      'contextId': pickupId,
      'rateeId': rateeId,
      'score': score,
      'tags': tags,
      // El backend acepta `comment` ausente; mandar una cadena vacía la
      // guardaría como tal y la pantalla de detalle mostraría un comentario
      // en blanco en vez de omitirlo.
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    });

    return (
      rateeTrustScore: toDoubleOrNull(data['rateeUpdatedTrustScore']) ?? 5.0,
      rateeRatingsCount: toIntOrNull(data['rateeTotalRatings']) ?? 0,
    );
  }

  @override
  Future<UserRatings> getUserRatings(String userId) async {
    return UserRatings.fromJson(await _datasource.getByUser(userId));
  }

  @override
  Future<List<EmittedRating>> getMyRatings() async {
    final list = await _datasource.getMine();
    return list
        .map((r) => EmittedRating.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
