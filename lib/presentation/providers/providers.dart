import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/api_client.dart';
import '../../core/push/push_notification_service.dart';
import '../../core/storage/secure_session_storage.dart';
import '../../data/datasources/local_json_datasource.dart';
import '../../data/datasources/remote/remote_auth_datasource.dart';
import '../../data/datasources/remote/remote_analytics_datasource.dart';
import '../../data/datasources/remote/remote_incident_datasource.dart';
import '../../data/datasources/remote/remote_media_datasource.dart';
import '../../data/datasources/remote/remote_notifications_datasource.dart';
import '../../data/datasources/remote/remote_ratings_datasource.dart';
import '../../data/datasources/remote/remote_recycling_datasource.dart';
import '../../data/datasources/remote/remote_store_datasource.dart';
import '../../data/demo/demo_state.dart';
import '../../data/models/company_model.dart';
import '../../data/models/store_product_model.dart';
import '../../data/repositories/demo_analytics_repository_impl.dart';
import '../../data/repositories/demo_auth_repository_impl.dart';
import '../../data/repositories/demo_media_repository_impl.dart';
import '../../data/repositories/demo_notifications_repository_impl.dart';
import '../../data/repositories/demo_points_repository_impl.dart';
import '../../data/repositories/demo_ratings_repository_impl.dart';
import '../../data/repositories/demo_recycling_repository_impl.dart';
import '../../data/repositories/demo_store_repository_impl.dart';
import '../../data/repositories/incident_repository_impl.dart';
import '../../data/repositories/remote_analytics_repository_impl.dart';
import '../../data/repositories/remote_auth_repository_impl.dart';
import '../../data/repositories/remote_incident_repository_impl.dart';
import '../../data/repositories/remote_media_repository_impl.dart';
import '../../data/repositories/remote_notifications_repository_impl.dart';
import '../../data/repositories/remote_points_repository_impl.dart';
import '../../data/repositories/remote_ratings_repository_impl.dart';
import '../../data/repositories/remote_recycling_repository_impl.dart';
import '../../data/repositories/remote_store_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/store_product.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/incident_repository.dart';
import '../../domain/repositories/media_repository.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../domain/repositories/points_repository.dart';
import '../../domain/entities/rating.dart';
import '../../domain/repositories/ratings_repository.dart';
import '../../domain/repositories/recycling_repository.dart';
import '../../domain/repositories/store_repository.dart';

// --- Datasources & Repositories ---
final localDatasourceProvider = Provider<LocalJsonDatasource>((ref) {
  return LocalJsonDatasource();
});

// Mantenido solo para `allUsersProvider` (pantallas que todavía listan el
// padrón local de usuarios semilla). El flujo de sesión real ya no pasa por
// aquí — ver authRepositoryProvider.
final userRepositoryProvider = Provider<UserRepositoryImpl>((ref) {
  final ds = ref.watch(localDatasourceProvider);
  return UserRepositoryImpl(ds);
});

// --- Infraestructura HTTP / sesión segura ---
final secureSessionStorageProvider = Provider<SecureSessionStorage>((ref) {
  return SecureSessionStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureSessionStorageProvider);
  return ApiClient(
    sessionStorage: storage,
    onSessionExpired: () async {
      ref.read(authProvider.notifier).forceLogoutLocally();
    },
  );
});

// --- Estado compartido del modo demo (ver AppConfig.demoMode) ---
// Un solo Provider (no autoDispose) para que todos los repos demo lean y
// muten el mismo estado en memoria durante toda la vida de la app.
final demoStateProvider = Provider<DemoState>((ref) => DemoState());

// --- Repositorios: backend real, o modo demo 100% local según AppConfig.demoMode ---
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.demoMode) {
    final ds = ref.watch(localDatasourceProvider);
    return DemoAuthRepositoryImpl(ds, ref.watch(demoStateProvider));
  }
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(secureSessionStorageProvider);
  return RemoteAuthRepositoryImpl(RemoteAuthDatasource(client), storage);
});

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  if (AppConfig.demoMode) {
    return IncidentRepositoryImpl(ref.watch(localDatasourceProvider));
  }
  final client = ref.watch(apiClientProvider);
  return RemoteIncidentRepositoryImpl(RemoteIncidentDatasource(client));
});

final pointsRepositoryProvider = Provider<PointsRepository>((ref) {
  if (AppConfig.demoMode) {
    return DemoPointsRepositoryImpl(ref.watch(demoStateProvider));
  }
  final client = ref.watch(apiClientProvider);
  return RemotePointsRepositoryImpl(RemoteAuthDatasource(client));
});

