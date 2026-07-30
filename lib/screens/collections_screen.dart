import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../presentation/providers/providers.dart';
import '../widgets/custom_app_bar.dart';

class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key});

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const CustomAppBar(
        title: 'Recolecciones',
        subtitle: 'Gestiona tus reservas',
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // A. Títulos Locales
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recolecciones', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text('Gestiona tus recolecciones pendientes y confirma las completadas.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // B. Tarjetas de Resumen
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildSummaryCard('0', 'Pendientes de recoger', Colors.orange.shade700),
                  const SizedBox(width: 8),
                  _buildSummaryCard('0', 'Completadas', Colors.teal.shade500),
                  const SizedBox(width: 8),
                  _buildSummaryCard('0kg', 'Kg recuperados', Colors.black87),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // C. Tarjeta de Estado Vacío
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.rotate(
                      angle: -0.3,
                      child: Icon(Icons.search, color: Colors.lightBlue.shade300, size: 60),
                    ),
                    const SizedBox(height: 16),
                    const Text('No tienes recolecciones pendientes', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Ve al mapa de reciclaje para encontrar materiales disponibles', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // D. Título de Sección
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('ALERTAS DISPONIBLES PARA RECOGER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
            ),
            const SizedBox(height: 12),

            // E. Lista de Alertas
            _buildAlertCard(Icons.shopping_bag, '3 bolsas grandes', 'Plan 3000 - Mañana 8-12hs', '+35 pts'),
            _buildAlertCard(Icons.delete_outline, '~5kg de latas', 'Equipetrol - Flexible', '+50 pts'),
            _buildAlertCard(Icons.tv, '1 microondas + 1 ventilador', 'Urbarí - Hoy', '+120 pts'),
            _buildAlertCard(Icons.wine_bar, '15 botellas de vidrio', 'Centro - Tarde', '+20 pts'),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, ref),
    );
  }

  Widget _buildSummaryCard(String value, String label, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: valueColor, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(IconData icon, String title, String subtitle, String reward) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(reward, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Reservar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, WidgetRef ref) {
    return BottomNavigationBar(
      currentIndex: 1, // Alertas is index 1
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
