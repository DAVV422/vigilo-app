import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../presentation/providers/providers.dart';
import '../widgets/custom_app_bar.dart';

class KpiScreen extends ConsumerWidget {
  const KpiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const CustomAppBar(
        title: 'KPIs de Gestión Pública',
        subtitle: 'Indicadores de eficiencia municipal - Santa Cruz',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40, top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(),
            const SizedBox(height: 16),
            _buildKpiGrid(),
            const SizedBox(height: 16),
            _buildSemaforoCard(),
            const SizedBox(height: 16),
            _buildLineChartCard(),
            const SizedBox(height: 16),
            _buildRankingCard(),
            const SizedBox(height: 16),
            _buildBarChartCard(),
            const SizedBox(height: 16),
            _buildEficienciaCard(),
            const SizedBox(height: 16),
            _buildMetodologiaCard(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, ref),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.onBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ÍNDICE DE EFICIENCIA URBANA',
            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('57', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text('/100', style: TextStyle(color: Colors.grey.shade400, fontSize: 20)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text('Gestión regular — hay áreas críticas', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    final kpis = [
      {'title': 'Total Reportes', 'val': '15', 'sub': '', 'icon': Icons.assignment},
      {'title': 'Resueltos', 'val': '5', 'sub': 'este mes', 'icon': Icons.check_circle_outline, 'color': Colors.green},
      {'title': 'Pendientes', 'val': '7', 'sub': '1 vencidos', 'icon': Icons.pending_actions, 'color': Colors.orange},
      {'title': 'Tasa de Resolución', 'val': '33.3%', 'sub': '', 'icon': Icons.pie_chart_outline},
      {'title': 'Tiempo Promedio', 'val': '14.6', 'sub': 'días', 'icon': Icons.timer_outlined},
      {'title': 'Cumplimiento de Plazo', 'val': '60%', 'sub': '', 'icon': Icons.event_available},
      {'title': 'Validación Ciudadana', 'val': '75%', 'sub': 'resoluciones confirmadas', 'icon': Icons.how_to_reg},
      {'title': 'Presión Urbana', 'val': '2.8', 'sub': 'rep/km²', 'icon': Icons.compress},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: kpis.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
        ),
        itemBuilder: (context, index) {
          final k = kpis[index];
          final Color iconColor = k['color'] as Color? ?? AppColors.primary;
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        k['title'] as String,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(k['icon'] as IconData, color: iconColor, size: 16),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        k['val'] as String,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      if ((k['sub'] as String).isNotEmpty)
                        Text(k['sub'] as String, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSemaforoCard() {
    final items = [
      {'label': 'Tasa de resolución', 'pct': '33.3%', 'color': Colors.red},
      {'label': 'Cumplimiento de plazos', 'pct': '60%', 'color': Colors.orange},
      {'label': 'Validación ciudadana', 'pct': '75%', 'color': Colors.orange},
      {'label': 'Nivel de transparencia', 'pct': '66%', 'color': Colors.orange},
      {'label': 'No-reincidencia', 'pct': '82%', 'color': Colors.orange},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Semáforo de gestión', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15)),
          const SizedBox(height: 12),
          ...items.map((item) {
            final c = item['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['label'] as String, style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w500)),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(item['pct'] as String, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLineChartCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Evolución mensual 2026', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('16', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('12', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('8', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('4', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('0', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomPaint(
                    painter: _SimpleLineChartPainter(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('Ene', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('Feb', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('Mar', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('Abr', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('May', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(width: 16, height: 2, color: Colors.blue),
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(width: 6),
                  const Text('Reportes', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(width: 16, height: 2, color: Colors.green),
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(width: 6),
                  const Text('Resueltos', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard() {
    final rows = [
      {'z': 'Equipetrol', 'rep': '15', 'res': '12', 'tasa_str': '80%', 'tasa': 80.0, 'efi': 88},
      {'z': 'Las Palmas', 'rep': '4', 'res': '4', 'tasa_str': '100%', 'tasa': 100.0, 'efi': 95},
      {'z': 'Plan 3000', 'rep': '5', 'res': '5', 'tasa_str': '100%', 'tasa': 100.0, 'efi': 90},
      {'z': 'Urbarí', 'rep': '10', 'res': '8', 'tasa_str': '80%', 'tasa': 80.0, 'efi': 85},
      {'z': 'Hamacas', 'rep': '7', 'res': '4', 'tasa_str': '57.1%', 'tasa': 57.1, 'efi': 60},
      {'z': 'Sur', 'rep': '12', 'res': '6', 'tasa_str': '50%', 'tasa': 50.0, 'efi': 55},
      {'z': 'Cambódromo', 'rep': '18', 'res': '9', 'tasa_str': '50%', 'tasa': 50.0, 'efi': 50},
      {'z': 'Norte', 'rep': '8', 'res': '3', 'tasa_str': '37.5%', 'tasa': 37.5, 'efi': 45},
      {'z': 'El Cristo', 'rep': '6', 'res': '2', 'tasa_str': '33.3%', 'tasa': 33.3, 'efi': 40},
      {'z': 'Palermo', 'rep': '3', 'res': '1', 'tasa_str': '33.3%', 'tasa': 33.3, 'efi': 35},
      {'z': 'Villa 1ro de Mayo', 'rep': '20', 'res': '5', 'tasa_str': '25%', 'tasa': 25.0, 'efi': 30},
      {'z': 'Centro', 'rep': '2', 'res': '0', 'tasa_str': '0%', 'tasa': 0.0, 'efi': 15},
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ranking de zonas — Reportes y Eficiencia', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 550, // Permite tener amplio espacio para las columnas sin apretarse
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 24, child: Text('#', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))),
                      Expanded(child: Text('ZONA', style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 70, child: Text('REPORTES', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 70, child: Text('RESUELTOS', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 60, child: Text('TASA %', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 80, child: Text('EFICIENCIA', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  ...rows.asMap().entries.map((e) {
                    final idx = e.key + 1;
                    final item = e.value;
                    final isTasaCien = (item['tasa'] as double) == 100.0;
                    final isTasaCero = (item['tasa'] as double) == 0.0;
                    final efiVal = item['efi'] as int;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          SizedBox(width: 24, child: Text('$idx', style: TextStyle(color: Colors.grey.shade500, fontSize: 12))),
                          Expanded(child: Text(item['z'] as String, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                          SizedBox(
                            width: 70,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                                child: Text(item['rep'] as String, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 70,
                            child: Text(item['res'] as String, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade800, fontSize: 13)),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              item['tasa_str'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isTasaCien ? Colors.green : (isTasaCero ? Colors.red : Colors.grey.shade800),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: efiVal / 100.0,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(efiVal >= 50 ? Colors.green : Colors.red),
                                      minHeight: 4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('$efiVal', style: TextStyle(color: Colors.grey.shade800, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartCard() {
    final data = [
      {'label': 'Baches y vías', 'val': 4, 'color': Colors.redAccent},
      {'label': 'Basura acumulada', 'val': 3, 'color': Colors.orangeAccent},
      {'label': 'Alcantarillas', 'val': 2, 'color': Colors.blueAccent},
      {'label': 'Iluminación', 'val': 1, 'color': Colors.amber},
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reportes por categoría', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15)),
          const SizedBox(height: 16),
          ...data.map((item) {
            final ratio = (item['val'] as int) / 5.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(item['label'] as String, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: (ratio * 100).toInt(),
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(color: item['color'] as Color, borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                        Expanded(
                          flex: ((1 - ratio) * 100).toInt(),
                          child: const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${item['val']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEficienciaCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Eficiencia por entidad responsable', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15)),
          const SizedBox(height: 16),
          _buildEntidadItem('Alcaldía - Obras Públicas', '72/100', 0.72, Colors.green, '7 rep - 43% res.', true),
          const SizedBox(height: 12),
          _buildEntidadItem('Emacruz (Aseo)', '45/100', 0.45, Colors.orange, '3 rep - 33% res.', false),
          const SizedBox(height: 12),
          _buildEntidadItem('Alumbrado Público', '20/100', 0.20, Colors.red, '1 rep - 0% res.', false),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: const [
                Icon(Icons.emoji_events, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Mejor eficiencia: Alcaldía - Obras Públicas', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: const [
                Icon(Icons.warning, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Mayor carga sin resolver: Alcaldía - Obras Públicas', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntidadItem(String name, String scoreText, double progress, Color color, String detail, bool hasMedal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (hasMedal) ...[const Icon(Icons.workspace_premium, color: Colors.amber, size: 16), const SizedBox(width: 4)],
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            Text(scoreText, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(detail, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }

  Widget _buildMetodologiaCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.onBackground, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Metodología de cálculo — Índice de Eficiencia Urbana', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildMetodologiaCell('35%', 'Tasa resolución', 'Resueltos / Recibidos')),
              const SizedBox(width: 12),
              Expanded(child: _buildMetodologiaCell('25%', 'Cumplimiento', 'Dentro del plazo')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetodologiaCell('25%', 'Validación', 'Confirmados por ciudad')),
              const SizedBox(width: 12),
              Expanded(child: _buildMetodologiaCell('15%', 'No-reincidencia', 'Sin reportes repetidos')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetodologiaCell(String pct, String title, String form) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(pct, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 2),
          Text(form, style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, WidgetRef ref) {
    return BottomNavigationBar(
      currentIndex: 0,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        Navigator.pop(context);
        ref.read(currentNavIndexProvider.notifier).setIndex(index);
        if (index != 0) {
          ref.read(selectedIncidentProvider.notifier).clear();
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alertas'),
        BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Tienda'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }
}

class _SimpleLineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 4; i++) {
      final y = size.height - (i * size.height / 4);
      for (double x = 0; x < size.width; x += 10) {
        canvas.drawLine(Offset(x, y), Offset(x + 5, y), gridPaint);
      }
    }

    final double stepX = size.width / 4;
    final reportes = [8.0, 11.0, 9.0, 14.0, 15.0];
    final resueltos = [6.0, 7.0, 8.0, 9.0, 5.0];

    _drawLine(canvas, size, stepX, reportes, Colors.blue);
    _drawLine(canvas, size, stepX, resueltos, Colors.green);
  }

  void _drawLine(Canvas canvas, Size size, double stepX, List<double> values, Color color) {
    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final Paint dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height - (values[i] / 16.0 * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = size.height - (values[i - 1] / 16.0 * size.height);
        
        final cp1X = prevX + (x - prevX) / 2;
        final cp1Y = prevY;
        final cp2X = prevX + (x - prevX) / 2;
        final cp2Y = y;
        
        path.cubicTo(cp1X, cp1Y, cp2X, cp2Y, x, y);
      }
    }
    
    canvas.drawPath(path, linePaint);
    
    // Draw points on top of the line
    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height - (values[i] / 16.0 * size.height);
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
