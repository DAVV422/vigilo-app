import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/dispute.dart';
import '../../../domain/repositories/disputes_repository.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../screens/admin/widgets/confirm_action_dialog.dart';

const _log = AppLogger('AdminDisputas');

/// Códigos de infracción que siembra `DatabaseSeederService`.
///
/// Van como constantes y no leídos de `GET /admin/penalty-rules` porque ese
/// endpoint es de `ADMIN` y un `MODERATOR` **sí** puede resolver disputas
/// pero **no** puede leer la lista de reglas. Hasta que exista la pantalla
/// de penalizaciones, pedirlos rompería la función para la mitad de quienes
/// la usan.
const _infractionCodes = {
  'NO_SHOW_RECYCLER': 'No se presentó al recojo',
  'LATE_CANCELLATION_CITIZEN': 'Canceló tarde',
  'FALSE_INCIDENT_REPORT': 'Reporte falso',
};

/// Abre la hoja de resolución. Devuelve `true` si la disputa quedó resuelta.
Future<bool?> showResolveDisputeSheet(
  BuildContext context, {
  required Dispute dispute,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ResolveSheet(dispute: dispute),
  );
}

class _ResolveSheet extends ConsumerStatefulWidget {
  const _ResolveSheet({required this.dispute});

  final Dispute dispute;

  @override
  ConsumerState<_ResolveSheet> createState() => _ResolveSheetState();
}

class _ResolveSheetState extends ConsumerState<_ResolveSheet> {
  DisputeAction? _action;
  final _notes = TextEditingController();
  final _creditPoints = TextEditingController();
  String _infractionCode = _infractionCodes.keys.first;

  /// Pesos corregidos por material, precargados con el registrado.
  late final Map<String, TextEditingController> _weights = {
    for (final r in widget.dispute.pickup?.results ?? const [])
      r.materialTypeId: TextEditingController(
        text: (r.actualWeightGrams / 1000).toStringAsFixed(2),
      ),
  };

  bool _sending = false;

  @override
  void dispose() {
    _notes.dispose();
    _creditPoints.dispose();
    for (final c in _weights.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Cada acción exige su propio dato. El DTO los declara opcionales pero
  /// los valida según la acción, así que frenarlo acá evita un 400.
  String? _validate() {
    if (_action == null) return 'Elegí una acción.';
    if (_notes.text.trim().isEmpty) return 'Las notas son obligatorias.';

    switch (_action!) {
      case DisputeAction.adjustWeight:
        if (_weights.isEmpty) return 'Este recojo no tiene pesaje que corregir.';
        for (final c in _weights.values) {
          final kg = double.tryParse(c.text.trim().replaceAll(',', '.'));
          if (kg == null) return 'Revisá los pesos: hay un valor inválido.';
          // El backend exige > 0.01 g; en kilos, cualquier cosa en cero.
          if (kg <= 0) return 'El peso debe ser mayor a cero.';
        }
      case DisputeAction.creditPoints:
        final n = int.tryParse(_creditPoints.text.trim());
        if (n == null || n < 0) return 'Indicá cuántos puntos acreditar.';
      case DisputeAction.penalizeRecycler:
      case DisputeAction.dismiss:
        break;
    }
    return null;
  }

  Future<void> _submit() async {
    final problem = _validate();
    if (problem != null) {
      _snack(problem, isError: true);
      return;
    }

    final ok = await confirmAction(
      context,
      title: _action!.label,
      consequence:
          '${_action!.help} La disputa queda cerrada y esto no se puede deshacer.',
      confirmLabel: 'Resolver',
    );
    if (!ok || !mounted) return;

    setState(() => _sending = true);
    try {
      await ref.read(disputesRepositoryProvider).resolve(
            id: widget.dispute.id,
            action: _action!,
            notes: _notes.text.trim(),
            adjustedWeights: _action == DisputeAction.adjustWeight
                ? [
                    for (final e in _weights.entries)
                      AdjustedWeight(
                        materialTypeId: e.key,
                        // El sistema trabaja en gramos; el campo se edita en
                        // kilos porque es como se piensa el material.
                        newWeightGrams:
                            double.parse(e.value.text.trim().replaceAll(',', '.')) * 1000,
                      ),
                  ]
                : null,
            creditPointsAmount: _action == DisputeAction.creditPoints
                ? int.parse(_creditPoints.text.trim())
                : null,
            penaltyInfractionCode:
                _action == DisputeAction.penalizeRecycler ? _infractionCode : null,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _sending = false);
      _snack(
        describeError(
          e,
          st,
          log: _log,
          operation: 'resolver la disputa',
          whereToCheck: 'la bandeja de disputas',
        ),
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
            const Text(
              'Resolver la disputa',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            RadioGroup<DisputeAction>(
              groupValue: _action,
              // RadioGroup.onChanged no admite null para deshabilitar, así
              // que el bloqueo mientras se envía va adentro.
              onChanged: (v) {
                if (_sending) return;
                setState(() => _action = v);
              },
              child: Column(
                children: [
                  for (final a in DisputeAction.values)
                    RadioListTile<DisputeAction>(
                      value: a,
                      title: Text(a.label, style: const TextStyle(fontSize: 14)),
                      subtitle: Text(a.help, style: const TextStyle(fontSize: 12)),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_action == DisputeAction.adjustWeight) ..._buildWeightFields(),
            if (_action == DisputeAction.creditPoints)
              TextField(
                controller: _creditPoints,
                enabled: !_sending,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Puntos a acreditar',
                  suffixText: 'pts',
                ),
              ),
            if (_action == DisputeAction.penalizeRecycler)
              DropdownButtonFormField<String>(
                initialValue: _infractionCode,
                decoration: const InputDecoration(labelText: 'Infracción'),
                items: [
                  for (final e in _infractionCodes.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged:
                    _sending ? null : (v) => setState(() => _infractionCode = v!),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              enabled: !_sending,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Notas de la resolución',
                // Es lo único que va a quedar para entender la decisión
                // dentro de seis meses.
                helperText: 'Obligatorio. Explicá por qué resolviste así.',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _sending ? null : _submit,
              child: _sending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Resolver'),
            ),
            TextButton(
              onPressed: _sending ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWeightFields() {
    final results = widget.dispute.pickup?.results ?? const <DisputeWeighIn>[];
    return [
      const Text(
        'Peso corregido',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),
      for (final r in results)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: _weights[r.materialTypeId],
            enabled: !_sending,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: r.materialName ?? 'Material',
              suffixText: 'kg',
              helperText:
                  'Registrado: ${(r.actualWeightGrams / 1000).toStringAsFixed(2)} kg',
            ),
          ),
        ),
    ];
  }
}
