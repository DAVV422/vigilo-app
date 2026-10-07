// lib/presentation/screens/dashboard/dashboard_screen.dart
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/incident.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_icons.dart';
import '../alerts/alerts_screen.dart';
import '../map/home_map_screen.dart';
import '../profile/profile_screen.dart';
import '../recycling/pickup_confirmation_screen.dart';
import '../store/store_screen.dart';
import '../../providers/providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const _log = AppLogger('Push');

  // Índice 0: Mapa (Vista activa inicial)

  final List<Widget> _screens = const [
    HomeMapScreen(),
    AlertsScreen(),
    StoreScreen(),
    ProfileScreen(),
  ];

  StreamSubscription<RemoteMessage>? _notificationTapSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(proximityNotifierProvider.notifier).start();
    });
    // En modo demo no hay Firebase inicializado (ver main.dart) — ni
    // siquiera se debe instanciar PushNotificationService, porque su
    // constructor accede a FirebaseMessaging.instance y eso explota con
    // "No Firebase App" si Firebase.initializeApp() nunca corrió.
    if (!AppConfig.demoMode) {
      _setUpNotificationTapHandling();
    }
  }

  void _setUpNotificationTapHandling() {
    final push = ref.read(pushNotificationServiceProvider);

    // App abierta desde terminada (cold start) tocando una notificación.
    push.getInitialMessage().then((message) {
      if (message != null) _handleNotificationTap(message);
    });

    // App en background y el usuario toca la notificación.
    _notificationTapSub = push.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  Future<void> _handleNotificationTap(RemoteMessage message) async {
    _log.info('Notificación push tocada: ${message.data}');

    final pickupId = message.data['pickupId'] as String?;
    if (message.data['type'] == 'PICKUP_PENDING_CONFIRMATION' && pickupId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PickupConfirmationScreen(pickupId: pickupId)),
      );
      return;
    }

    final incidentId = message.data['incidentId'] as String?;
    if (incidentId == null) {
      ref.read(currentNavIndexProvider.notifier).goToAlerts();
      return;
    }

    await ref.read(incidentsProvider.notifier).loadIncidents();
    if (!mounted) return;
    final incidents = ref.read(incidentsProvider);
    Incident? incident;
    for (final i in incidents) {
      if (i.id == incidentId) {
        incident = i;
        break;
      }
    }
    if (incident != null) {
      ref.read(selectedIncidentProvider.notifier).setIncident(incident);
    } else {
      // El incidente notificado no está en el radio cargado localmente;
      // igual mandamos al usuario a Alertas para que no quede varado.
      ref.read(currentNavIndexProvider.notifier).goToAlerts();
    }
  }

  @override
  void dispose() {
    ref.read(proximityNotifierProvider.notifier).stop();
    _notificationTapSub?.cancel();
    super.dispose();
  }

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
          if (index != 0) {
            ref.read(selectedIncidentProvider.notifier).clear();
          }
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
