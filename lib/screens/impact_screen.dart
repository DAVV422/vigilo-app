import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../presentation/providers/providers.dart';
import '../widgets/custom_app_bar.dart';

class ImpactScreen extends ConsumerStatefulWidget {
  const ImpactScreen({super.key});

  @override
  ConsumerState<ImpactScreen> createState() => _ImpactScreenState();
}

class _ImpactScreenState extends ConsumerState<ImpactScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: const CustomAppBar(
        title: 'Dashboard de Impacto',
        subtitle: 'Economía circular y reciclaje social - Santa Cruz',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // 2. Hero Card
              _buildHeroCard(),
              const SizedBox(height: 16),

              // 3. Economía Circular
              _buildCircularEconomyCard(),
              const SizedBox(height: 16),

              // 4. Quick Metrics Grid 2x2
              _buildQuickMetricsGrid(),
              const SizedBox(height: 16),

              // 5. Evolución kg (Area Chart)
              _buildAreaChartCard(),
              const SizedBox(height: 16),

              // 6. Donut Chart
              _buildDonutChartCard(),
              const SizedBox(height: 16),

              // 7. Grouped Bar Chart
              _buildGroupedBarCard(),
              const SizedBox(height: 16),

              // 8. Bar Chart
              _buildBarChartCard(),
              const SizedBox(height: 24),

              // 9. Empresas List
              _buildEmpresasList(),
              const SizedBox(height: 24),

              // 10. Impacto Social (Dark Card)
              _buildSocialImpactCard(),
              const SizedBox(height: 32),
            ],
          ),
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
        color: const Color(0xFF00B074), // Verde esmeralda
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF00B074).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('IMPACTO TOTAL ACUMULADO 2025', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: const [
                        Text('81', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        Text('kg', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Materiales\nrecuperados', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('4', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Recolectores\nactivos', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Bs.385', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Valor económico\ngenerado', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularEconomyCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ECONOMÍA CIRCULAR', style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          _buildRowItem('CO2 evitado (est.)', '~146kg', Colors.green, true),
          const Divider(),
          _buildRowItem('Alertas publicadas', '12', Colors.black87, true),
          const Divider(),
          _buildRowItem('Tasa de retiro', '42%', Colors.orange, true),
          const Divider(),
          _buildRowItem('Productos canjeados', '23', Colors.black87, true),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(30)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.eco, color: Colors.green.shade700, size: 16),
                const SizedBox(width: 8),
                Text('Índice de circularidad: 42%', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRowItem(String title, String val, Color valColor, bool boldVal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          Text(val, style: TextStyle(color: valColor, fontSize: 13, fontWeight: boldVal ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildQuickMetricsGrid() {
    final metrics = [
      {'title': 'Alertas publicadas', 'val': '12', 'icon': Icons.inventory_2, 'color': Colors.orange},
      {'title': 'Alertas recogidas', 'val': '5', 'icon': Icons.recycling, 'color': Colors.green},
      {'title': 'Puntos emitidos', 'val': '2840', 'icon': Icons.star, 'color': Colors.purple},
      {'title': 'Puntos canjeados', 'val': '1450', 'icon': Icons.local_mall, 'color': Colors.pink},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: metrics.map((m) {
          final color = m['color'] as Color;
          return Container(
            width: (MediaQuery.of(context).size.width - 44) / 2,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(m['title'] as String, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold))),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(m['icon'] as IconData, color: color, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(m['val'] as String, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAreaChartCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Evolución de kg recuperados 2025', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapUp: (details) {
                  final values = [25.0, 35.0, 42.0, 65.0, 80.0];
                  final months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo'];
                  final stepX = constraints.maxWidth / (values.length - 1);
                  final index = (details.localPosition.dx / stepX).round();
                  if (index >= 0 && index < values.length) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${months[index]}: ${values[index]} kg recuperados'), duration: const Duration(seconds: 2)));
                  }
                },
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: CustomPaint(painter: _AreaChartPainter()),
                ),
              );
            }
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Ene', style: TextStyle(color: Colors.grey, fontSize: 11)),
              Text('Feb', style: TextStyle(color: Colors.grey, fontSize: 11)),
              Text('Mar', style: TextStyle(color: Colors.grey, fontSize: 11)),
              Text('Abr', style: TextStyle(color: Colors.grey, fontSize: 11)),
              Text('May', style: TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDonutChartCard() {
    final data = [
      {'label': 'Plástico', 'color': Colors.lightBlue, 'val': 40.0},
      {'label': 'Cartón', 'color': Colors.orange.shade800, 'val': 25.0},
      {'label': 'Metal', 'color': Colors.grey, 'val': 10.0},
      {'label': 'Muebles/otro', 'color': Colors.orange.shade300, 'val': 10.0},
      {'label': 'Ropa', 'color': Colors.purple, 'val': 5.0},
      {'label': 'Botellas', 'color': Colors.teal, 'val': 5.0},
      {'label': 'Vidrio', 'color': Colors.green, 'val': 5.0},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kg recuperados por tipo de material', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15)),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTapUp: (details) {
                final center = const Offset(80, 80);
                final dx = details.localPosition.dx - center.dx;
                final dy = details.localPosition.dy - center.dy;
                final distance = sqrt(dx * dx + dy * dy);
                if (distance >= 50 && distance <= 90) {
                  double angle = atan2(dy, dx);
                  if (angle < -pi / 2) angle += 2 * pi;
                  angle += pi / 2;
                  if (angle < 0) angle += 2 * pi;
                  
                  double total = data.fold(0.0, (sum, item) => sum + (item['val'] as double));
                  double currentAngle = 0;
                  for (var d in data) {
                    final sweepAngle = (d['val'] as double) / total * 2 * pi;
                    if (angle >= currentAngle && angle <= currentAngle + sweepAngle) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${d['label']}: ${d['val']} kg'), duration: const Duration(seconds: 2)));
                      break;
                    }
                    currentAngle += sweepAngle;
                  }
                }
              },
              child: SizedBox(
                height: 160,
                width: 160,
                child: CustomPaint(painter: _DonutChartPainter(data)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: data.map((d) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: d['color'] as Color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 4),
                Text(d['label'] as String, style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedBarCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Actividad de reciclaje por zona de Santa Cruz', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapUp: (details) {
                  final zones = ['Equipetrol', 'Norte', 'Hamacas', 'Villa 1ro de Mayo', 'Las Palmas'];
                  final zonesData = [[18.0, 4.0], [14.0, 3.0], [12.0, 2.0], [9.0, 1.0], [5.0, 1.0]];
                  final spacing = constraints.maxWidth / zones.length;
                  final index = (details.localPosition.dx / spacing).floor();
                  if (index >= 0 && index < zones.length) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${zones[index]}: ${zonesData[index][0]} kg recuperados'), duration: const Duration(seconds: 2)));
                  }
                },
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: CustomPaint(painter: _GroupedBarChartPainter()),
                ),
              );
            }
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('Equipetrol', style: TextStyle(color: Colors.grey, fontSize: 9)),
              Text('Norte', style: TextStyle(color: Colors.grey, fontSize: 9)),
              Text('Hamacas', style: TextStyle(color: Colors.grey, fontSize: 9)),
              Text('Villa 1ro', style: TextStyle(color: Colors.grey, fontSize: 9)),
              Text('Las Palmas', style: TextStyle(color: Colors.grey, fontSize: 9)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBarChartCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Puntos emitidos vs canjeados', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapUp: (details) {
                  final values = [300.0, 450.0, 800.0, 1000.0, 1200.0];
                  final months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo'];
                  final spacing = constraints.maxWidth / values.length;
                  final index = (details.localPosition.dx / spacing).floor();
                  if (index >= 0 && index < values.length) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${months[index]}: ${values[index].toInt()} pts emitidos'), duration: const Duration(seconds: 2)));
                  }
                },
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: CustomPaint(painter: _SimpleBarChartPainter()),
                ),
              );
            }
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Ene', style: TextStyle(color: Colors.grey, fontSize: 11)),
              Text('Feb', style: TextStyle(color: Colors.grey, fontSize: 11)),
              Text('Mar', style: TextStyle(color: Colors.grey, fontSize: 11)),
              Text('Abr', style: TextStyle(color: Colors.grey, fontSize: 11)),
              Text('May', style: TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Puntos emitidos', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    const Text('2840', style: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Canjeados (51%)', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    const Text('1450', style: TextStyle(color: Colors.pink, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmpresasList() {
    final empresas = [
      {'name': 'RecicloBolivia SCZ', 'type': 'Múltiples', 'zones': '3 zonas'},
      {'name': 'MetalCruz Reciclaje', 'type': 'Metal', 'zones': '2 zonas'},
      {'name': 'Verde PET S.R.L.', 'type': 'Plástico', 'zones': '4 zonas'},
      {'name': 'Vidrios del Oriente', 'type': 'Vidrio', 'zones': '1 zona'},
      {'name': 'RopaCircular Bolivia', 'type': 'Ropa', 'zones': '2 zonas'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Empresas compradoras de material', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16)),
          const SizedBox(height: 12),
          ...empresas.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.business, color: Colors.blue, size: 20),
                ),
                title: Text(e['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(e['type']!, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(e['zones']!, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                    const Text('Activa', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildSocialImpactCard() {
    final items = [
      {'icon': Icons.accessibility_new, 'val': '4', 'text': 'Personas en situación vulnerable activas como recolectoras'},
      {'icon': Icons.shopping_cart, 'val': '23', 'text': 'Productos de primera necesidad canjeados este mes'},
      {'icon': Icons.attach_money, 'val': 'Bs.385', 'text': 'Valor económico generado por recolectores'},
      {'icon': Icons.eco, 'val': '146kg', 'text': 'CO2 equivalente evitado en la atmósfera'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Impacto social estimado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: items.map((e) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(e['icon'] as IconData, color: Colors.greenAccent, size: 24),
                  const SizedBox(height: 12),
                  Text(e['val'] as String, style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(e['text'] as String, style: TextStyle(color: Colors.grey.shade400, fontSize: 10, height: 1.2)),
                ],
              ),
            )).toList(),
          )
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

// -------------------------------------------------------------
// Custom Painters para Gráficos
// -------------------------------------------------------------

class _AreaChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Grid Lines
    final gridPaint = Paint()..color = Colors.grey.shade200..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height - (i * size.height / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Line and Area
    final values = [25.0, 35.0, 42.0, 65.0, 80.0];
    final maxVal = 100.0;
    final stepX = size.width / (values.length - 1);

    Path linePath = Path();
    Path areaPath = Path();
    
    areaPath.moveTo(0, size.height);
    
    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height - (values[i] / maxVal * size.height);
      
      if (i == 0) {
        linePath.moveTo(x, y);
        areaPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        areaPath.lineTo(x, y);
      }
    }
    
    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    final paintLine = Paint()..color = Colors.green..strokeWidth = 3..style = PaintingStyle.stroke;
    final paintArea = Paint()
      ..shader = LinearGradient(
        colors: [Colors.green.withOpacity(0.3), Colors.green.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(areaPath, paintArea);
    canvas.drawPath(linePath, paintLine);
    
    // Dots
    final dotPaint = Paint()..color = Colors.green;
    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height - (values[i] / maxVal * size.height);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _DonutChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 15;
    final strokeWidth = 25.0;

    double startAngle = -pi / 2;
    double total = data.fold(0.0, (sum, item) => sum + (item['val'] as double));

    for (var d in data) {
      final sweepAngle = (d['val'] as double) / total * 2 * pi;
      final paint = Paint()
        ..color = d['color'] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle - 0.05, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GroupedBarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = Colors.grey.shade200..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height - (i * size.height / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final zonesData = [
      [18.0, 4.0], // Equipetrol
      [14.0, 3.0], // Norte
      [12.0, 2.0], // Hamacas
      [9.0, 1.0],  // Villa 1ro
      [5.0, 1.0],  // Las Palmas
    ];
    
    final maxVal = 20.0;
    final groupWidth = size.width / zonesData.length;
    final barWidth = 12.0;
    final spacing = 4.0;

    for (int i = 0; i < zonesData.length; i++) {
      final centerX = (i * groupWidth) + (groupWidth / 2);
      final startX = centerX - barWidth - (spacing / 2);

      // Green Bar
      final h1 = (zonesData[i][0] / maxVal) * size.height;
      final paint1 = Paint()..color = Colors.green..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(startX, size.height - h1, barWidth, h1), const Radius.circular(4)),
        paint1
      );

      // Blue Bar
      final h2 = (zonesData[i][1] / maxVal) * size.height;
      final paint2 = Paint()..color = Colors.blue.shade200..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(startX + barWidth + spacing, size.height - h2, barWidth, h2), const Radius.circular(4)),
        paint2
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SimpleBarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = Colors.grey.shade200..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height - (i * size.height / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final values = [300.0, 450.0, 800.0, 1000.0, 1200.0]; // Ene - May
    final maxVal = 1200.0;
    final barWidth = 24.0;
    final spacing = size.width / values.length;

    final paint = Paint()..color = Colors.purple.shade300..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final h = (values[i] / maxVal) * size.height;
      final x = (i * spacing) + (spacing / 2) - (barWidth / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - h, barWidth, h), const Radius.circular(6)),
        paint
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
