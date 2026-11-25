import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/company.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import 'admin_company_detail_screen.dart';
import 'admin_company_form_screen.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/admin_scaffold.dart';

const _log = AppLogger('AdminEmpresas');

/// Las empresas de la plataforma.
///
/// Seis endpoints existían sin ninguna vista, y el efecto en cadena es lo
/// que importa: cuatro roles —guardia, recolector de basura, supervisor y
/// gerente— exigen una `company_id`, y sin forma de crear una empresa esos
/// roles no existen en la práctica. Con ellos tampoco existe la asignación
/// automática de incidentes por territorio.
class AdminCompaniesScreen extends ConsumerStatefulWidget {
  const AdminCompaniesScreen({super.key});

  @override
  ConsumerState<AdminCompaniesScreen> createState() =>
      _AdminCompaniesScreenState();
}

class _AdminCompaniesScreenState extends ConsumerState<AdminCompaniesScreen> {
  List<Company> _companies = [];
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await ref.read(companiesRepositoryProvider).getAll();
      if (!mounted) return;
      setState(() {
        _companies = list;
        _isLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      describeError(e, st, log: _log, operation: 'cargar las empresas');
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Future<void> _open(Company c) async {
    final cambio = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminCompanyDetailScreen(companyId: c.id)),
    );
    if (cambio == true) await _load();
  }

  Future<void> _create() async {
    final creada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminCompanyFormScreen()),
    );
    if (creada == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    // Las pendientes primero: son las únicas que piden una acción.
    final pendientes = _companies.where((c) => c.isPending).toList();
    final resto = _companies.where((c) => !c.isPending).toList();

    return AdminScaffold(
      title: 'Empresas',
      onRefresh: _load,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: AdminAsyncView(
        isLoading: _isLoading,
        error: _error,
        onRetry: _load,
        isEmpty: _companies.isEmpty,
        emptyIcon: Icons.business_outlined,
        emptyTitle: 'Todavía no hay empresas',
        emptyMessage:
            'Las empresas atienden los incidentes de su zona y emplean a '
            'guardias y recolectores. Creá la primera con el botón de abajo.',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          physics:
              const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: [
            if (pendientes.isNotEmpty) ...[
              _header('PENDIENTES DE VERIFICACIÓN'),
              for (final c in pendientes) _buildCard(c),
              const SizedBox(height: 18),
            ],
            if (resto.isNotEmpty) ...[
              if (pendientes.isNotEmpty) _header('EL RESTO'),
              for (final c in resto) _buildCard(c),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _buildCard(Company c) {
    final (label, color) = switch (c.verificationStatus) {
      'VERIFIED' => ('Verificada', AppColors.primary),
      'PENDING' => ('Pendiente', AppColors.warning),
      'REJECTED' => ('Rechazada', AppColors.error),
      _ => (c.verificationLabel, AppColors.onSurfaceVariant),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(
          color: c.isPending ? AppColors.warning : AppColors.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _open(c),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      c.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                c.type?.label ?? 'Sin tipo',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                c.coverageZones.isEmpty
                    ? 'Sin zona de cobertura'
                    : '${c.coverageZones.length} '
                        '${c.coverageZones.length == 1 ? "zona" : "zonas"} de cobertura',
                style: TextStyle(
                  fontSize: 11,
                  color: c.coverageZones.isEmpty
                      ? AppColors.error
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