final recyclingRepositoryProvider = Provider<RecyclingRepository>((ref) {
  if (AppConfig.demoMode) {
    return DemoRecyclingRepositoryImpl(ref.watch(demoStateProvider));
  }
  final client = ref.watch(apiClientProvider);
  return RemoteRecyclingRepositoryImpl(RemoteRecyclingDatasource(client));
});

final ratingsRepositoryProvider = Provider<RatingsRepository>((ref) {
  if (AppConfig.demoMode) {
    return DemoRatingsRepositoryImpl(ref.watch(demoStateProvider));
  }
  final client = ref.watch(apiClientProvider);
  return RemoteRatingsRepositoryImpl(RemoteRatingsDatasource(client));
});

/// Reputación de un usuario. `family` porque la misma pantalla sirve para el
/// perfil propio y para mirar al otro lado de un recojo.
final userRatingsProvider =
    FutureProvider.family<UserRatings, String>((ref, userId) {
  return ref.watch(ratingsRepositoryProvider).getUserRatings(userId);
});

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  if (AppConfig.demoMode) {
    return DemoMediaRepositoryImpl();
  }
  final client = ref.watch(apiClientProvider);
  return RemoteMediaRepositoryImpl(RemoteMediaDatasource(client));
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  if (AppConfig.demoMode) {
    final ds = ref.watch(localDatasourceProvider);
    return DemoAnalyticsRepositoryImpl(ds, ref.watch(demoStateProvider));
  }
  final client = ref.watch(apiClientProvider);
  return RemoteAnalyticsRepositoryImpl(RemoteAnalyticsDatasource(client));
});

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  if (AppConfig.demoMode) {
    final ds = ref.watch(localDatasourceProvider);
    return DemoStoreRepositoryImpl(ds, ref.watch(demoStateProvider));
  }
  final client = ref.watch(apiClientProvider);
  return RemoteStoreRepositoryImpl(RemoteStoreDatasource(client));
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  if (AppConfig.demoMode) {
    return DemoNotificationsRepositoryImpl(ref.watch(demoStateProvider));
  }
  final client = ref.watch(apiClientProvider);
  return RemoteNotificationsRepositoryImpl(RemoteNotificationsDatasource(client));
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

// --- Auth State ---
final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

/// Roles activos del usuario en sesión; lista vacía si no hay sesión.
///
/// Derivado de [authProvider] a propósito, no estado nuevo: así cualquier
/// cosa que mueva la sesión —login, restauración, `reloadUser`, logout—
/// propaga sola y no hay dos fuentes de verdad que puedan discrepar.
final currentRolesProvider = Provider<List<UserRole>>((ref) {
  return ref.watch(authProvider)?.roles ?? const [];
});

/// Azúcar para las pantallas: `ref.watch(hasRoleProvider(UserRole.recycling))`.
final hasRoleProvider = Provider.family<bool, UserRole>((ref, role) {
  return ref.watch(currentRolesProvider).contains(role);
});

class AuthNotifier extends Notifier<User?> {
  static const _log = AppLogger('Auth');

  bool _bootstrapped = false;
  Future<void>? _restoring;

  /// Se completa cuando terminó el intento de restaurar la sesión guardada.
  ///
  /// `build()` no puede ser asíncrono, así que la restauración arranca en
  /// segundo plano y `state` queda en `null` hasta que responde. Quien
  /// necesite decidir algo en función de si hay sesión —el splash— tiene
  /// que esperar esto primero; mirar `state` antes es leer un `null` que
  /// solo significa "todavía no sé".
  Future<void> get ready => _restoring ?? Future<void>.value();

  @override
  User? build() {
    if (!_bootstrapped) {
      _bootstrapped = true;
      _restoring = _restoreSession();
      // En modo demo no hay backend al que registrar un token, y evitamos
      // tocar Firebase del todo (ver main.dart) — nada que escuchar acá.
      if (!AppConfig.demoMode) {
        final sub = ref.read(pushNotificationServiceProvider).onTokenRefresh.listen((token) {
          if (state != null) _registerPushToken(token: token);
        });
        ref.onDispose(sub.cancel);
      }
    }
    return null;
  }

  /// Best-effort: un fallo al pedir permiso o registrar el token no debe
  /// impedir que el usuario use la app, así que cualquier error se traga
  /// (pero sí queda constancia en el log para poder diagnosticarlo).
  Future<void> _registerPushToken({String? token}) async {
    if (AppConfig.demoMode) return;
    try {
      final push = ref.read(pushNotificationServiceProvider);
      final resolvedToken = token ?? await push.requestPermissionAndGetToken();
      if (resolvedToken == null) {
        _log.warning('No se obtuvo token push (permiso denegado o sin Play Services)');
        return;
      }
      await ref.read(notificationsRepositoryProvider).registerPushToken(
        token: resolvedToken,
        platform: push.platform,
      );
      _log.info('Token push registrado en el backend');
    } catch (e) {
      _log.warning('No se pudo registrar el token push: $e');
    }
  }

