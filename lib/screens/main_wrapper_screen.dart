import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import 'home_map_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';
import '../presentation/providers/providers.dart';

class MainWrapperScreen extends ConsumerStatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  ConsumerState<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends ConsumerState<MainWrapperScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentNavIndexProvider);
    final selectedIncident = ref.watch(selectedIncidentProvider);

    Widget currentScreen;
    switch (currentIndex) {
      case 0:
        currentScreen = HomeMapScreen(incidentToShow: selectedIncident);
        break;
      case 1:
        currentScreen = const AlertsScreen();
        break;
      case 2:
        currentScreen = const ProfileScreen();
        break;
      default:
        currentScreen = const HomeMapScreen();
    }

    return Scaffold(
      body: currentScreen,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          ref.read(currentNavIndexProvider.notifier).state = index;
          if (index != 0) {
            ref.read(selectedIncidentProvider.notifier).clear();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alertas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}