import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../presentation/providers/providers.dart';
import '../widgets/custom_app_bar.dart';

class PointsScreen extends ConsumerWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const CustomAppBar(
        title: 'Mis Puntos',
        subtitle: 'Historial y ranking',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildHeroCard(ref),
            const SizedBox(height: 20),
            _buildChartCard(),
            const SizedBox(height: 24),
            _buildEarnMoreGrid(),
            const SizedBox(height: 24),
            _buildHistoryList(),
            const SizedBox(height: 40), // Padding extra at bottom
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // Perfil
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
      ),
    );
  }



  Widget _buildHeroCard(WidgetRef ref) {
    final user = ref.watch(authProvider);
    final userPoints = user?.points ?? 350;

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
          Text('SALDO ACTUAL', style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$userPoints', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('puntos', style: TextStyle(color: Colors.grey.shade300, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
              const SizedBox(width: 6),
              Text('#7 en ranking', style: TextStyle(color: Colors.amber.shade400, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade800, thickness: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total ganado', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text('+130', style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total canjeado', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('-80', style: TextStyle(color: Colors.redAccent.shade100, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cómo ganaste tus puntos', style: TextStyle(color: AppColors.onBackground, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBar('Reportes', 105, 120, Colors.blue.shade300),
              _buildBar('Publicar', 15, 120, AppColors.primaryContainer),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double value, double max, Color color) {
    final double heightRatio = value / max;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(value.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 100 * heightRatio,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  Widget _buildEarnMoreGrid() {
    final List<Map<String, dynamic>> actions = [
      {'icon': Icons.public, 'title': 'Reportar problema urbano', 'pts': '+25 pts', 'sub': 'Por reporte enviado'},
      {'icon': Icons.recycling, 'title': 'Recoger material reciclable', 'pts': '+20-60 pts', 'sub': 'La mayor recompensa'},
      {'icon': Icons.security, 'title': 'Ser Guardia Vecinal', 'pts': 'Bonus x2', 'sub': ' '},
      {'icon': Icons.thumb_up, 'title': 'Validar reportes', 'pts': '+5 pts', 'sub': ' '},
      {'icon': Icons.check_circle, 'title': 'Asistir a eventos', 'pts': '+50 pts', 'sub': ' '},
      {'icon': Icons.emoji_events, 'title': 'Top 1 Semanal', 'pts': '+100 pts', 'sub': ' '},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('¿Cómo ganar más puntos?', style: TextStyle(color: AppColors.onBackground, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(action['icon'], color: AppColors.primary, size: 24),
                    const SizedBox(height: 8),
                    Text(action['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2)),
                    const SizedBox(height: 4),
                    Text(action['pts'], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    if ((action['sub'] as String).trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(action['sub'], style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                    ]
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final List<Map<String, dynamic>> history = [
      {'title': 'Confirmación de proximidad', 'date': '2026-08-18', 'val': '+5', 'pos': true},
      {'title': 'Canje: Bolsa de arroz 2kg', 'date': '2026-08-18', 'val': '-80', 'pos': false},
      {'title': 'Reporte urbano validado - Bache Av. Banzer', 'date': '2026-08-17', 'val': '+25', 'pos': true},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Historial de movimientos', style: TextStyle(color: AppColors.onBackground, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: history.length,
              separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100, height: 1),
              itemBuilder: (context, index) {
                final item = history[index];
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item['pos'] ? Colors.green.shade50 : Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item['pos'] ? Icons.arrow_upward : Icons.arrow_downward,
                        color: item['pos'] ? Colors.green.shade700 : Colors.red.shade700,
                        size: 18,
                      ),
                    ),
                    title: Text(item['title'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(item['date'], style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    trailing: Text(
                      item['val'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: item['pos'] ? Colors.green.shade600 : Colors.red.shade600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
