import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/dispute.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import 'admin_dispute_detail_screen.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/admin_scaffold.dart';

const _log = AppLogger('AdminDisputas');

/// Bandeja de disputas de pesaje.
///
/// Hasta ahora el ciudadano podía abrir una disputa y nadie podía cerrarla:
/// los tres endpoints de moderación existían sin que nada los llamara.
class AdminDisputesScreen extends ConsumerStatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  ConsumerState<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends ConsumerState<AdminDisputesScreen> {
  /// Abiertas por defecto: son las únicas que piden una acción.
  String? _filter = 'OPEN';

  List<Dispute> _disputes = [];
  bool _isLoading = true;
  Object? _error;

  static const _filters = {
    'OPEN': 'Abiertas',
    'RESOLVED': 'Resueltas',
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
      final list = await ref.read(disputesRepositoryProvider).getAll(status: _filter);
      if (!mounted) return;
      setState(() {
        _disputes = list;
        _isLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      describeError(e, st, log: _log, operation: 'cargar las disputas');
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Future<void> _open(Dispute d) async {
    final resolved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminDisputeDetailScreen(disputeId: d.id)),
    );
    if (resolved == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Disputas',
      onRefresh: _load,
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
              isEmpty: _disputes.isEmpty,
              emptyIcon: Icons.gavel_outlined,
              // Una bandeja vacía es una buena noticia, no un error.
              emptyTitle: _filter == 'OPEN'
                  ? 'No hay disputas abiertas'
                  : 'No hay disputas que mostrar',
              emptyMessage: _filter == 'OPEN'
                  ? 'Cuando alguien reclame un pesaje, va a aparecer acá.'
                  : null,
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics:
                    const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                children: _disputes.map(_buildCard).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Dispute d) {
    final (label, color) = switch (d.status) {
      'OPEN' => ('Abierta', AppColors.warning),
      'RESOLVED' => ('Resuelta', AppColors.primary),
      'REJECTED' => ('Rechazada', AppColors.outline),
      _ => (d.status, AppColors.onSurfaceVariant),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(
          color: d.isOpen ? AppColors.warning : AppColors.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _open(d),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    d.openedBy?.name ?? 'Usuario',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              d.reason,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              _relative(d.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _relative(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return 'hoy';
    if (days == 1) return 'ayer';
    if (days < 30) return 'hace $days días';
    final months = (days / 30).floor();
    return months == 1 ? 'hace 1 mes' : 'hace $months meses';
  }
}
