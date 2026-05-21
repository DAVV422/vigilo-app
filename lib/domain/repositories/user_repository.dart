import '../entities/user.dart';

abstract class UserRepository {
  Future<List<User>> getUsers();
  Future<User?> login(String email, String password);
  Future<void> updateUser(User user);
}
