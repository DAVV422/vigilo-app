import '../entities/rating.dart';

/// Reputación: la calificación mutua que ambas partes se dan al terminar un
/// recojo, y que alimenta el `trustScore` y el motor de penalizaciones.
/// Ver docs/refactor/faseA/A-01-capa-de-datos-de-calificaciones.md.
abstract class RatingsRepository {
  /// Califica a la otra parte de un recojo completado.
  ///
  /// `contextType` no está en la firma porque hoy el único contexto es
  /// `RECYCLING_PICKUP`, y el parámetro se llama [pickupId] justamente para
  /// decirlo. Cuando exista un segundo contexto se generaliza; agregar ahora
  /// un string que siempre vale lo mismo no abstrae nada.
  ///
  /// Devuelve la reputación del calificado ya recalculada por el servidor,
  /// para poder reflejarla sin una segunda llamada. Ojo: es la del *otro*,
  /// no la de quien califica.
  ///
  /// Lanza `ApiException` con 409 si ya calificó ese recojo (lo garantiza el
  /// índice único `uq_rating_context_rater`), y con 400 si el recojo no está
  /// completado o quien llama no es parte de él.
  Future<({double rateeTrustScore, int rateeRatingsCount})> rate({
    required String pickupId,
    required String rateeId,
    required int score,
    List<String> tags = const [],
    String? comment,
  });

  /// Reputación y calificaciones recibidas por alguien. El endpoint es
  /// público, así que sirve tanto para el perfil propio como para mirar al
  /// recolector antes de que llegue.
  Future<UserRatings> getUserRatings(String userId);

  /// Calificaciones emitidas por el usuario en sesión.
  ///
  /// Existe para saber qué recojos ya calificó y no volver a ofrecerle la
  /// tarjeta de "calificá tu último recojo". `getUserRatings` no sirve para
  /// eso: devuelve lo recibido, no lo emitido.
  Future<List<EmittedRating>> getMyRatings();
}
