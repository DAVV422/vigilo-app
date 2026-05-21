import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/local_json_datasource.dart';
import '../../data/models/company_model.dart';
import '../../data/repositories/incident_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/company.dart';
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
    final updatedUser = users.firstWhere((u) => u.id == state!.id, orElse: () => state!);
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
final currentNavIndexProvider = NotifierProvider<NavIndexNotifier, int>(() => NavIndexNotifier());
final selectedIncidentProvider = NotifierProvider<SelectedIncidentNotifier, Incident?>(() => SelectedIncidentNotifier());

class NavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void goToMap() {
    state = 0;
  }

  void goToAlerts() {
    state = 1;
  }

  void goToProfile() {
    state = 2;
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
final incidentsProvider = NotifierProvider<IncidentsNotifier, List<Incident>>(IncidentsNotifier.new);

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
final companiesProvider = NotifierProvider<CompaniesNotifier, List<Company>>(() => CompaniesNotifier());

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
    state = companiesJson.map((c) => CompanyModel.fromJson(c as Map<String, dynamic>)).toList();
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
