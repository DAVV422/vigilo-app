import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_exception.dart';
import '../domain/entities/platform_impact.dart';
import '../presentation/providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/main_app_bar.dart';

/// Reescrito contra `AnalyticsRepository.getPlatformImpact()`. La versión
/// anterior tenía 2026 kg, "Bs.385 de valor económico", una lista de 5
/// empresas compradoras y gráficos de evolución mensual/por zona — ninguno
/// de esos datos existe en el backend (no hay series de tiempo ni zonas
/// geográficas modeladas, y la plataforma no mueve dinero real todavía, ver
/// docs/decisiones.md #003), así que se quitaron en vez de inventarlos. Lo
/// que queda — kg totales, CO2 evitado, tasa de recuperación y el desglose
/// por material — sale de una agregación real sobre `recycling_pickups`.
class ImpactScreen extends ConsumerStatefulWidget {
  const ImpactScreen({super.key});

  @override
  ConsumerState<ImpactScreen> createState() => _ImpactScreenState();
}

class _ImpactScreenState extends ConsumerState<ImpactScreen> {
  PlatformImpact? _impact;
  bool _isLoading = true;
  String? _error;

  static const _palette = [
    Colors.lightBlue,
    Color(0xFFB86B1F),
    Colors.grey,
    Colors.teal,
    Colors.purple,
    Colors.green,
    Colors.indigo,
    Colors.brown,
  ];

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
      final impact = await ref.read(analyticsRepositoryProvider).getPlatformImpact();
      if (!mounted) return;
      setState(() {
        _impact = impact;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'No se pudo cargar el impacto de la plataforma.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const MainAppBar(title: 'Impacto de la comunidad'),
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
                      _buildHeroCard(_impact!),
                      const SizedBox(height: 16),
                      _buildCircularEconomyCard(_impact!),
                      const SizedBox(height: 16),
                      if (_impact!.materialBreakdown.isNotEmpty) _buildDonutChartCard(_impact!),
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

  Widget _buildHeroCard(PlatformImpact impact) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'IMPACTO TOTAL DE LA COMUNIDAD',
            style: TextStyle(color: AppColors.primaryFixed, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _heroStat('${impact.totalWeightKgRecycled.toStringAsFixed(1)} kg', 'Material recuperado'),
              _heroStat('${impact.activeRecyclers}', 'Recicladores activos'),
              _heroStat('${impact.co2AvoidedKg.toStringAsFixed(0)} kg', 'CO₂ evitado (est.)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: AppColors.primaryFixed, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildCircularEconomyCard(PlatformImpact impact) {
    return _card(
      title: 'Economía circular',
      child: Column(
        children: [
          _metricRow('Publicaciones creadas', '${impact.listingsPublished}'),
          _metricRow('Publicaciones completadas', '${impact.listingsCompleted}'),
          _metricRow('Tasa de recuperación', '${impact.retrievalRatePercent.toStringAsFixed(1)}%'),
          _metricRow('Puntos emitidos', '${impact.pointsIssued}'),
          _metricRow('Puntos canjeados', '${impact.pointsRedeemed}'),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        ],
      ),
    );
  }

  Widget _buildDonutChartCard(PlatformImpact impact) {
    final data = impact.materialBreakdown
        .asMap()
        .entries
        .map((e) => {
              'label': e.value.materialName,
              'color': _palette[e.key % _palette.length],
              'val': e.value.totalWeightKg == 0 ? 0.01 : e.value.totalWeightKg,
            })
        .toList();

    return _card(
      title: 'Kg recuperados por tipo de material',
      child: Column(
        children: [
          Center(
            child: SizedBox(
              height: 160,
              width: 160,
              child: CustomPaint(painter: _DonutChartPainter(data)),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: data
                .map(
                  (d) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: d['color'] as Color, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 4),
                      Text('${d['label']}', style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11)),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.onSurface, fontSize: 14)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _DonutChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 15;
    const strokeWidth = 25.0;

    double startAngle = -pi / 2;
    double total = data.fold(0.0, (sum, item) => sum + (item['val'] as double));
    if (total == 0) return;

    for (var d in data) {
      final sweepAngle = (d['val'] as double) / total * 2 * pi;
      final paint = Paint()
        ..color = d['color'] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, max(sweepAngle - 0.05, 0), false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
