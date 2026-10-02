// admin/companySupervisor/companyManager/moderator no tienen UI propia todavía
// pero se agregan para que mapear los roles reales del backend nunca falle.
enum UserRole { normal, security, cleaning, recycling, admin, companySupervisor, companyManager, moderator }
enum CompanyRole { employee, manager, director }

class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final String avatarUrl;
  final String username;
  final String lastName;
  final String phone;
  final int points;
  final List<UserRole> roles;
  final String? companyId;
  final CompanyRole? companyRole;
  // Campos que solo provee el backend real (ver RemoteUserMapper). Quedan
  // con defaults inofensivos para los usuarios que siguen viniendo del mock
  // local, que nunca los tuvo.
  final double trustScore;
  final int ratingsCount;

  User({
    required this.id,
    required this.name,
    required this.email,
    // El backend real nunca devuelve la contraseña — el mock local sí la
    // guardaba en texto plano para comparar en `login()`. Queda opcional
    // para que un User mapeado desde la API no necesite inventar una.
    this.password = '',
    this.avatarUrl = '',
    this.username = '',
    this.lastName = '',
    this.phone = '',
    this.points = 0,
    this.roles = const [UserRole.normal],
    this.companyId,
    this.companyRole,
    this.trustScore = 5.0,
    this.ratingsCount = 0,
  });

  bool get isEmployee => companyId != null && companyId!.isNotEmpty;

  /// Verifica si este usuario puede resolver un tipo de incidente dado
  bool canResolveIncidentType(String incidentType) {
    if (!isEmployee) return false;
    switch (incidentType) {
      case 'insecurity':
        return roles.contains(UserRole.security);
      case 'trash':
      case 'weeds':
        return roles.contains(UserRole.cleaning);
      case 'recycling':
        return roles.contains(UserRole.recycling);
      default:
        return false;
    }
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? avatarUrl,
    String? username,
    String? lastName,
    String? phone,
    int? points,
    List<UserRole>? roles,
    String? companyId,
    CompanyRole? companyRole,
    double? trustScore,
    int? ratingsCount,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      username: username ?? this.username,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      points: points ?? this.points,
      roles: roles ?? this.roles,
      companyId: companyId ?? this.companyId,
      companyRole: companyRole ?? this.companyRole,
      trustScore: trustScore ?? this.trustScore,
      ratingsCount: ratingsCount ?? this.ratingsCount,
    );
  }
}
