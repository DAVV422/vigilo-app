import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../data/datasources/local_json_datasource.dart';
import '../../data/models/company_model.dart';
import '../../data/repositories/incident_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/models/store_product_model.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/store_product.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/user.dart';

// --- Datasources & Repositories ---
final localDatasourceProvider = Provider<LocalJsonDatasource>((ref) {
  return LocalJsonDatasource();
});

final incidentRepositoryProvider = Provider<IncidentRepositoryImpl>((ref) {
  final ds = ref.watch(localDatasourceProvider);
  return IncidentRepositoryImpl(ds);
});

final userRepositoryProvider = Provider<UserRepositoryImpl>((ref) {
  final ds = ref.watch(localDatasourceProvider);
  return UserRepositoryImpl(ds);
});

// --- Auth State ---
final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends Notifier<User?> {
  @override
  User? build() {
    _loadSavedUser();
    return null;
  }

  Future<void> _loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('userEmail');
    final savedPassword = prefs.getString('userPassword');

    if (savedEmail != null && savedPassword != null) {
      final repo = ref.read(userRepositoryProvider);
      final user = await repo.login(savedEmail, savedPassword);
      if (user != null) {
        state = user;
      }
    }
  }

  Future<bool> login(String email, String password) async {
    final repo = ref.read(userRepositoryProvider);
    final user = await repo.login(email, password);
    if (user != null) {
      state = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userEmail', email);
      await prefs.setString('userPassword', password);
      return true;
    }
    return false;
  }

  Future<void> reloadUser() async {
    if (state == null) return;
    final repo = ref.read(userRepositoryProvider);
    final users = await repo.getUsers();
    final updatedUser = users.firstWhere(
      (u) => u.id == state!.id,
      orElse: () => state!,
    );
    state = updatedUser;
  }

  Future<void> logout() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userEmail');
    await prefs.remove('userPassword');
  }
}

// --- Navigation State ---
final currentNavIndexProvider = NotifierProvider<NavIndexNotifier, int>(
  () => NavIndexNotifier(),
);
final selectedIncidentProvider =
    NotifierProvider<SelectedIncidentNotifier, Incident?>(
      () => SelectedIncidentNotifier(),
    );

class NavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }

  void goToMap() {
    state = 0;
  }

  void goToAlerts() {
    state = 1;
  }

  void goToStore() {
    state = 2;
  }

  void goToProfile() {
    state = 3;
  }
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

  Future<void> addIncident(Incident incident) async {
    final repo = ref.read(incidentRepositoryProvider);
    await repo.addIncident(incident);

    // Gamificación: +3 puntos por reportar
    final authNotifier = ref.read(authProvider.notifier);
    final currentUser = ref.read(authProvider);
    if (currentUser != null && currentUser.id == incident.reportedByUserId) {
      final userRepo = ref.read(userRepositoryProvider);
      final updatedUser = currentUser.copyWith(points: currentUser.points + 3);
      await userRepo.updateUser(updatedUser);
      await authNotifier.reloadUser(); // Refrescar UI del Perfil
    }

    await loadIncidents();
  }

  Future<void> validateIncident(String incidentId, String userId) async {
    final repo = ref.read(incidentRepositoryProvider);
    await repo.validateIncident(incidentId, userId);

    // Gamificación: +1 punto por validar
    final authNotifier = ref.read(authProvider.notifier);
    final currentUser = ref.read(authProvider);
    if (currentUser != null && currentUser.id == userId) {
      final userRepo = ref.read(userRepositoryProvider);
      final updatedUser = currentUser.copyWith(points: currentUser.points + 1);
      await userRepo.updateUser(updatedUser);
      await authNotifier.reloadUser();
    }

    await loadIncidents();
  }

  Future<void> resolveIncident({
    required String incidentId,
    required String userId,
    required String companyId,
    required String companyName,
    required String comment,
  }) async {
    final repo = ref.read(incidentRepositoryProvider);
    await repo.resolveIncident(
      incidentId: incidentId,
      userId: userId,
      companyId: companyId,
      companyName: companyName,
      comment: comment,
    );

    // Gamificación: +2 puntos por resolver
    final authNotifier = ref.read(authProvider.notifier);
    final currentUser = ref.read(authProvider);
    if (currentUser != null && currentUser.id == userId) {
      final userRepo = ref.read(userRepositoryProvider);
      final updatedUser = currentUser.copyWith(points: currentUser.points + 2);
      await userRepo.updateUser(updatedUser);
      await authNotifier.reloadUser();
    }

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
