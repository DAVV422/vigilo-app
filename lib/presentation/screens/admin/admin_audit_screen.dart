import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/audit_entry.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import 'admin_audit_entry_screen.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/admin_scaffold.dart';

const _log = AppLogger('AdminBitacora');

/// La bitácora de auditoría.
///
/// Se abre cuando alguien pregunta «¿quién cambió esto?». Por eso pagina en
/// vez de desplazarse infinito: se consulta buscando algo concreto, y saber
/// que hay 39 páginas y poder ir a la última vale más que un
/// desplazamiento que nunca termina sobre una lista que crece mientras se
/// la lee.
class AdminAuditScreen extends ConsumerStatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  ConsumerState<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends ConsumerState<AdminAuditScreen> {
  AuditPage? _pageData;
  bool _isLoading = true;
  Object? _error;

  int _page = 1;
  String? _entityType;
  bool _onlyFailed = false;
  DateTimeRange? _range;

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
      final data = await ref.read(auditRepositoryProvider).query(
            page: _page,
            limit: 50,
            entityType: _entityType,
            // El filtro de acción es coincidencia exacta, así que se
            // compone en vez de pedirle a nadie que escriba
            // `POST_FAILED_COMPANIES` de memoria. Solo tiene sentido con
            // una entidad elegida.
            action: (_onlyFailed && _entityType != null)
                ? 'POST_FAILED_$_entityType'
                : null,
            startDate: _range?.start,
            endDate: _range?.end,
          );
      if (!mounted) return;
      setState(() {
        _pageData = data;
        _isLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      describeError(e, st, log: _log, operation: 'cargar la bitácora');
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickRange() async {
    final ahora = DateTime.now();
    final elegido = await showDateRangePicker(
      context: context,
      firstDate: DateTime(ahora.year - 2),
      lastDate: ahora,
      initialDateRange: _range,
      helpText: 'Rango de fechas',
      saveText: 'Aplicar',
    );
    if (elegido == null || !mounted) return;
    setState(() {
      // El fin se lleva al final del día: si no, un rango de un solo día
      // no devuelve nada y parece que no hubiera registros.
      _range = DateTimeRange(
        start: elegido.start,
        end: DateTime(
          elegido.end.year,
          elegido.end.month,
          elegido.end.day,
          23,
          59,
          59,
        ),
      );
      _page = 1;
    });
    await _load();
  }

  void _open(AuditEntry e) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminAuditEntryScreen(entry: e)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _pageData;

    return AdminScaffold(
      title: 'Bitácora',
      onRefresh: _load,
      actions: [
        IconButton(
          onPressed: _pickRange,
          icon: Icon(
            Icons.date_range_outlined,
            color: _range != null ? AppColors.primary : null,
          ),
          tooltip: 'Filtrar por fechas',
        ),
      ],
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: AdminAsyncView(
              isLoading: _isLoading,
              error: _error,
              onRetry: _load,
              isEmpty: data != null && data.entries.isEmpty,
              emptyIcon: Icons.history_outlined,
              emptyTitle: AppConfig.demoMode
                  ? 'La bitácora vive en el servidor'
                  : _page > 1
                      ? 'No hay más registros'
                      : 'No hay registros que coincidan',
              emptyMessage: AppConfig.demoMode
                  ? 'El modo demo no registra actividad porque no hay un '
                      'servidor que la escriba.'
                  : _page > 1
                      ? 'Te pasaste de la última página.'
                      : 'Probá quitando algún filtro.',
              child: data == null
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics()),
                            children: data.entries.map(_buildRow).toList(),
                          ),
                        ),
                        _buildPager(data),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Todo'),
                    selected: _entityType == null,
                    onSelected: (_) {
                      setState(() {
                        _entityType = null;
                        _onlyFailed = false;
                        _page = 1;
                      });
                      _load();
                    },
                  ),
                ),
                for (final entry in AuditEntry.entityLabels.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: _entityType == entry.key,
                      onSelected: (_) {
                        setState(() {
                          _entityType = entry.key;
                          _page = 1;
                        });
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (_entityType != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: _onlyFailed,
                    onChanged: (v) {
                      setState(() {
                        _onlyFailed = v ?? false;
                        _page = 1;
                      });
                      _load();
                    },
                  ),
                  const Text(
                    'Solo las que fallaron',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          if (_range != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Del ${_fecha(_range!.start)} al ${_fecha(_range!.end)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _range = null;
                        _page = 1;
                      });
                      _load();
                    },
                    child: const Text('Quitar'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(AuditEntry e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(
          color: e.failed ? AppColors.error : AppColors.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _open(e),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: e.failed ? AppColors.error : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      // «Sin sesión» y no «desconocido»: son afirmaciones
                      // distintas, y esta es la correcta.
                      e.actor?.fullName ?? 'Sin sesión',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ),
                  Text(
                    _relativo(e.createdAt),
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

  Widget _buildPager(AuditPage data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: data.hasPrevious
                ? () {
                    setState(() => _page = 1);
                    _load();
                  }
                : null,
            icon: const Icon(Icons.first_page),
            tooltip: 'Primera',
          ),
          IconButton(
            onPressed: data.hasPrevious
                ? () {
                    setState(() => _page -= 1);
                    _load();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              'Página ${data.page} de ${data.totalPages} · '
              '${data.total} ${data.total == 1 ? "registro" : "registros"}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ),
          IconButton(
            onPressed: data.hasNext
                ? () {
                    setState(() => _page += 1);
                    _load();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            onPressed: data.hasNext
                ? () {
                    setState(() => _page = data.totalPages);
                    _load();
                  }
                : null,
            icon: const Icon(Icons.last_page),
            tooltip: 'Última',
          ),
        ],
      ),
    );
  }

  String _fecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  String _relativo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'recién';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 30) return 'hace ${diff.inDays} días';
    final meses = (diff.inDays / 30).floor();
    return meses == 1 ? 'hace 1 mes' : 'hace $meses meses';
  }
}
