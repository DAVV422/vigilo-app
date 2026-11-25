import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/penalty.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';

const _log = AppLogger('AdminSanciones');

/// Abre la hoja de una sanción. Devuelve `true` si quedó levantada.
Future<bool?> showPenaltySheet(
  BuildContext context, {
  required Penalty penalty,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _PenaltySheet(penalty: penalty),
  );
}

class _PenaltySheet extends ConsumerStatefulWidget {
  const _PenaltySheet({required this.penalty});

  final Penalty penalty;

  @override
  ConsumerState<_PenaltySheet> createState() => _PenaltySheetState();
}

class _PenaltySheetState extends ConsumerState<_PenaltySheet> {
  final _reason = TextEditingController();
  bool _lifting = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _lift() async {
    if (_reason.text.trim().length < 10) {
      _snack('Escribí por qué se levanta la sanción.', isError: true);
      return;
    }

    setState(() => _lifting = true);
    try {
      final r = await ref.read(penaltiesRepositoryProvider).lift(
            id: widget.penalty.id,
            reason: _reason.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
      _snack(
        r.pointsRestored > 0
            ? 'Sanción levantada. Se devolvieron ${r.pointsRestored} puntos'
                '${r.roleRestored ? " y se restauró el rol de recolector" : ""}.'
            : 'Sanción levantada.',
      );
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _lifting = false);
      _snack(
        describeError(e, st,
            log: _log,
            operation: 'levantar la sanción',
            whereToCheck: 'el historial de sanciones'),
        isError: true,
      );
    }
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.penalty;

    return Padding(
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
            const SizedBox(height: 18),
            Text(
              p.infractionLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${p.userName ?? "Usuario"} · ${p.typeLabel} · '
              '${p.occurrenceNumber}.ª falta',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MOTIVO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Completo y sin recortar: es la justificación entera.
                  Text(p.reason,
                      style: const TextStyle(fontSize: 13, height: 1.4)),
                  const SizedBox(height: 10),
                  Text(
                    '−${p.pointsDeducted} puntos · ${_fecha(p.startsAt)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (p.isLifted)
              const Text(
                'Esta sanción ya fue levantada.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
              )
            else ...[
              TextField(
                controller: _reason,
                enabled: !_lifting,
                maxLines: 2,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Por qué se levanta',
                  helperText:
                      'Se devuelven los puntos y la sanción queda marcada '
                      'como levantada, no se borra.',
                  helperMaxLines: 3,
                ),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: _lifting ? null : _lift,
                child: _lifting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Levantar la sanción'),
              ),
            ],
            TextButton(
              onPressed: _lifting ? null : () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}

String _fecha(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
