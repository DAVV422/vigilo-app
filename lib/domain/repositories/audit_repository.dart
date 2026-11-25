import '../entities/audit_entry.dart';

/// La bitácora de auditoría (`ADMIN`).
///
/// Registra quién hizo qué, cuándo, desde qué IP y con qué resultado. No
/// aporta capacidad nueva al producto; aporta la posibilidad de explicarlo.
abstract class AuditRepository {
  /// [action] y [entityType] son **coincidencia exacta** en el servidor, no
  /// búsquedas: un texto libre no encontraría nada salvo que se escriba el
  /// valor justo. Por eso la pantalla los ofrece como listas cerradas.
  Future<AuditPage> query({
    int page = 1,
    int limit = 50,
    String? actorId,
    String? action,
    String? entityType,
    DateTime? startDate,
    DateTime? endDate,
  });
}
