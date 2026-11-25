import '../../core/network/json_parsing.dart';

/// Quien emitió una calificación, tal como la devuelve el backend en el
/// detalle de `GET /ratings/user/:id`. Puede venir nulo: la relación existe
/// pero el servidor la deja opcional.
class RatingAuthor {
  const RatingAuthor({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;

  String get displayName => '$firstName $lastName'.trim();

  /// Inicial para el avatar cuando no hay imagen — es lo que ya hace el
  /// perfil, y en los datos sembrados `avatarUrl` es siempre nulo.
  String get initial =>
      displayName.isEmpty ? '?' : displayName.substring(0, 1).toUpperCase();

  factory RatingAuthor.fromJson(Map<String, dynamic> json) {
    return RatingAuthor(
      id: json['id'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

/// Una calificación recibida.
class Rating {
  const Rating({
    required this.id,
    required this.score,
    required this.tags,
    this.comment,
    required this.createdAt,
    this.rater,
  });

  final String id;
  final int score;
  final List<String> tags;
  final String? comment;
  final DateTime createdAt;
  final RatingAuthor? rater;

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] as String,
      score: toInt(json['score'], field: 'score'),
      tags: ((json['tags'] as List<dynamic>?) ?? const []).cast<String>(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      rater: json['rater'] != null
          ? RatingAuthor.fromJson(json['rater'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Lo que devuelve `GET /ratings/user/:id`: el resumen de reputación y el
/// detalle en una sola respuesta.
class UserRatings {
  const UserRatings({
    required this.userId,
    required this.trustScore,
    required this.ratingsCount,
    required this.ratings,
  });

  final String userId;
  final double trustScore;
  final int ratingsCount;

  /// Ordenadas de más reciente a más antigua por el servidor.
  final List<Rating> ratings;

  /// Cuántas calificaciones hubo de cada nota, de 1 a 5. El backend no lo
  /// agrega y tampoco hace falta pedírselo: sale de [ratings].
  Map<int, int> get scoreBreakdown {
    final counts = {for (var i = 1; i <= 5; i++) i: 0};
    for (final r in ratings) {
      if (counts.containsKey(r.score)) counts[r.score] = counts[r.score]! + 1;
    }
    return counts;
  }

  factory UserRatings.fromJson(Map<String, dynamic> json) {
    return UserRatings(
      userId: json['userId'] as String,
      // `trustScore` sale de una columna NUMERIC(3,2) y el driver `pg` la
      // serializa como texto. El backend normaliza con Number(), pero el
      // parseo tolerante es la red de seguridad: un `as num` acá fue el bug
      // que rompía la publicación de material.
      trustScore: toDoubleOrNull(json['trustScore']) ?? 5.0,
      ratingsCount: toIntOrNull(json['ratingsCount']) ?? 0,
      ratings: ((json['ratings'] as List<dynamic>?) ?? const [])
          .map((r) => Rating.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Una calificación *emitida* por el usuario en sesión (`GET /ratings/mine`).
///
/// Es un tipo aparte de [Rating] porque responde a otra pregunta y trae otros
/// campos: no dice quién calificó —es uno mismo— sino *qué* se calificó.
/// [contextId] es el id del recojo, y es el único campo que la pantalla de
/// calificación diferida necesita para saber qué ya está hecho.
class EmittedRating {
  const EmittedRating({
    required this.id,
    required this.contextType,
    required this.contextId,
    required this.rateeId,
    required this.score,
    required this.tags,
    this.comment,
    required this.createdAt,
  });

  final String id;
  final String contextType;
  final String contextId;
  final String rateeId;
  final int score;
  final List<String> tags;
  final String? comment;
  final DateTime createdAt;

  factory EmittedRating.fromJson(Map<String, dynamic> json) {
    return EmittedRating(
      id: json['id'] as String,
      contextType: json['contextType'] as String,
      contextId: json['contextId'] as String,
      rateeId: json['rateeId'] as String,
      score: toInt(json['score'], field: 'score'),
      tags: ((json['tags'] as List<dynamic>?) ?? const []).cast<String>(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
