import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/company.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import 'admin_coverage_zones_screen.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/confirm_action_dialog.dart';

const _log = AppLogger('AdminEmpresas');

/// Detalle de una empresa: sus datos, su verificación y su territorio.
class AdminCompanyDetailScreen extends ConsumerStatefulWidget {
  const AdminCompanyDetailScreen({super.key, required this.companyId});

  final String companyId;

  @override
  ConsumerState<AdminCompanyDetailScreen> createState() =>
      _AdminCompanyDetailScreenState();
}

class _AdminCompanyDetailScreenState
    extends ConsumerState<AdminCompanyDetailScreen> {
  Company? _company;
  bool _isLoading = true;
  Object? _error;
  bool _changed = false;
  bool _verifying = false;

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
      final c = await ref.read(companiesRepositoryProvider).getById(widget.companyId);
      if (!mounted) return;
      setState(() {
        _company = c;
        _isLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      describeError(e, st, log: _log, operation: 'cargar la empresa');
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Future<void> _verify(Company c, {required bool approved}) async {
    final ok = await confirmAction(
      context,
      title: approved ? 'Verificar ${c.name}' : 'Rechazar ${c.name}',
      // Qué habilita, no "¿estás seguro?": verificar una empresa la pone a
      // recibir incidentes reales y habilita a su personal a operar.
      consequence: approved
          ? 'Queda habilitada para recibir incidentes asignados '
              'automáticamente dentro de sus zonas, y su personal puede '
              'operar en la plataforma.'
          : 'Queda marcada como rechazada y no recibe incidentes. Se puede '
              'verificar más adelante.',
      confirmLabel: approved ? 'Verificar' : 'Rechazar',
      isDestructive: !approved,
    );
    if (!ok || !mounted) return;

    setState(() => _verifying = true);
    try {
      await ref
          .read(companiesRepositoryProvider)
          .verify(c.id, approved: approved);
      if (!mounted) return;
      _changed = true;
      await _load();
      if (!mounted) return;
      setState(() => _verifying = false);
      _snack(approved ? 'Empresa verificada.' : 'Empresa rechazada.');
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _verifying = false);
      _snack(
        describeError(e, st,
            log: _log,
            operation: 'cambiar la verificación',
            whereToCheck: 'el detalle de la empresa'),
        isError: true,
      );
    }
  }

  Future<void> _openZones(Company c) async {
    final cambio = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminCoverageZonesScreen(
          companyId: c.id,
          companyName: c.name,
        ),
      ),
    );
    if (cambio == true) {
      _changed = true;
      await _load();
    }
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _company;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: AdminScaffold(
        title: c?.name ?? 'Empresa',
        onRefresh: _load,
        body: AdminAsyncView(
          isLoading: _isLoading,
          error: _error,
          onRetry: _load,
          child: c == null
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  children: [
                    _buildStatus(c),
                    const SizedBox(height: 16),
                    _buildData(c),
                    const SizedBox(height: 16),
                    _buildZones(c),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildStatus(Company c) {
    final (label, color) = switch (c.verificationStatus) {
      'VERIFIED' => ('Verificada', AppColors.primary),
      'PENDING' => ('Pendiente de verificación', AppColors.warning),
      'REJECTED' => ('Rechazada', AppColors.error),
      _ => (c.verificationLabel, AppColors.onSurfaceVariant),
    };

    return _card(
      title: 'ESTADO',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                c.isVerified ? Icons.verified_outlined : Icons.pending_outlined,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
          if (!c.isVerified) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _verifying ? null : () => _verify(c, approved: true),
                icon: const Icon(Icons.verified_outlined, size: 18),
                label: const Text('Verificar'),
              ),
            ),
          ],
          // Sin botón para rechazar algo que ya está rechazado, ni para
          // verificar lo ya verificado: no harían nada.
          if (c.verificationStatus != 'REJECTED') ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _verifying ? null : () => _verify(c, approved: false),
                child: const Text('Rechazar'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildData(Company c) {
    return _card(
      title: 'DATOS',
      child: Column(
        children: [
          _row('Razón social', c.legalName ?? '—'),
          _row('Tipo', c.type?.label ?? '—'),
          _row('Identificador tributario', c.taxId ?? '—'),
          _row('Teléfono', c.contactPhone ?? '—'),
          _row('Correo', c.contactEmail ?? '—'),
          const SizedBox(height: 8),
          const Text(
            // Deuda conocida: no hay PATCH /companies/:id.
            'Los datos de una empresa todavía no se pueden corregir desde '
            'la app.',
            style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildZones(Company c) {
    final zonas = c.coverageZones;

    return _card(
      title: 'ZONAS DE COBERTURA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (zonas.isEmpty)
            const Text(
              'Sin zonas. Una empresa sin zona no recibe ningún incidente '
              'asignado automáticamente, por más que esté verificada.',
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            )
          else
            for (final z in zonas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.layers_outlined,
                        size: 16, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(z.name, style: const TextStyle(fontSize: 13)),
                    ),
                    Text(
                      '${z.areaKm2.toStringAsFixed(1)} km²',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openZones(c),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(zonas.isEmpty ? 'Crear la primera zona' : 'Ver en el mapa'),
            ),
          ),
        ],
      ),
    );
  }
}
