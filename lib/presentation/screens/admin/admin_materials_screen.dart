import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/material_type.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import 'admin_material_detail_screen.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/admin_scaffold.dart';

const _log = AppLogger('AdminMateriales');

/// Materiales y su precio por kilo.
///
/// Es la única variable económica del producto: el precio por kilo decide
/// cuánto le paga el recolector al ciudadano, y los puntos por kilo deciden
/// cuánto vale reciclar. Hasta ahora los dos los ponía el seeder y
/// cambiarlos exigía entrar a la base por SQL.
class AdminMaterialsScreen extends ConsumerStatefulWidget {
  const AdminMaterialsScreen({super.key});

  @override
  ConsumerState<AdminMaterialsScreen> createState() =>
      _AdminMaterialsScreenState();
}

class _AdminMaterialsScreenState extends ConsumerState<AdminMaterialsScreen> {
  List<MaterialType> _materials = [];
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
      // Con los inactivos: si no, desactivar un material lo haría
      // desaparecer de la única pantalla que permite reactivarlo.
      final list = await ref
          .read(materialsRepositoryProvider)
          .getAll(includeInactive: true);
      if (!mounted) return;
      setState(() {
        _materials = list;
        _isLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      describeError(e, st, log: _log, operation: 'cargar los materiales');
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Future<void> _open(MaterialType m) async {
    final cambio = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminMaterialDetailScreen(materialId: m.id),
      ),
    );
    if (cambio == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Materiales y precios',
      onRefresh: _load,
      body: AdminAsyncView(
        isLoading: _isLoading,
        error: _error,
        onRetry: _load,
        isEmpty: _materials.isEmpty,
        emptyIcon: Icons.scale_outlined,
        emptyTitle: 'No hay materiales cargados',
        emptyMessage:
            'Los materiales se crean desde el servidor; todavía no se pueden '
            'dar de alta desde la app.',
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics:
              const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: [
            for (final m in _materials) _buildCard(m),
            const SizedBox(height: 16),
            const Text(
              'Los materiales nuevos se agregan desde el servidor. Acá se '
              'configuran los que ya existen.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(MaterialType m) {
    return Opacity(
      opacity: m.isActive ? 1 : 0.6,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border.all(color: AppColors.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () => _open(m),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              m.name,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (!m.isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.outline.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Inactivo',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m.category,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // La unidad siempre escrita: el sistema pesa en gramos y
                    // cobra por kilo, y un número suelto acá se malinterpreta.
                    Text(
                      m.currentPricePerKg > 0
                          ? 'Bs ${m.currentPricePerKg.toStringAsFixed(2)} / kg'
                          : 'Sin precio',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: m.currentPricePerKg > 0
                            ? AppColors.onSurface
                            : AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_fmt(m.pointsPerKg)} pts / kg',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sin decimales cuando no hacen falta: "10 pts / kg", no "10.0".
String _fmt(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
