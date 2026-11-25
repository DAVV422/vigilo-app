import '../../core/network/json_parsing.dart';

/// Quién hizo una operación. Nulo cuando no había sesión.
class AuditActor {
  const AuditActor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String username;

  String get fullName => '$firstName $lastName'.trim();

  factory AuditActor.fromJson(Map<String, dynamic> json) => AuditActor(
        id: json['id'] as String,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        username: json['username'] as String? ?? '',
      );
}

/// Un cambio registrado en la bitácora.
///
/// **Solo se registra lo que modifica datos.** El interceptor del servidor
/// sale temprano si el método no es `POST`, `PATCH`, `PUT` o `DELETE`: las
/// lecturas no dejan rastro. La pantalla no debe insinuar que muestra toda
/// la actividad; muestra los cambios.
class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.action,
    required this.httpMethod,
    required this.httpPath,
    required this.statusCode,
    required this.createdAt,
    this.actor,
    this.entityType,
    this.entityId,
    this.ipAddress,
    this.userAgent,
    this.newState,
    this.metadata,
  });

  final String id;

  /// `{MÉTODO}_{ENTIDAD}`, o `{MÉTODO}_FAILED_{ENTIDAD}` si falló.
  final String action;
  final String httpMethod;
  final String httpPath;
  final int statusCode;
  final DateTime createdAt;

  /// Nulo en las operaciones sin sesión, que incluye **todos** los inicios
  /// de sesión: todavía no había un actor.
  final AuditActor? actor;

  final String? entityType;
  final String? entityId;
  final String? ipAddress;
  final String? userAgent;

  /// El cuerpo de la respuesta, con las claves sensibles redactadas por el
  /// servidor. Se muestra como JSON: tipar el estado posterior de catorce
  /// entidades distintas no se sostiene.
  final Map<String, dynamic>? newState;
  final Map<String, dynamic>? metadata;

  bool get failed => action.contains('_FAILED_') || statusCode >= 400;

  String? get errorMessage => metadata?['error'] as String?;

  /// Qué pasó, en castellano. Cae al valor crudo si la combinación es
  /// desconocida: un registro nuevo tiene que verse, no romper la pantalla.
  String get label {
    final entidad = _entidades[entityType] ?? entityType ?? 'un recurso';
    if (failed) return 'Falló una operación sobre $entidad';
    return switch (httpMethod) {
      'POST' => 'Se creó algo en $entidad',
      'PATCH' || 'PUT' => 'Se modificó $entidad',
      'DELETE' => 'Se eliminó algo de $entidad',
      _ => action,
    };
  }

  static const _entidades = {
    'ADMIN_PENALTIES': 'sanciones',
    'ANALYTICS': 'analítica',
    'AUTH': 'autenticación',
    'COMPANIES': 'empresas',
    'DISPUTES': 'disputas',
    'INCIDENTS': 'incidentes',
    'MATERIALS': 'materiales',
    'MEDIA': 'archivos',
    'NOTIFICATIONS': 'notificaciones',
    'RATINGS': 'calificaciones',
    'RECYCLING_LISTINGS': 'publicaciones',
    'RECYCLING_PICKUPS': 'recojos',
    'STORE': 'la tienda',
    'USERS': 'usuarios',
  };

  /// Las entidades que el servidor puede registrar, para el filtro.
  /// Se derivan de los decoradores `@Auditable` del backend.
  static Map<String, String> get entityLabels => _entidades;

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
        id: json['id'] as String,
        action: json['action'] as String? ?? '',
        httpMethod: json['httpMethod'] as String? ?? '',
        httpPath: json['httpPath'] as String? ?? '',
        statusCode: toIntOrNull(json['statusCode']) ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        actor: json['actor'] is Map<String, dynamic>
            ? AuditActor.fromJson(json['actor'] as Map<String, dynamic>)
            : null,
        entityType: json['entityType'] as String?,
        entityId: json['entityId'] as String?,
        ipAddress: json['ipAddress'] as String?,
        userAgent: json['userAgent'] as String?,
        newState: json['newState'] as Map<String, dynamic>?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// Una página de la bitácora.
class AuditPage {
  const AuditPage({
    required this.entries,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final List<AuditEntry> entries;
  final int page;
  final int totalPages;
  final int total;

  bool get hasPrevious => page > 1;
  bool get hasNext => page < totalPages;

  factory AuditPage.fromJson(Map<String, dynamic> json) {
    final meta = (json['meta'] as Map<String, dynamic>?) ?? const {};
    return AuditPage(
      entries: ((json['data'] as List<dynamic>?) ?? const [])
          .map((e) => AuditEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: toIntOrNull(meta['page']) ?? 1,
      totalPages: toIntOrNull(meta['totalPages']) ?? 1,
      total: toIntOrNull(meta['total']) ?? 0,
    );
  }
}
