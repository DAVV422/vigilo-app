import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/coverage_zone.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import 'admin_zone_editor_screen.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/confirm_action_dialog.dart';

const _log = AppLogger('AdminZonas');

/// Santa Cruz de la Sierra. Se centra acá y no en la ubicación de quien
/// mira: el que dibuja una zona puede no estar parado en ella.
const santaCruzCenter = LatLng(-17.7833, -63.1821);

/// Las zonas de cobertura de una empresa, dibujadas sobre el mapa.
class AdminCoverageZonesScreen extends ConsumerStatefulWidget {
  const AdminCoverageZonesScreen({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  final String companyId;
  final String companyName;

  @override
  ConsumerState<AdminCoverageZonesScreen> createState() =>
      _AdminCoverageZonesScreenState();
}

class _AdminCoverageZonesScreenState
    extends ConsumerState<AdminCoverageZonesScreen> {
  List<CoverageZone> _zones = [];
  bool _isLoading = true;
  Object? _error;
  bool _changed = false;

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
      // Con las inactivas: si no, desactivar una zona la sacaría de la
      // única pantalla desde la que se puede volver a activar.
      final list = await ref
          .read(companiesRepositoryProvider)
          .getZones(widget.companyId, includeInactive: true);
      if (!mounted) return;
      setState(() {
        _zones = list;
        _isLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      describeError(e, st, log: _log, operation: 'cargar las zonas');
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Future<void> _create() async {
    final creada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminZoneEditorScreen(
          companyId: widget.companyId,
          companyName: widget.companyName,
        ),
      ),
    );
    if (creada == true) {
      _changed = true;
      await _load();
    }
  }

  Future<void> _toggle(CoverageZone z) async {
    if (z.active) {
      final ok = await confirmAction(
        context,
        title: 'Desactivar "${z.name}"',
        consequence:
            'Los incidentes nuevos que caigan en este territorio dejan de '
            'asignarse a ${widget.companyName}. Los ya asignados no cambian.',
        confirmLabel: 'Desactivar',
        isDestructive: true,
      );
      if (!ok || !mounted) return;
    }

    try {
      await ref.read(companiesRepositoryProvider).setZoneActive(
            companyId: widget.companyId,
            zoneId: z.id,
            active: !z.active,
          );
      if (!mounted) return;
      _changed = true;
      await _load();
    } catch (e, st) {
      if (!mounted) return;
      _snack(
        describeError(e, st,
            log: _log,
            operation: 'cambiar la zona',
            whereToCheck: 'la lista de zonas'),
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: AdminScaffold(
        title: 'Zonas de cobertura',
        onRefresh: _load,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _create,
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Nueva zona'),
        ),
        body: AdminAsyncView(
          isLoading: _isLoading,
          error: _error,
          onRetry: _load,
          isEmpty: _zones.isEmpty,
          emptyIcon: Icons.map_outlined,
          emptyTitle: 'Sin zonas de cobertura',
          emptyMessage:
              'Una zona es el territorio que atiende ${widget.companyName}. '
              'Los incidentes que se reporten adentro se le asignan solos. '
              'Sin ninguna zona, no recibe nada.',
          child: Column(
            children: [
              SizedBox(height: 280, child: _buildMap()),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                  children: [for (final z in _zones) _buildTile(z)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    final activas = _zones.where((z) => z.active && z.vertices.length >= 3);
    final inactivas = _zones.where((z) => !z.active && z.vertices.length >= 3);
    final todos = [for (final z in _zones) ...z.vertices];

    return FlutterMap(
      options: MapOptions(
        initialCenter: santaCruzCenter,
        initialZoom: 12,
        initialCameraFit: todos.length < 2
            ? null
            : CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(todos),
                padding: const EdgeInsets.all(28),
              ),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.vigilo.app',
        ),
        PolygonLayer(
          polygons: [
            // Las inactivas se dibujan apagadas en vez de ocultarse: saber
            // qué territorio *no* se está cubriendo es la mitad del sentido
            // de esta pantalla.
            for (final z in inactivas)
              Polygon(
                points: z.vertices,
                color: AppColors.outline.withValues(alpha: 0.10),
                borderColor: AppColors.outline,
                borderStrokeWidth: 1,
                pattern: StrokePattern.dashed(segments: const [6, 4]),
              ),
            for (final z in activas)
              Polygon(
                points: z.vertices,
                color: AppColors.primary.withValues(alpha: 0.18),
                borderColor: AppColors.primary,
                borderStrokeWidth: 2,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTile(CoverageZone z) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  z.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: z.active
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${z.areaKm2.toStringAsFixed(1)} km² · '
                  '${z.vertices.length} puntos',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(value: z.active, onChanged: (_) => _toggle(z)),
        ],
      ),
    );
  }
}
