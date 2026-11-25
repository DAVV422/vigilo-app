import '../../core/network/json_parsing.dart';

/// Una persona encontrada en la búsqueda de administración.
///
/// Trae lo necesario para elegir a la correcta y para decidir qué hacer con
/// ella. **No trae correo ni teléfono**, a propósito: quien sanciona o
/// ajusta un límite no necesita el dato de contacto para hacerlo, y un
/// listado de administración es justo donde un volcado de datos personales
/// se vuelve un problema.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.status,
    required this.pointsBalance,
    required this.trustScore,
    required this.ratingsCount,
    this.roles = const [],
  });

  final String id;
  final String firstName;
  final String lastName;
  final String username;

  /// `ACTIVE` · `SUSPENDED` · `BANNED`.
  final String status;
  final int pointsBalance;
  final double trustScore;
  final int ratingsCount;
  final List<String> roles;

  String get fullName => '$firstName $lastName'.trim();

  bool get isRecycler => roles.contains('RECYCLER_INDIVIDUAL');

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] as String,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        username: json['username'] as String? ?? '',
        status: json['status'] as String? ?? 'ACTIVE',
        pointsBalance: toIntOrNull(json['pointsBalance']) ?? 0,
        // Columna NUMERIC.
        trustScore: toDoubleOrNull(json['trustScore']) ?? 0,
        ratingsCount: toIntOrNull(json['ratingsCount']) ?? 0,
        roles: ((json['roles'] as List<dynamic>?) ?? const [])
            .map((r) => r.toString())
            .toList(),
      );
}
