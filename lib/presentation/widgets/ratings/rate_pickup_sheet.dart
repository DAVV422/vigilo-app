import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import 'rating_stars.dart';
import 'rating_tags.dart';

const _log = AppLogger('Ratings');

/// Abre la hoja de calificación de un recojo.
///
/// Devuelve `true` si quedó registrada (o si el servidor respondió que ya lo
/// estaba), y `null` si el usuario la descartó. Calificar es opcional: por
/// eso la hoja se puede cerrar y por eso existen las entradas diferidas en
/// "Mis publicaciones" y en "Mis recolecciones".
///
/// [rateeName] puede ser nulo cuando el backend todavía no expone el nombre
/// del recolector; la hoja dice "el recolector" y funciona igual.
Future<bool?> showRatePickupSheet(
  BuildContext context, {
  required String pickupId,
  required String rateeId,
  String? rateeName,
  double? rateeTrustScore,
  required bool rateeIsRecycler,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _RatePickupSheet(
      pickupId: pickupId,
      rateeId: rateeId,
      rateeName: rateeName,
      rateeTrustScore: rateeTrustScore,
      rateeIsRecycler: rateeIsRecycler,
    ),
  );
}

class _RatePickupSheet extends ConsumerStatefulWidget {
  const _RatePickupSheet({
    required this.pickupId,
    required this.rateeId,
    required this.rateeName,
    required this.rateeTrustScore,
    required this.rateeIsRecycler,
  });

  final String pickupId;
  final String rateeId;
  final String? rateeName;
  final double? rateeTrustScore;
  final bool rateeIsRecycler;

  @override
  ConsumerState<_RatePickupSheet> createState() => _RatePickupSheetState();
}

class _RatePickupSheetState extends ConsumerState<_RatePickupSheet> {
  /// Cero y no cinco: una hoja que abre con las cinco estrellas marcadas
  /// invita a confirmar sin leer, y el promedio se va a 5,00 solo.
  int _score = 0;
  final Set<String> _tags = {};
  final _commentController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String get _displayName =>
      widget.rateeName ?? (widget.rateeIsRecycler ? 'el recolector' : 'el ciudadano');

  List<String> get _visibleTags {
    final all = widget.rateeIsRecycler ? recyclerTags : citizenTags;
    // Las etiquetas negativas solo aparecen con una nota baja. Con 4 o 5
    // estrellas no aportan y ensucian la elección.
    if (_score >= 4) return all.where((t) => !negativeTags.contains(t)).toList();
    return all;
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    try {
      await ref.read(ratingsRepositoryProvider).rate(
            pickupId: widget.pickupId,
            rateeId: widget.rateeId,
            score: _score,
            // Una etiqueta negativa pudo quedar seleccionada y luego el
            // usuario subió la nota: se manda solo lo que sigue visible.
            tags: _tags.where(_visibleTags.contains).toList(),
            comment: _commentController.text,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      // 409 no es un error que el usuario deba resolver: ya hizo lo que
      // quería, probablemente desde otro dispositivo o en un doble toque.
      // Tratarlo como fallo lo invitaría a reintentar algo imposible.
      if (e.statusCode == 409) {
        _log.info('El recojo ${widget.pickupId} ya estaba calificado');
        // El messenger se resuelve ANTES de cerrar la hoja: después, el
        // context que se está usando para buscarlo es el de una ruta que
        // acaba de salir del árbol.
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context, true);
        messenger.showSnackBar(
          const SnackBar(content: Text('Ya habías calificado este recojo.')),
        );
        return;
      }
      setState(() => _sending = false);
      _showError(e.message);
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _sending = false);
      _showError(
        describeError(
          e,
          st,
          log: _log,
          operation: 'registrar la calificación',
          whereToCheck: 'Mis publicaciones',
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleTags;

    return Padding(
      // Deja la hoja por encima del teclado cuando se escribe el comentario.
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '¿Cómo te fue con $_displayName?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (widget.rateeTrustScore != null) ...[
              const SizedBox(height: 6),
              Center(child: RatingScoreBadge(score: widget.rateeTrustScore!)),
            ],
            const SizedBox(height: 16),
            RatingStars(
              score: _score,
              onChanged: _sending ? null : (v) => setState(() => _score = v),
            ),
            const SizedBox(height: 20),
            if (_score > 0) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in visible)
                    FilterChip(
                      label: Text(ratingTagLabel(tag)),
                      selected: _tags.contains(tag),
                      onSelected: _sending
                          ? null
                          : (on) => setState(
                                () => on ? _tags.add(tag) : _tags.remove(tag),
                              ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _commentController,
              enabled: !_sending,
              maxLines: 3,
              // El servidor rechaza con 400 más allá de 500; mejor que el
              // contador lo impida antes de enviar.
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Comentario (opcional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              // Deshabilitado sin nota y mientras hay un envío en curso. El
              // índice único del servidor es el respaldo contra el doble
              // toque, no la defensa principal.
              onPressed: (_score == 0 || _sending) ? null : _submit,
              child: _sending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enviar calificación'),
            ),
            TextButton(
              onPressed: _sending ? null : () => Navigator.pop(context),
              child: const Text('Ahora no'),
            ),
          ],
        ),
      ),
    );
  }
}