  Future<void> _restoreSession() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      state = await repo.restoreSession();
      if (state != null) {
        _log.info('Sesión restaurada para el usuario ${state!.id}');
        await _registerPushToken();
      } else {
        _log.info('No había sesión guardada que restaurar');
      }
    } catch (e) {
      _log.warning('Fallo al restaurar sesión: $e');
      state = null;
    }
  }

  /// Login contra el backend real. A diferencia del mock anterior, un error
  /// de credenciales SÍ debe tratarse como error — la pantalla de login es
  /// quien decide qué mostrar, esto solo propaga la excepción.
  Future<void> login(String email, String password) async {
    final repo = ref.read(authRepositoryProvider);
    try {
      state = await repo.login(email: email.trim(), password: password.trim());
      _log.info('Login exitoso para el usuario ${state!.id}');
    } catch (e) {
      _log.warning('Login fallido para "$email": $e');
      rethrow;
    }
    await _registerPushToken();
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
    String? phone,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    try {
      state = await repo.register(
        email: email.trim(),
        password: password,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        username: username.trim(),
        phone: phone?.trim(),
      );
      _log.info('Registro exitoso para el usuario ${state!.id}');
    } catch (e) {
      _log.warning('Registro fallido para "$email": $e');
      rethrow;
    }
    await _registerPushToken();
  }

  Future<void> reloadUser() async {
    if (state == null) return;
    final repo = ref.read(authRepositoryProvider);
    final refreshed = await repo.restoreSession();
    if (refreshed != null) state = refreshed;
  }

  Future<void> logout() async {
    final userId = state?.id;
    try {
      final pushToken = AppConfig.demoMode
          ? null
          : await ref.read(pushNotificationServiceProvider).getCurrentToken();
      await ref.read(authRepositoryProvider).logout(pushToken: pushToken);
      _log.info('Logout exitoso para el usuario $userId');
    } catch (e) {
      _log.warning('Logout del usuario $userId falló contra el backend (se limpia la sesión local igual): $e');
    } finally {
      state = null;
    }
  }

  /// Llamado por [ApiClient] cuando ni el access ni el refresh token sirven
  /// ya. Solo limpia el estado en memoria — la sesión guardada ya la borró
  /// el propio ApiClient.
  void forceLogoutLocally() {
    state = null;
  }
}

// --- Navigation State ---
final currentTabProvider = NotifierProvider<NavTabNotifier, AppTab>(
  () => NavTabNotifier(),
);
final selectedIncidentProvider =
    NotifierProvider<SelectedIncidentNotifier, Incident?>(
      () => SelectedIncidentNotifier(),
    );

/// Pestañas posibles de la barra inferior.
///
/// La navegación guarda *cuál* pestaña está activa, no en qué posición está.
/// La diferencia importa desde que la barra se arma según el rol: para un
/// ciudadano el índice 1 es Alertas, pero para un recolector sin rol
/// ciudadano es Recolecciones, y el índice 3 es Perfil con cuatro pestañas
/// y Tienda con cinco. Guardar un entero hacía que `setIndex(3)` llevara a
/// destinos distintos según quién hubiera iniciado sesión.
enum AppTab { map, alerts, collections, store, admin, profile }

class NavTabNotifier extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.map;

  void goTo(AppTab tab) {
    state = tab;
  }

  void goToMap() => goTo(AppTab.map);

  void goToAlerts() => goTo(AppTab.alerts);

  void goToStore() => goTo(AppTab.store);

  void goToProfile() => goTo(AppTab.profile);
}

class SelectedIncidentNotifier extends Notifier<Incident?> {
  @override
  Incident? build() => null;

  void setIncident(Incident? incident) {
    state = incident;
  }

  void clear() {
    state = null;
  }
}

// --- Incidents State ---
final incidentsProvider = NotifierProvider<IncidentsNotifier, List<Incident>>(
  IncidentsNotifier.new,
);

class IncidentsNotifier extends Notifier<List<Incident>> {
  @override
  List<Incident> build() {
    _initLoad();
    return [];
  }

  Future<void> _initLoad() async {
    final repo = ref.read(incidentRepositoryProvider);
    state = await repo.getIncidents();
  }

  Future<void> loadIncidents() async {
    await _initLoad();
  }

