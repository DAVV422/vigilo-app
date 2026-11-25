import '../../domain/entities/admin_user.dart';
import '../../domain/repositories/admin_users_repository.dart';
import '../datasources/remote/remote_admin_users_datasource.dart';

class RemoteAdminUsersRepositoryImpl implements AdminUsersRepository {
  RemoteAdminUsersRepositoryImpl(this._datasource);

  final RemoteAdminUsersDatasource _datasource;

  @override
  Future<List<AdminUser>> search(String query) async {
    final raw = await _datasource.search(query);
    return raw.map((u) => AdminUser.fromJson(u as Map<String, dynamic>)).toList();
  }
}
