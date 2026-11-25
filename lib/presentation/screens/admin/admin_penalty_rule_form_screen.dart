import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/penalty.dart';
import '../../../domain/repositories/penalties_repository.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/confirm_action_dialog.dart';

const _log = AppLogger('AdminSanciones');

/// Edición de una regla de sanción.
///
/// Mientras se escriben los números, la pantalla muestra **cuánto se
/// descontaría en cada reincidencia**. Sin eso, la escala es un
/// multiplicador abstracto y nadie puede ver que subirlo de 2 a 4 convierte
/// la cuarta falta de 80 puntos en 640.
class AdminPenaltyRuleFormScreen extends ConsumerStatefulWidget {
  const AdminPenaltyRuleFormScreen({super.key, required this.rule});

  final PenaltyRule rule;

  @override
  ConsumerState<AdminPenaltyRuleFormScreen> createState() =>
      _AdminPenaltyRuleFormScreenState();
}

class _AdminPenaltyRuleFormScreenState
    extends ConsumerState<AdminPenaltyRuleFormScreen> {
  late final _description =
      TextEditingController(text: widget.rule.description);
  late final _base =
      TextEditingController(text: '${widget.rule.basePointsDeducted}');
  late final _multiplier = TextEditingController(
      text: widget.rule.escalationMultiplier.toStringAsFixed(2));
  late final _window =
      TextEditingController(text: '${widget.rule.evaluationWindowDays}');
  late final _warning = TextEditingController(
      text: '${widget.rule.warningThresholdOccurrences}');
  late final _suspension = TextEditingController(
      text: '${widget.rule.suspensionThresholdOccurrences}');

  late bool _active = widget.rule.active;
  bool _saving = false;

  @override
  void dispose() {
    _description.dispose();
    _base.dispose();
    _multiplier.dispose();
    _window.dispose();
    _warning.dispose();
    _suspension.dispose();
    super.dispose();
  }

  int? _int(TextEditingController c) => int.tryParse(c.text.trim());
  double? _double(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  /// La regla tal como quedaría con lo que hay escrito ahora mismo.
  PenaltyRule? get _preview {
    final base = _int(_base);
    final mult = _double(_multiplier);
    final susp = _int(_suspension);
    if (base == null || mult == null || susp == null) return null;
    return PenaltyRule(
      id: widget.rule.id,
      infractionCode: widget.rule.infractionCode,
      description: _description.text,
      basePointsDeducted: base,
      escalationMultiplier: mult,
      evaluationWindowDays: _int(_window) ?? widget.rule.evaluationWindowDays,
      warningThresholdOccurrences:
          _int(_warning) ?? widget.rule.warningThresholdOccurrences,
      suspensionThresholdOccurrences: susp,
      active: _active,
    );
  }

  String? _validate() {
    if (_description.text.trim().isEmpty) return 'Falta la descripción.';

    final base = _int(_base);
    if (base == null || base < 0) return 'Los puntos base no son válidos.';

    final mult = _double(_multiplier);
    // El servidor exige >= 1.0: por debajo, reincidir costaría menos.
    if (mult == null || mult < 1.0) {
      return 'El multiplicador tiene que ser 1,00 o mayor.';
    }

    final window = _int(_window);
    if (window == null || window < 1) return 'La ventana no es válida.';

    final warning = _int(_warning);
    final susp = _int(_suspension);
    if (warning == null || warning < 1) return 'El umbral de aviso no es válido.';
    if (susp == null || susp < 1) return 'El umbral de suspensión no es válido.';
    if (susp < warning) {
      return 'La suspensión no puede llegar antes que el aviso.';
    }
    return null;
  }

  Future<void> _save() async {
    final problema = _validate();
    if (problema != null) {
      _snack(problema, isError: true);
      return;
    }

    final p = _preview!;
    final mult = p.escalationMultiplier;

    // Un multiplicador alto no falla y no se nota hasta que alguien pierde
    // el saldo entero. Se avisa con el número concreto, no en abstracto.
    if (mult > 5.0) {
      final ok = await confirmAction(
        context,
        title: 'Revisá el multiplicador',
        consequence:
            'Con ${_fmt(mult)}, la 4.ª reincidencia descuenta '
            '${p.pointsForOccurrence(4)} puntos. ¿Es lo que querés?',
        confirmLabel: 'Sí, guardar',
      );
      if (!ok || !mounted) return;
    }

    if (widget.rule.active && !_active) {
      final ok = await confirmAction(
        context,
        title: 'Desactivar «${widget.rule.label}»',
        consequence:
            'Deja de poder aplicarse. Las sanciones ya aplicadas con esta '
            'regla no cambian.',
        confirmLabel: 'Desactivar',
        isDestructive: true,
      );
      if (!ok || !mounted) return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(penaltiesRepositoryProvider).updateRule(
            widget.rule.id,
            PenaltyRuleInput(
              description: _description.text.trim(),
              basePointsDeducted: p.basePointsDeducted,
              escalationMultiplier: p.escalationMultiplier,
              evaluationWindowDays: p.evaluationWindowDays,
              warningThresholdOccurrences: p.warningThresholdOccurrences,
              suspensionThresholdOccurrences: p.suspensionThresholdOccurrences,
              active: _active,
            ),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(
        describeError(e, st,
            log: _log,
            operation: 'guardar la regla',
            whereToCheck: 'las reglas de sanción'),
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
    return AdminScaffold(
      title: widget.rule.label,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPreview(),
          const SizedBox(height: 16),
          TextField(
            controller: _description,
            enabled: !_saving,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              helperText: 'Qué hizo la persona para merecer esta sanción.',
              helperMaxLines: 2,
            ),
          ),
          const SizedBox(height: 16),
          _number(
            controller: _base,
            label: 'Puntos base',
            suffix: 'pts',
            help: 'Lo que se descuenta la primera vez.',
          ),
          const SizedBox(height: 14),
          _number(
            controller: _multiplier,
            label: 'Multiplicador por reincidencia',
            suffix: '×',
            help: 'Cada repetición multiplica el descuento por este número.',
            decimal: true,
          ),
          const SizedBox(height: 14),
          _number(
            controller: _window,
            label: 'Ventana de evaluación',
            suffix: 'días',
            help: 'Solo cuentan las faltas dentro de este plazo.',
          ),
          const SizedBox(height: 14),
          _number(
            controller: _warning,
            label: 'Aviso a partir de la',
            suffix: '.ª falta',
            help: null,
          ),
          const SizedBox(height: 14),
          _number(
            controller: _suspension,
            label: 'Suspensión a partir de la',
            suffix: '.ª falta',
            help: 'Desde acá la sanción deja de ser una advertencia.',
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            value: _active,
            onChanged: _saving ? null : (v) => setState(() => _active = v),
            contentPadding: EdgeInsets.zero,
            title: const Text('Activa', style: TextStyle(fontSize: 14)),
            subtitle: Text(
              _active
                  ? 'Se puede aplicar.'
                  : 'No se puede aplicar. Lo ya aplicado no cambia.',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar regla'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final p = _preview;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CON ESTOS NÚMEROS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          if (p == null)
            const Text(
              'Completá los números para ver el efecto.',
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            )
          else
            for (var n = 1; n <= 5; n++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        '$n.ª falta',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      '−${p.pointsForOccurrence(n)} pts',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 10),
                    if (p.suspendsAt(n))
                      const Text(
                        'suspensión',
                        style: TextStyle(fontSize: 11, color: AppColors.error),
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _number({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required String? help,
    bool decimal = false,
  }) {
    return TextField(
      controller: controller,
      enabled: !_saving,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      // La vista previa se recalcula con cada tecla: es lo que hace visible
      // el efecto de un multiplicador.
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        helperText: help,
        helperMaxLines: 2,
      ),
    );
  }
}

String _fmt(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
