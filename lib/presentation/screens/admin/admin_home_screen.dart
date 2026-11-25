import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/user.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import 'admin_disputes_screen.dart';
import 'admin_fulfill_redemption_screen.dart';
import 'admin_products_screen.dart';
import 'widgets/admin_scaffold.dart';

/// Una entrada del índice de gestión.
///
/// Se modela como dato y no como widget suelto para que habilitar una
/// sección nueva sea cambiar una línea —poner su `builder`— y no reescribir
/// la lista. Con `builder` nulo la fila se pinta apagada y no navega.
class _Section {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.allowedRoles,
    this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Set<UserRole> allowedRoles;
  final WidgetBuilder? builder;

  bool get isReady => builder != null;

  bool allows(List<UserRole> roles) => roles.any(allowedRoles.contains);
}

Widget _buildProducts(BuildContext _) => const AdminProductsScreen();
Widget _buildFulfill(BuildContext _) => const AdminFulfillRedemptionScreen();
Widget _buildDisputes(BuildContext _) => const AdminDisputesScreen();

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  static const _admin = {UserRole.admin};
  static const _staff = {UserRole.admin, UserRole.moderator};

  List<_Section> get _sections => const [
        _Section(
          title: 'Catálogo de la tienda',
          subtitle: 'Dar de alta y editar las recompensas',
          icon: Icons.storefront_outlined,
          allowedRoles: _admin,
          builder: _buildProducts,
        ),
        _Section(
          title: 'Entrega de canjes',
          subtitle: 'Buscar un código y marcarlo como entregado',
          icon: Icons.qr_code_scanner_outlined,
          allowedRoles: _staff,
          builder: _buildFulfill,
        ),
        _Section(
          title: 'Disputas',
          subtitle: 'Revisar y resolver reclamos de pesaje',
          icon: Icons.gavel_outlined,
          allowedRoles: _staff,
          builder: _buildDisputes,
        ),
        _Section(
          title: 'Materiales y precios',
          subtitle: 'Precio por kilo y puntos de cada material',
          icon: Icons.scale_outlined,
          allowedRoles: _admin,
        ),
        _Section(
          title: 'Empresas',
          subtitle: 'Alta, verificación y zonas de cobertura',
          icon: Icons.business_outlined,
          allowedRoles: _admin,
        ),
        _Section(
          title: 'Penalizaciones y configuración',
          subtitle: 'Reglas, sanciones y parámetros del sistema',
          icon: Icons.rule_outlined,
          allowedRoles: _admin,
        ),
        _Section(
          title: 'Bitácora de auditoría',
          subtitle: 'Quién hizo qué y cuándo',
          icon: Icons.history_outlined,
          allowedRoles: _admin,
        ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(currentRolesProvider);
    // Una sección que el rol no alcanza no se muestra, en vez de mostrarse
    // deshabilitada: listar lo que no se puede hacer solo genera preguntas.
    final visible = _sections.where((s) => s.allows(roles)).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Gestión')),
      body: Column(
        children: [
          const AdminBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final section in visible) _buildTile(context, section),
                const SizedBox(height: 16),
                const Text(
                  'Las secciones apagadas todavía no están construidas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, _Section section) {
    final enabled = section.isReady;
    final fg = enabled ? AppColors.onSurface : AppColors.onSurfaceVariant;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border.all(color: AppColors.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(section.icon, size: 21, color: AppColors.primary),
          ),
          title: Text(
            section.title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg),
          ),
          subtitle: Text(
            enabled ? section.subtitle : 'Próximamente',
            style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          trailing: enabled
              ? const Icon(Icons.chevron_right, size: 18, color: AppColors.onSurfaceVariant)
              : null,
          onTap: enabled
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: section.builder!),
                  )
              : null,
        ),
      ),
    );
  }
}
