import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/penalty.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../widgets/admin/lift_penalty_sheet.dart';
import 'admin_apply_penalty_screen.dart';
import 'admin_penalty_rules_screen.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/admin_scaffold.dart';

const _log = AppLogger('AdminSanciones');

/// Historial de sanciones aplicadas.
///
/// Es la entrada de la sección: desde acá se llega a las reglas que
/// gobiernan el castigo y a aplicar una sanción nueva.
class AdminPenaltiesScreen extends ConsumerStatefulWidget {
  const AdminPenaltiesScreen({super.key});

  @override
  ConsumerState<AdminPenaltiesScreen> createState() =>
      _AdminPenaltiesScreenState();
}

class _AdminPenaltiesScreenState extends ConsumerState<AdminPenaltiesScreen> {
  /// Vigentes por defecto: son las que todavía tienen efecto.
  String? _filter = 'ACTIVE';

  List<Penalty> _penalties = [];
  bool _isLoading = true;
  Object? _error;

  static const _filters = {
    'ACTIVE': 'Vigentes',
    'LIFTED': 'Levantadas',
    null: 'Todas',
  };

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
      final list = await ref
          .read(penaltiesRepositoryProvider)
          .getPenalties(status: _filter);
      if (!mounted) return;
      setState(() {
        _penalties = list;
        _isLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      describeError(e, st, log: _log, operation: 'cargar las sanciones');
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Future<void> _open(Penalty p) async {
    final levantada = await showPenaltySheet(context, penalty: p);
    if (levantada == true) await _load();
  }

  Future<void> _apply() async {
    final aplicada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminApplyPenaltyScreen()),
    );
    if (aplicada == true) await _load();
  }

  void _openRules() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminPenaltyRulesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Sanciones',
      onRefresh: _load,
      actions: [
        IconButton(
          onPressed: _openRules,
          icon: const Icon(Icons.rule_outlined),
          tooltip: 'Reglas de sanción',
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _apply,
        icon: const Icon(Icons.gavel_outlined),
        label: const Text('Sancionar'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                for (final entry in _filters.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: _filter == entry.key,
                      onSelected: (_) {
                        setState(() => _filter = entry.key);
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AdminAsyncView(
              isLoading: _isLoading,
              error: _error,
              onRetry: _load,
              isEmpty: _penalties.isEmpty,
              emptyIcon: Icons.verified_user_outlined,
              // Una lista vacía de sanciones es una buena noticia.
              emptyTitle: _filter == 'ACTIVE'
                  ? 'No hay sanciones vigentes'
                  : 'No hay sanciones que mostrar',
              emptyMessage: _filter == 'ACTIVE'
                  ? 'Nadie tiene una sanción con efecto en este momento.'
                  : null,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                children: _penalties.map(_buildCard).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Penalty p) {
    final (label, color) = switch (p.status) {
      'ACTIVE' => ('Vigente', AppColors.error),
      'LIFTED' => ('Levantada', AppColors.primary),
      'EXPIRED' => ('Vencida', AppColors.outline),
      _ => (p.statusLabel, AppColors.onSurfaceVariant),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(
          color: p.isActive ? AppColors.error : AppColors.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _open(p),
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
                      p.userName ?? 'Usuario',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${p.infractionLabel} · ${p.occurrenceNumber}.ª falta',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                p.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '−${p.pointsDeducted} pts',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.isLifted
                          ? AppColors.onSurfaceVariant
                          : AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    p.typeLabel,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Text(
                    _relativo(p.startsAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativo(DateTime date) {
    final dias = DateTime.now().difference(date).inDays;
    if (dias <= 0) return 'hoy';
    if (dias == 1) return 'ayer';
    if (dias < 30) return 'hace $dias días';
    final meses = (dias / 30).floor();
    return meses == 1 ? 'hace 1 mes' : 'hace $meses meses';
  }
}
