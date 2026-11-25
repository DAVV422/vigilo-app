import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

/// Marco común de las pantallas de gestión.
///
/// Además del título y el refresco, pinta una franja que avisa que se está
/// operando como administrador. En un teléfono no hay URL ni barra lateral
/// que lo recuerde, y confundir "ver el catálogo" con "editar el catálogo"
/// es fácil y caro: desde acá se cambian precios, se entregan canjes y se
/// resuelven disputas que mueven el saldo de otra persona.
class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onRefresh,
    this.floatingActionButton,
    this.actions,
  });

  final String title;
  final Widget body;
  final Future<void> Function()? onRefresh;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final content = onRefresh == null
        ? body
        : RefreshIndicator(onRefresh: onRefresh!, child: body);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(title), actions: actions),
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          const AdminBanner(),
          Expanded(child: content),
        ],
      ),
    );
  }
}

/// La franja de "modo gestión". Separada para que el índice pueda usarla sin
/// envolverse en un [AdminScaffold].
class AdminBanner extends StatelessWidget {
  const AdminBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.tertiaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.admin_panel_settings_outlined,
              size: 15, color: AppColors.onTertiaryContainer),
          const SizedBox(width: 8),
          Text(
            'Estás operando como administrador',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