  // Nota: el backend real es la única fuente de verdad para los puntos (ver
  // docs/reglas-negocio.md). Ya no se calculan ni se escriben deltas aquí —
  // cada acción solo recarga el perfil para reflejar el saldo que el
  // servidor ya acreditó.
  Future<void> addIncident(Incident incident) async {
    final repo = ref.read(incidentRepositoryProvider);
    await repo.addIncident(incident);
    await ref.read(authProvider.notifier).reloadUser();
    await loadIncidents();
  }

  Future<void> validateIncident(
    String incidentId,
    String userId, {
    IncidentVote vote = IncidentVote.stillPresent,
  }) async {
    final repo = ref.read(incidentRepositoryProvider);
    await repo.validateIncident(incidentId, userId, vote: vote);
    await ref.read(authProvider.notifier).reloadUser();
    await loadIncidents();
  }

  Future<void> resolveIncident({
    required String incidentId,
    required String userId,
    String? companyId,
    String? companyName,
    required String comment,
    String? resolutionMediaId,
  }) async {
    final repo = ref.read(incidentRepositoryProvider);
    await repo.resolveIncident(
      incidentId: incidentId,
      userId: userId,
      companyId: companyId,
      companyName: companyName,
      comment: comment,
      resolutionMediaId: resolutionMediaId,
    );
    await ref.read(authProvider.notifier).reloadUser();
    await loadIncidents();
  }
}

// --- Users Provider ---
final allUsersProvider = FutureProvider<List<User>>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return await repo.getUsers();
});

// --- Companies Provider ---
final companiesProvider = NotifierProvider<CompaniesNotifier, List<Company>>(
  () => CompaniesNotifier(),
);

class CompaniesNotifier extends Notifier<List<Company>> {
  @override
  List<Company> build() {
    _loadCompanies();
    return [];
  }

  Future<void> _loadCompanies() async {
    final ds = ref.read(localDatasourceProvider);
    final data = await ds.readData();
    final companiesJson = data['companies'] as List<dynamic>;
    state = companiesJson
        .map((c) => CompanyModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateCompany(Company company) async {
    final ds = ref.read(localDatasourceProvider);
    await ds.updateCompany(CompanyModel.fromEntity(company));
    await _loadCompanies();
  }

  Company? getCompanyById(String id) {
    try {
      return state.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}

// --- Products Provider ---
final productsProvider = FutureProvider<List<StoreProduct>>((ref) async {
  final ds = ref.watch(localDatasourceProvider);
  final data = await ds.readData();
  final productsJson = data['products'] as List<dynamic>? ?? [];
  return productsJson
      .map((p) => StoreProductModel.fromJson(p as Map<String, dynamic>))
      .toList();
});

// --- Current Location (shared simulation + GPS) ---
final currentLocationProvider = StateProvider<LatLng>((ref) {
  return const LatLng(-17.783327, -63.182141);
});

// --- Proximity Alerts ---
final proximityNotifierProvider =
    NotifierProvider<ProximityNotifier, List<Incident>>(
      () => ProximityNotifier(),
    );

class ProximityNotifier extends Notifier<List<Incident>> {
  final Set<String> _notifiedIds = {};
  final Set<String> _permanentlyDismissedIds = {};
  Timer? _timer;

  @override
  List<Incident> build() {
    ref.onDispose(() => _timer?.cancel());
    return [];
  }

  void start() {
    _timer?.cancel();
    _check();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void checkNow() {
    _check();
  }

  void _check() {
    final location = ref.read(currentLocationProvider);
    final incidents = ref.read(incidentsProvider);
    final user = ref.read(authProvider);
    if (user == null) return;

    final activeIncidents = incidents
        .where((i) => i.status == IncidentStatus.active)
        .toList();

    final Set<String> currentlyInRange = {};

    for (final incident in activeIncidents) {
      final distance = Geolocator.distanceBetween(
        location.latitude,
        location.longitude,
        incident.location.latitude,
        incident.location.longitude,
      );
      if (distance <= 200) {
        currentlyInRange.add(incident.id);
        if (!_notifiedIds.contains(incident.id) && !_permanentlyDismissedIds.contains(incident.id)) {
          _notifiedIds.add(incident.id);
          state = [...state, incident];
        }
      }
    }
    
    // Remove from notified if they are no longer in range!
    _notifiedIds.removeWhere((id) => !currentlyInRange.contains(id));

    // Remove from state if they are no longer in range (auto-dismiss)
    if (state.isNotEmpty) {
      final newState = state.where((i) => currentlyInRange.contains(i.id)).toList();
      if (newState.length != state.length) {
        state = newState;
      }
    }
  }

  void dismissAlert(String incidentId) {
    state = state.where((i) => i.id != incidentId).toList();
  }

  void permanentlyDismissAlert(String incidentId) {
    _permanentlyDismissedIds.add(incidentId);
    state = state.where((i) => i.id != incidentId).toList();
  }
}
