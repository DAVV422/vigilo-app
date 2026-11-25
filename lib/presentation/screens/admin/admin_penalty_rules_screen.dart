import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/penalty.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import 'admin_penalty_rule_form_screen.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/admin_scaffold.dart';

const _log = AppLogger('AdminSanciones');

/// Las políticas de sanción: cuánto se descuenta por cada infracción y cómo
/// escala con la reincidencia.
///
/// Es la pantalla con más alcance de la fase: un multiplicador mal puesto no
/// falla, y se nota recién cuando alguien pierde todo su saldo.
class AdminPenaltyRulesScreen extends ConsumerStatefulWidget {
  const AdminPenaltyRulesScreen({super.key});

  @override
  ConsumerState<AdminPenaltyRulesScreen> createState() =>
      _AdminPenaltyRulesScreenState();
}

class _AdminPenaltyRulesScreenState
    extends ConsumerState<AdminPenaltyRulesScreen> {
  List<PenaltyRule> _rules = [];
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await ref.read(penaltiesRepositoryProvider).getRules();
      if (!mounted) return;
      setState(() {
        _rules = list;
        _isLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      describeError(e, st, log: _log, operation: 'cargar las reglas');
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Future<void> _open(PenaltyRule r) async {
    final cambio = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminPenaltyRuleFormScreen(rule: r)),
    );
    if (cambio == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Reglas de sanción',
      onRefresh: _load,
      body: AdminAsyncView(
        isLoading: _isLoading,
        error: _error,
        onRetry: _load,
        isEmpty: _rules.isEmpty,
        emptyIcon: Icons.rule_outlined,
        emptyTitle: 'No hay reglas cargadas',
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics:
              const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: [
            for (final r in _rules) _buildCard(r),
            const SizedBox(height: 16),
            const Text(
              'Las infracciones nuevas se agregan desde el servidor. Acá se '
              'ajusta el castigo de las que ya existen.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(PenaltyRule r) {
    return Opacity(
      opacity: r.active ? 1 : 0.6,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border.all(color: AppColors.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () => _open(r),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.label,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (!r.active)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.outline.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Inactiva',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: 6),
                // La escala es lo que esta pantalla existe para gobernar, y
                // es invisible si solo se muestran los puntos base.
                Text(
                  _escalaResumida(r),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Se cuentan las reincidencias de los últimos '
                  '${r.evaluationWindowDays} días · suspende en la '
                  '${r.suspensionThresholdOccurrences}.ª',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// «1.ª −10 · 2.ª −20 · 3.ª −40 pts», con la aritmética del servidor.
String _escalaResumida(PenaltyRule r) {
  final tramos = [
    for (var n = 1; n <= 3; n++) '$n.ª −${r.pointsForOccurrence(n)}',
  ];
  return '${tramos.join(' · ')} pts';
}
