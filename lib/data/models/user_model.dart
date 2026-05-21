import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.password,
    super.avatarUrl = '',
    super.username = '',
    super.lastName = '',
    super.phone = '',
    super.points = 0,
    super.roles = const [UserRole.normal],
    super.companyId,
    super.companyRole,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parsear roles
    List<UserRole> parsedRoles = [UserRole.normal];
    if (json['roles'] != null) {
      parsedRoles = (json['roles'] as List<dynamic>).map((r) {
        return UserRole.values.firstWhere(
          (e) => e.toString() == 'UserRole.$r',
          orElse: () => UserRole.normal,
        );
      }).toList();
    }

    // Parsear companyRole
    CompanyRole? parsedCompanyRole;
    if (json['companyRole'] != null) {
      parsedCompanyRole = CompanyRole.values.firstWhere(
        (e) => e.toString() == 'CompanyRole.${json['companyRole']}',
        orElse: () => CompanyRole.employee,
      );
    }

    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      username: json['username'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'] ?? '',
      points: json['points'] ?? 0,
      roles: parsedRoles,
      companyId: json['companyId'],
      companyRole: parsedCompanyRole,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'avatarUrl': avatarUrl,
      'username': username,
      'lastName': lastName,
      'phone': phone,
      'points': points,
      'roles': roles.map((r) => r.toString().split('.').last).toList(),
      'companyId': companyId,
      'companyRole': companyRole?.toString().split('.').last,
    };
  }

  factory UserModel.fromEntity(User entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      password: entity.password,
      avatarUrl: entity.avatarUrl,
      username: entity.username,
      lastName: entity.lastName,
      phone: entity.phone,
      points: entity.points,
      roles: entity.roles,
      companyId: entity.companyId,
      companyRole: entity.companyRole,
    );
  }
}
