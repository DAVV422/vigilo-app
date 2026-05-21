import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local_json_datasource.dart';
import '../models/user_model.dart';
import '../models/incident_model.dart';
import '../models/company_model.dart';

class UserRepositoryImpl implements UserRepository {
  final LocalJsonDatasource datasource;

  UserRepositoryImpl(this.datasource);

  @override
  Future<List<User>> getUsers() async {
    final data = await datasource.readData();
    final usersJson = data['users'] as List<dynamic>;
    return usersJson.map<User>((u) => UserModel.fromJson(u)).toList();
  }

  @override
  Future<User?> login(String email, String password) async {
    final users = await getUsers();
    try {
      return users.firstWhere((u) => u.email == email && u.password == password);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateUser(User user) async {
    final data = await datasource.readData();
    final usersJson = data['users'] as List<dynamic>;
    final incidentsJson = data['incidents'] as List<dynamic>;
    final companiesJson = data['companies'] as List<dynamic>;

    final users = usersJson.map((u) => UserModel.fromJson(u)).toList();
    final incidents = incidentsJson.map((i) => IncidentModel.fromJson(i)).toList();
    final companies = companiesJson.map((c) => CompanyModel.fromJson(c as Map<String, dynamic>)).toList();

    final index = users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      users[index] = UserModel.fromEntity(user);
      await datasource.writeData(users, incidents, companies);
    }
  }
}
