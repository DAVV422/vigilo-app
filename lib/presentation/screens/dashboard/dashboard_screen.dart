// lib/presentation/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_icons.dart';
import '../alerts/alerts_screen.dart';
import '../map/home_map_screen.dart';
import '../profile/profile_screen.dart';
import '../store/store_screen.dart';
import '../../providers/providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Índice 0: Mapa (Vista activa inicial)

  final List<Widget> _screens = const [
    HomeMapScreen(),
    AlertsScreen(),
    StoreScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentNavIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(currentNavIndexProvider.notifier).setIndex(index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(AppIcons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(AppIcons.notifications),
            label: 'Alertas',
          ),
          BottomNavigationBarItem(
            icon: Icon(AppIcons.store),
            label: 'Tienda',
          ),
          BottomNavigationBarItem(
            icon: Icon(AppIcons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
