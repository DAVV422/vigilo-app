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
  bool _isShowingProximityDialog = false;

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

    ref.listen<List<Incident>>(proximityNotifierProvider, (prev, next) {
      if (next.isNotEmpty && !_isShowingProximityDialog) {
        _isShowingProximityDialog = true;
        final incident = next.first;
        showDialog(
          context: context,
          builder: (ctx) => ProximityAlertDialog(
            incident: incident,
            onDismiss: () {
              ref
                  .read(proximityNotifierProvider.notifier)
                  .dismissAlert(incident.id);
              _isShowingProximityDialog = false;
            },
          ),
        ).then((_) => _isShowingProximityDialog = false);
      }
    });

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
