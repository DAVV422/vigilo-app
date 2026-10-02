import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_exception.dart';
import '../domain/entities/citizen_summary.dart';
import '../domain/entities/incident.dart';
import '../presentation/providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/main_app_bar.dart';

/// Reescrito por completo. La versión anterior ("KPIs de Gestión Pública")
/// mostraba un ranking de 12 zonas de Santa Cruz y una "eficiencia por
/// entidad responsable" (Alcaldía, Emacruz...) con puntajes y una fórmula
/// ponderada — ninguno de esos conceptos existe en el modelo de datos (no
/// hay zonas geográficas ni desempeño de entidades registrado), así que
/// eran números inventados sin forma de volverse reales sin modelar algo
/// que el producto no tiene todavía. Se reemplaza por un resumen honesto:
/// tu actividad de reportes (real, de `/analytics/citizen-summary`) y un
/// desglose por tipo de los incidentes cercanos que ya carga el mapa.
class KpiScreen extends ConsumerStatefulWidget {
  const KpiScreen({super.key});

  @override
  ConsumerState<KpiScreen> createState() => _KpiScreenState();
}

class _KpiScreenState extends ConsumerState<KpiScreen> {
  CitizenSummary? _summary;
  bool _isLoading = true;
  String? _error;

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
      final summary = await ref.read(analyticsRepositoryProvider).getCitizenSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'No se pudo cargar el resumen de incidentes.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nearbyIncidents = ref.watch(incidentsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const MainAppBar(title: 'Resumen de incidentes'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError(_error!)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    children: [
                      _buildPersonalCard(_summary!),
                      const SizedBox(height: 16),
                      _buildNearbyCard(nearbyIncidents),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: AppColors.outline, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalCard(CitizenSummary summary) {
    final resolutionRate = summary.incidentsReported > 0
        ? (summary.incidentsResolved / summary.incidentsReported * 100)
        : 0.0;
    return _card(
      title: 'Tu actividad de reportes',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _stat('${summary.incidentsReported}', 'Reportados'),
          _stat('${summary.incidentsResolved}', 'Resueltos'),
          _stat('${summary.incidentsValidated}', 'Validados'),
          _stat('${resolutionRate.toStringAsFixed(0)}%', 'Tasa de\nresolución'),
        ],
      ),
    );
  }

  Widget _buildNearbyCard(List<Incident> incidents) {
    final active = incidents.where((i) => i.status == IncidentStatus.active).length;
    final resolved = incidents.where((i) => i.status == IncidentStatus.resolved).length;
    final byType = <IncidentType, int>{};
    for (final incident in incidents) {
      byType[incident.type] = (byType[incident.type] ?? 0) + 1;
    }

    return _card(
      title: 'Incidentes en tu zona',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('${incidents.length}', 'Total cercanos'),
              _stat('$active', 'Activos'),
              _stat('$resolved', 'Resueltos'),
            ],
          ),
          if (byType.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(color: AppColors.outlineVariant),
            const SizedBox(height: 12),
            const Text('Por categoría', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 10),
            ...byType.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_typeLabel(e.key), style: const TextStyle(fontSize: 13, color: AppColors.onSurface)),
                    Text('${e.value}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _typeLabel(IncidentType type) {
    switch (type) {
      case IncidentType.insecurity:
        return 'Inseguridad';
      case IncidentType.trash:
        return 'Basura';
      case IncidentType.weeds:
        return 'Maleza';
      case IncidentType.recycling:
        return 'Reciclaje';
      case IncidentType.streetLight:
        return 'Alumbrado público';
      case IncidentType.pothole:
        return 'Baches';
      case IncidentType.other:
        return 'Otro';
    }
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
