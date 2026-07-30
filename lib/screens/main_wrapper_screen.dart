import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vigilo/domain/entities/incident.dart';
import '../theme/app_colors.dart';
import 'home_map_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';
import 'store_screen.dart';
import '../widgets/proximity_alert_dialog.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(proximityNotifierProvider.notifier).start();
    });
  }

  @override
  void dispose() {
    ref.read(proximityNotifierProvider.notifier).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentNavIndexProvider);
    final selectedIncident = ref.watch(selectedIncidentProvider);
    final proximityIncidents = ref.watch(proximityNotifierProvider);

    Widget currentScreen;
    switch (currentIndex) {
      case 0:
        currentScreen = HomeMapScreen(incidentToShow: selectedIncident);
        break;
      case 1:
        currentScreen = const AlertsScreen();
        break;
      case 2:
        currentScreen = const StoreScreen();
        break;
      case 3:
        currentScreen = const ProfileScreen();
        break;
      default:
        currentScreen = const HomeMapScreen();
    }

    return Scaffold(
      body: Stack(
        children: [
          currentScreen,
          if (proximityIncidents.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 16.0,
              child: SafeArea(
                child: ProximityAlertDialog(
                  incident: proximityIncidents.first,
                  onDismiss: (permanently) {
                    if (permanently) {
                      ref.read(proximityNotifierProvider.notifier).permanentlyDismissAlert(proximityIncidents.first.id);
                    } else {
                      ref.read(proximityNotifierProvider.notifier).dismissAlert(proximityIncidents.first.id);
                    }
                  },
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          ref.read(currentNavIndexProvider.notifier).setIndex(index);
          if (index != 0) {
            ref.read(selectedIncidentProvider.notifier).clear();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alertas',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Tienda'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
