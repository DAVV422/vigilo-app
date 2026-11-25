import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Estrellas de calificación, en dos modos.
///
/// Se separó en su propio archivo porque la hoja de calificación las necesita
/// interactivas y el detalle de reputación las necesita de solo lectura, y
/// tener dos implementaciones garantizaba que se vieran distinto.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.score,
    this.onChanged,
    this.size = 40,
  });

  /// Nota actual, de 0 a 5. Cero significa "sin elegir todavía".
  final int score;

  /// Si es nulo, las estrellas son de solo lectura.
  final ValueChanged<int>? onChanged;

  final double size;

  bool get _interactive => onChanged != null;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          _interactive ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        for (var i = 1; i <= 5; i++)
          Semantics(
            label: '$i de 5 estrellas',
            selected: score == i,
            child: IconButton(
              // En solo lectura el IconButton no responde pero conserva el
              // mismo tamaño y espaciado, así una nota se ve igual se pueda
              // tocar o no.
              onPressed: _interactive ? () => onChanged!(i) : null,
              padding: EdgeInsets.symmetric(horizontal: size * 0.05),
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              icon: Icon(
                i <= score ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: i <= score ? AppColors.warning : AppColors.outline,
              ),
            ),
          ),
      ],
    );
  }
}

/// Versión compacta para listas: una estrella y el número al lado.
class RatingScoreBadge extends StatelessWidget {
  const RatingScoreBadge({super.key, required this.score, this.count});

  final double score;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
        const SizedBox(width: 4),
        Text(
          score.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        if (count != null) ...[
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
