import '../../domain/entities/audit_entry.dart';
import '../../domain/repositories/audit_repository.dart';

/// Bitácora en modo demo.
///
/// La bitácora la escribe el servidor en cada operación que muta datos; sin
/// backend no hay nada que registrar ni que mostrar. Una página vacía es la
/// respuesta correcta, y la pantalla lo explica.
class DemoAuditRepositoryImpl implements AuditRepository {
  const DemoAuditRepositoryImpl();

  @override
  Future<AuditPage> query({
    int page = 1,
    int limit = 50,
    String? actorId,
    String? action,
    String? entityType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return const AuditPage(entries: [], page: 1, totalPages: 1, total: 0);
  }
}
