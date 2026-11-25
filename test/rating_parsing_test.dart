import 'package:flutter_test/flutter_test.dart';
import 'package:vigilo/domain/entities/rating.dart';

void main() {
  group('UserRatings.fromJson', () {
    // Copiado literal de la respuesta del servidor desplegado para
    // 0dec0ded-0001-4000-8000-000000000007 (Gregorio Mamani Quispe).
    final realResponse = <String, dynamic>{
      'userId': '0dec0ded-0001-4000-8000-000000000007',
      'trustScore': 4.67,
      'ratingsCount': 3,
      'ratings': [
        {
          'id': '0dec0ded-000f-4000-8000-00000000000b',
          'score': 4,
          'tags': ['peso_justo', 'amable'],
          'comment': 'Buen trato. Tuvo que volver en dos viajes porque no entraba todo.',
          'createdAt': '2026-11-11T02:12:16.177Z',
          'rater': {
            'id': '0dec0ded-0001-4000-8000-000000000003',
            'firstName': 'Daniela',
            'lastName': 'Chávez Ortiz',
            'avatarUrl': null,
          },
        },
      ],
    };

    test('parsea la respuesta real del servidor', () {
      final summary = UserRatings.fromJson(realResponse);
      expect(summary.trustScore, 4.67);
      expect(summary.ratingsCount, 3);
      expect(summary.ratings.single.score, 4);
      expect(summary.ratings.single.tags, ['peso_justo', 'amable']);
      expect(summary.ratings.single.rater?.displayName, 'Daniela Chávez Ortiz');
      expect(summary.ratings.single.rater?.initial, 'D');
    });

    // La que de verdad protege: `users.trust_score` es NUMERIC(3,2) y el
    // driver `pg` lo serializa como texto. El backend normaliza con Number(),
    // pero basta que un endpoint se lo olvide para que un `as num` lance en
    // medio del parseo. Pasó con citizen.trustScore al publicar material.
    test('tolera trustScore como string', () {
      final summary = UserRatings.fromJson({
        ...realResponse,
        'trustScore': '4.67',
        'ratings': <dynamic>[],
      });
      expect(summary.trustScore, 4.67);
    });

    test('un usuario sin calificaciones no rompe', () {
      final summary = UserRatings.fromJson({
        'userId': 'u-sin-calificaciones',
        'trustScore': 5,
        'ratingsCount': 0,
        'ratings': <dynamic>[],
      });
      expect(summary.ratingsCount, 0);
      expect(summary.ratings, isEmpty);
      expect(summary.trustScore, 5.0);
    });

    test('rater nulo y comment nulo se toleran', () {
      final summary = UserRatings.fromJson({
        'userId': 'u1',
        'trustScore': 3,
        'ratingsCount': 1,
        'ratings': [
          {
            'id': 'r1',
            'score': 3,
            'tags': <dynamic>[],
            'comment': null,
            'createdAt': '2026-11-11T02:12:16.177Z',
            'rater': null,
          },
        ],
      });
      expect(summary.ratings.single.rater, isNull);
      expect(summary.ratings.single.comment, isNull);
      expect(summary.ratings.single.tags, isEmpty);
    });

    test('tags ausente degrada a lista vacía', () {
      final rating = Rating.fromJson({
        'id': 'r1',
        'score': 5,
        'createdAt': '2026-11-11T02:12:16.177Z',
      });
      expect(rating.tags, isEmpty);
    });

    test('scoreBreakdown cuenta cada nota y deja en cero las que faltan', () {
      final summary = UserRatings.fromJson({
        'userId': 'u1',
        'trustScore': 3.67,
        'ratingsCount': 3,
        'ratings': [
          for (final s in [5, 4, 2])
            {
              'id': 'r$s',
              'score': s,
              'tags': <dynamic>[],
              'createdAt': '2026-11-11T02:12:16.177Z',
            },
        ],
      });
      expect(summary.scoreBreakdown, {5: 1, 4: 1, 3: 0, 2: 1, 1: 0});
    });
  });

  group('EmittedRating.fromJson', () {
    // Respuesta real de GET /ratings/mine para daniela.chavez@vigilo.bo.
    test('parsea lo que devuelve /ratings/mine', () {
      final emitted = EmittedRating.fromJson({
        'id': '0dec0ded-000f-4000-8000-000000000005',
        'contextType': 'RECYCLING_PICKUP',
        'contextId': '0dec0ded-0009-4000-8000-000000000005',
        'rateeId': '0dec0ded-0001-4000-8000-000000000009',
        'score': 2,
        'tags': ['peso_discutible'],
        'comment': 'El peso que registró es bastante menor al que marcó mi balanza.',
        'createdAt': '2026-11-16T02:12:16.177Z',
      });
      expect(emitted.contextId, '0dec0ded-0009-4000-8000-000000000005');
      expect(emitted.score, 2);
      expect(emitted.contextType, 'RECYCLING_PICKUP');
    });

    // El uso real: con esto la pantalla sabe qué recojos ya calificó.
    test('sirve para armar el conjunto de recojos ya calificados', () {
      final emitted = [
        for (final id in ['p1', 'p2'])
          EmittedRating.fromJson({
            'id': 'r-$id',
            'contextType': 'RECYCLING_PICKUP',
            'contextId': id,
            'rateeId': 'u9',
            'score': 5,
            'tags': <dynamic>[],
            'createdAt': '2026-11-16T02:12:16.177Z',
          }),
      ];
      final rated = emitted.map((r) => r.contextId).toSet();
      expect(rated.contains('p1'), isTrue);
      expect(rated.contains('p3'), isFalse);
    });
  });
}
