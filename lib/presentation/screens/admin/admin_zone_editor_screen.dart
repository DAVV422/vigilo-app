import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/geo/polygon_validation.dart';
import '../../../core/logging/app_logger.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import 'admin_coverage_zones_screen.dart' show santaCruzCenter;
import 'widgets/admin_scaffold.dart';

const _log = AppLogger('AdminZonas');

/// Dibuja una zona de cobertura.
///
/// **Se toca para poner cada punto; no se dibuja arrastrando.** En un mapa
/// táctil, arrastrar ya significa mover el mapa: poner un vértice y
/// desplazar la vista serían el mismo gesto, y ahí es donde este tipo de
/// editor se vuelve frustrante. Tocando, los dos gestos no se pisan nunca.
///
/// Para corregir se toca el punto otra vez y se borra, en vez de
/// arrastrarlo: en una pantalla de seis pulgadas acertarle a un círculo de
/// 24 píxeles para moverlo es incómodo, y "deshacer" resuelve el 90 % de
/// los casos reales.
///
/// El botón **Encuadrar** toma el rectángulo que se ve en pantalla. Las
/// tres zonas que ya existen son rectángulos, y no es casualidad: para
/// delimitar "la zona norte" o "el casco viejo" alcanza. Es el camino
/// rápido; el dibujo punto a punto queda para cuando hace falta precisión.
class AdminZoneEditorScreen extends ConsumerStatefulWidget {
  const AdminZoneEditorScreen({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  final String companyId;
  final String companyName;

  @override
  ConsumerState<AdminZoneEditorScreen> createState() =>
      _AdminZoneEditorScreenState();
}

class _AdminZoneEditorScreenState extends ConsumerState<AdminZoneEditorScreen> {
  final _mapController = MapController();
  final _name = TextEditingController();

  final List<LatLng> _vertices = [];
  bool _saving = false;
  bool _tilesFailed = false;

  @override
  void dispose() {
    _name.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _addVertex(LatLng point) {
    if (_saving) return;
    setState(() => _vertices.add(point));
  }

  void _removeVertex(int index) {
    if (_saving) return;
    setState(() => _vertices.removeAt(index));
  }

  void _undo() {
    if (_saving || _vertices.isEmpty) return;
    setState(() => _vertices.removeLast());
  }

  void _clear() {
    if (_saving || _vertices.isEmpty) return;
    setState(_vertices.clear);
  }

  /// Toma el rectángulo visible como zona.
  void _frame() {
    if (_saving) return;
    final b = _mapController.camera.visibleBounds;

    // Un margen chico para que el contorno se vea dentro de la pantalla en
    // vez de pegado al borde.
    final dLat = (b.north - b.south) * 0.06;
    final dLng = (b.east - b.west) * 0.06;

    setState(() {
      _vertices
        ..clear()
        ..addAll([
          LatLng(b.south + dLat, b.west + dLng),
          LatLng(b.south + dLat, b.east - dLng),
          LatLng(b.north - dLat, b.east - dLng),
          LatLng(b.north - dLat, b.west + dLng),
        ]);
    });
  }

  Future<void> _save() async {
    final nombre = _name.text.trim();
    if (nombre.isEmpty) {
      _snack('Ponele un nombre a la zona.', isError: true);
      return;
    }

    final problema = validateRing(_vertices);
    if (problema != null) {
      _snack(problema, isError: true);
      return;
    }

    final aviso = areaWarning(_vertices);
    if (aviso != null) {
      final seguir = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Revisá el tamaño'),
          content: Text(aviso),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Volver a dibujar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar igual'),
            ),
          ],
        ),
      );
      if (seguir != true || !mounted) return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(companiesRepositoryProvider).createZone(
            companyId: widget.companyId,
            name: nombre,
            vertices: _vertices,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(
        describeError(e, st,
            log: _log,
            operation: 'guardar la zona',
            whereToCheck: 'las zonas de la empresa'),
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
    final puntos = _vertices.length;
    final completa = puntos >= PolygonValidation.minVertices;

    return AdminScaffold(
      title: 'Nueva zona',
      actions: [
        IconButton(
          onPressed: _vertices.isEmpty ? null : _undo,
          icon: const Icon(Icons.undo),
          tooltip: 'Deshacer el último punto',
        ),
        IconButton(
          onPressed: _vertices.isEmpty ? null : _clear,
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Borrar todo',
        ),
      ],
      body: Column(
        children: [
          if (_tilesFailed)
            Container(
              width: double.infinity,
              color: AppColors.errorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text(
                // Sin mosaicos no se puede dibujar a ciegas: mejor decirlo
                // que mostrar un cuadrado gris y dejar que alguien dibuje
                // sobre la nada.
                'No se pudo cargar el mapa. Revisá la conexión antes de '
                'dibujar: sin ver las calles no hay forma de delimitar nada.',
                style: TextStyle(fontSize: 12, color: AppColors.onErrorContainer),
              ),
            ),
          Expanded(child: _buildMap()),
          _buildPanel(puntos, completa),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: santaCruzCenter,
            initialZoom: 13,
            onTap: (_, point) => _addVertex(point),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.vigilo.app',
              errorTileCallback: (_, _, _) {
                if (!_tilesFailed && mounted) {
                  // En el próximo cuadro: esto puede dispararse durante el
                  // build de la capa.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _tilesFailed = true);
                  });
                }
              },
            ),
            if (_vertices.length >= 3)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: _vertices,
                    // Se cierra solo en la vista previa: no hay que volver a
                    // tocar el primer punto.
                    color: AppColors.primary.withValues(alpha: 0.18),
                    borderColor: AppColors.primary,
                    borderStrokeWidth: 2,
                  ),
                ],
              )
            else if (_vertices.length == 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _vertices,
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (var i = 0; i < _vertices.length; i++)
                  Marker(
                    point: _vertices[i],
                    width: 30,
                    height: 30,
                    child: GestureDetector(
                      onTap: () => _removeVertex(i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.primary, width: 2.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: FloatingActionButton.small(
            heroTag: 'encuadrar',
            onPressed: _frame,
            tooltip: 'Usar el rectángulo visible',
            child: const Icon(Icons.crop_free),
          ),
        ),
      ],
    );
  }

  /// Mismo texto que `validateRing`, concordando singular y plural: la
  /// pantalla y el mensaje de error tienen que decir lo mismo.
  String _faltan(int n) => n == 1
      ? 'Falta un punto: una zona necesita al menos tres.'
      : 'Faltan $n puntos: una zona necesita al menos tres.';

  Widget _buildPanel(int puntos, bool completa) {
    final area = completa ? approximateAreaKm2(_vertices) : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            enabled: !_saving,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Nombre de la zona',
              hintText: 'Zona Norte: Equipetrol y Av. Banzer',
              counterText: '',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  completa
                      // El área en vivo: un cero de más se nota al instante.
                      ? '$puntos puntos · ${area.toStringAsFixed(2)} km²'
                      : puntos == 0
                          ? 'Tocá el mapa para poner el primer punto.'
                          : _faltan(PolygonValidation.minVertices - puntos),
                  style: TextStyle(
                    fontSize: 12,
                    color: completa
                        ? AppColors.onSurfaceVariant
                        : AppColors.tertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            // Deshabilitado hasta que haya un polígono: no tiene sentido
            // dejar guardar dos puntos y que falle el servidor.
            onPressed: (!completa || _saving) ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar zona'),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tocá un punto para borrarlo.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
