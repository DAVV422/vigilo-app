import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/rating.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../widgets/ratings/rating_stars.dart';
import '../../widgets/ratings/rating_tags.dart';

const _log = AppLogger('Reputacion');

/// Reputación de **alguien**, no "mi reputación".
///
/// Toma un [userId] a propósito, aunque hoy se entre casi siempre desde el
/// perfil propio: `GET /ratings/user/:id` es público, así que la misma
/// pantalla sirve para que un ciudadano mire al recolector antes de que
/// toque la puerta, y al revés antes de reclamar una publicación. Costaba lo
/// mismo construirla así.
class UserRatingsScreen extends ConsumerWidget {
  const UserRatingsScreen({super.key, required this.userId, this.displayName});

  final String userId;

  /// Para el título mientras carga. Puede ser nulo.
  final String? displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userRatingsProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(displayName ?? 'Reputación')),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, st) => _buildError(
          context,
          ref,
          // Sin `whereToCheck`: esta pantalla solo lee, así que reintentar es
          // inofensivo y no hay nada que verificar antes.
          describeError(e, st, log: _log, operation: 'cargar las calificaciones'),
        ),
        data: (summary) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(userRatingsProvider(userId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              _buildHeader(summary),
              if (summary.ratings.isEmpty)
                _buildEmpty()
              else ...[
                const SizedBox(height: 20),
                _buildBreakdown(summary),
                const SizedBox(height: 24),
                const Text(
                  'Comentarios',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...summary.ratings.map(_buildRatingCard),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.invalidate(userRatingsProvider(userId)),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserRatings summary) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            summary.trustScore.toStringAsFixed(2),
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          RatingStars(score: summary.trustScore.round(), size: 26),
          const SizedBox(height: 8),
          Text(
            summary.ratingsCount == 1
                ? '1 calificación'
                : '${summary.ratingsCount} calificaciones',
            style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// Importa decirlo: con `trust_score` por defecto en 5.00, un perfil sin
  /// calificaciones muestra la nota máxima. Sin esta aclaración parece un
  /// error, o peor, una reputación ganada.
  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Icon(Icons.star_outline_rounded, size: 40, color: AppColors.outline),
          SizedBox(height: 12),
          Text(
            'Todavía no hay calificaciones',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            'Aparecen cuando se completa un recojo y la otra parte califica.',
            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdown(UserRatings summary) {
    final counts = summary.scoreBreakdown;
    final max = counts.values.fold<int>(0, (a, b) => b > a ? b : a);
    return Column(
      children: [
        for (var score = 5; score >= 1; score--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  child: Text('$score', style: const TextStyle(fontSize: 12)),
                ),
                const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      // Proporcional a la nota más frecuente, no al total:
                      // con pocas calificaciones todas las barras quedarían
                      // casi vacías y no se distinguiría nada.
                      value: max == 0 ? 0 : counts[score]! / max,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceContainerLow,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${counts[score]}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRatingCard(Rating rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  // El backend admite `rater` nulo. Mostrar "Usuario" en vez
                  // de dejar un hueco.
                  rating.rater?.initial ?? '?',
                  style: const TextStyle(
                    color: AppColors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rating.rater?.displayName ?? 'Usuario',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                _relativeDate(rating.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RatingStars(score: rating.score, size: 16),
          if (rating.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in rating.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // Una etiqueta desconocida se muestra tal cual, nunca
                    // desaparece: es información real que alguien escribió.
                    child: Text(
                      ratingTagLabel(tag),
                      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ],
          if (rating.comment != null) ...[
            const SizedBox(height: 10),
            Text(rating.comment!, style: const TextStyle(fontSize: 13)),
          ],
        ],
      ),
    );
  }

  String _relativeDate(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return 'hoy';
    if (days == 1) return 'ayer';
    if (days < 30) return 'hace $days días';
    final months = (days / 30).floor();
    return months == 1 ? 'hace 1 mes' : 'hace $months meses';
  }
}
