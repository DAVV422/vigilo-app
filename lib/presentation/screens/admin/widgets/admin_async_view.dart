import 'package:flutter/material.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../theme/app_colors.dart';

/// Los tres estados que toda pantalla de gestión repite: cargando, error con
/// reintento, y vacío.
///
/// Vive en un solo lugar porque si no, cada pantalla los escribe distinto y
/// la sección termina pareciendo cuatro aplicaciones. También concentra el
/// manejo del 403, que acá no es un caso raro: la superficie de gestión se
/// muestra según el rol que el cliente conoce, y ese rol puede estar viejo.
class AdminAsyncView extends StatelessWidget {
  const AdminAsyncView({
    super.key,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.child,
    this.isEmpty = false,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyTitle = 'No hay nada acá todavía',
    this.emptyMessage,
  });

  final bool isLoading;

  /// Mensaje ya traducido por `describeError`, o la excepción cruda si se
  /// necesita distinguir el 403.
  final Object? error;
  final VoidCallback onRetry;
  final Widget child;

  final bool isEmpty;
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (error != null) return _buildError(context);
    if (isEmpty) return _buildEmpty();
    return child;
  }

  Widget _buildError(BuildContext context) {
    final e = error;
    final isForbidden = e is ApiException && e.statusCode == 403;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isForbidden ? Icons.lock_outline : Icons.error_outline,
              color: isForbidden ? AppColors.onSurfaceVariant : AppColors.error,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              isForbidden
                  ? 'No tenés permiso para esta sección. Es posible que tu rol '
                      'haya cambiado: cerrá sesión y volvé a entrar.'
                  : (e is ApiException ? e.message : e.toString()),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            // Sin reintento en un 403: volver a pedir lo mismo con el mismo
            // rol va a fallar igual, y ofrecerlo sería mentir.
            if (!isForbidden)
              OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    // ListView y no Column, para que el RefreshIndicator de arriba siga
    // teniendo algo desplazable cuando no hay contenido.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        const SizedBox(height: 80),
        Icon(emptyIcon, size: 44, color: AppColors.outline),
        const SizedBox(height: 12),
        Text(
          emptyTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        if (emptyMessage != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              emptyMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }
}
