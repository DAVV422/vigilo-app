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
import '../../../domain/entities/user.dart';
import '../../../screens/collections_screen.dart';
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


  StreamSubscription<RemoteMessage>? _notificationTapSub;

  /// Se guarda la referencia en vez de volver a pedirla en `dispose`, porque
  /// Riverpod prohíbe usar `ref` cuando el widget ya se está desmontando
  /// ("Using ref when a widget is about to or has been unmounted is unsafe").
  /// No saltaba antes porque el dashboard nunca se quitaba del árbol: al
  /// cerrar sesión la app se quedaba colgada en él. Al arreglar eso, este
  /// `dispose` empezó a ejecutarse de verdad. Guardar la instancia es seguro
  /// acá: `proximityNotifierProvider` cuelga del scope raíz y no es
  /// autoDispose, así que vive más que esta pantalla.
  ProximityNotifier? _proximity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _proximity = ref.read(proximityNotifierProvider.notifier);
      _proximity!.start();
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
      ref.read(currentTabProvider.notifier).goToAlerts();
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
      ref.read(currentTabProvider.notifier).goToAlerts();
    }
  }

  @override
  void dispose() {
    _proximity?.stop();
    _notificationTapSub?.cancel();
    super.dispose();
  }

  /// Pestañas visibles según los roles activos.
  ///
  /// `Recolecciones` no es una pantalla nueva: es [CollectionsScreen] —
  /// material disponible, recojos activos y reclamo—, que ya existía pero
  /// solo se alcanzaba desde un botón dentro del mapa. Un recolector que no
  /// descubriera ese botón no tenía cómo trabajar.
  ///
  /// `SECURITY_GUARD` y `TRASH_COLLECTOR` todavía caen en el layout de
  /// ciudadano: sus pantallas dependen de que exista la gestión de empresas
  /// (Fase C.2 del plan), porque hasta entonces no tienen una empresa a la
  /// que pertenecer ni una zona asignada.
  List<_TabSpec> _tabsFor(List<UserRole> roles) {
    final isRecycler = roles.contains(UserRole.recycling);
    // Sin roles se asume ciudadano: si el backend devolviera una lista vacía
    // —por ejemplo con todos los roles en PENDING— es preferible una app
    // usable a una barra con dos pestañas.
    final isCitizen = roles.contains(UserRole.normal) || !isRecycler;

    return [
      const _TabSpec(AppTab.map, HomeMapScreen(), AppIcons.map, 'Mapa'),
      if (isCitizen)
        const _TabSpec(AppTab.alerts, AlertsScreen(), AppIcons.notifications, 'Alertas'),
      if (isRecycler)
        const _TabSpec(
          AppTab.collections,
          CollectionsScreen(),
          AppIcons.recycling,
          'Recolecciones',
        ),
      const _TabSpec(AppTab.store, StoreScreen(), AppIcons.store, 'Tienda'),
      const _TabSpec(AppTab.profile, ProfileScreen(), AppIcons.person, 'Perfil'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabsFor(ref.watch(currentRolesProvider));
    final selected = ref.watch(currentTabProvider);

    // Se busca por identidad y no por posición: así, si la barra cambia de
    // composición mientras la app está abierta (al activarse el rol de
    // recolector), el usuario se queda en la pestaña donde estaba en vez de
    // saltar a la que haya quedado en ese índice. El -1 solo ocurre si la
    // pestaña activa dejó de existir para este rol; ahí, al mapa.
    final foundIndex = tabs.indexWhere((t) => t.tab == selected);
    final currentIndex = foundIndex < 0 ? 0 : foundIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: currentIndex,
        children: [for (final t in tabs) t.screen],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          final tab = tabs[index].tab;
          ref.read(currentTabProvider.notifier).goTo(tab);
          if (tab != AppTab.map) {
            ref.read(selectedIncidentProvider.notifier).clear();
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 8,
        items: [
          for (final t in tabs)
            BottomNavigationBarItem(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }
}

/// Una pestaña y todo lo que hace falta para pintarla. Antes la lista de
/// pantallas y la de ítems de la barra eran dos listas paralelas que había
/// que acordarse de editar juntas.
class _TabSpec {
  const _TabSpec(this.tab, this.screen, this.icon, this.label);

  final AppTab tab;
  final Widget screen;
  final IconData icon;
  final String label;
}
