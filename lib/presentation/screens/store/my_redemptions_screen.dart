import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/redemption.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';

const _log = AppLogger('Canjes');

/// Los canjes del usuario, con su código.
///
/// Hasta ahora el código se veía una sola vez, en el diálogo de confirmación
/// del canje: si el usuario lo cerraba, lo perdía. `GET /store/my-redemptions`
/// existía y hasta estaba implementado en el datasource y el repositorio —
/// solo faltaba la pantalla que lo llamara.
class MyRedemptionsScreen extends ConsumerStatefulWidget {
  const MyRedemptionsScreen({super.key});

  @override
  ConsumerState<MyRedemptionsScreen> createState() => MyRedemptionsScreenState();
}

class MyRedemptionsScreenState extends ConsumerState<MyRedemptionsScreen> {
  List<Redemption> _redemptions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    load();
  }

  /// Pública para que la Tienda pueda refrescar esta pestaña después de un
  /// canje, sin que el usuario tenga que tirar para recargar.
  Future<void> load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await ref.read(storeRepositoryProvider).getMyRedemptions();
      if (!mounted) return;
      setState(() {
        // El servidor ya los devuelve del más nuevo al más viejo, pero
        // ordenar acá cuesta una línea y no depende de eso.
        _redemptions = [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _error = describeError(e, st, log: _log, operation: 'cargar tus canjes');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) return _buildError(_error!);

    return RefreshIndicator(
      onRefresh: load,
      child: _redemptions.isEmpty
          ? _buildEmpty()
          : ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              children: _redemptions.map(_buildCard).toList(),
            ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: load, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    // ListView y no Column: el RefreshIndicator necesita algo desplazable
    // para que el gesto funcione también con la lista vacía.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: const [
        SizedBox(height: 80),
        Icon(Icons.card_giftcard_outlined, size: 44, color: AppColors.outline),
        SizedBox(height: 12),
        Text(
          'Todavía no canjeaste nada',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 6),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Mirá el catálogo y usá tus puntos.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  /// El estado llega como texto y no como enum a propósito: uno nuevo del
  /// servidor tiene que mostrarse tal cual, no romper la pantalla.
  (String, Color, Color) _statusChip(String status) {
    switch (status) {
      case 'PENDING':
        return ('Pendiente de retiro', AppColors.warning, AppColors.onSurface);
      case 'FULFILLED':
        return ('Entregado', AppColors.primary, AppColors.onPrimary);
      case 'CANCELLED':
        return ('Cancelado', AppColors.outline, AppColors.onSurface);
      default:
        return (status, AppColors.surfaceContainerHigh, AppColors.onSurface);
    }
  }

  Widget _buildCard(Redemption r) {
    final (label, bg, fg) = _statusChip(r.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (r.productImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    r.productImageUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(width: 44, height: 44),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // El producto puede haberse desactivado o borrado del
                      // catálogo; el canje sigue siendo válido igual.
                      r.productName ?? 'Producto no disponible',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r.pointsSpent} puntos · ${_formatDate(r.createdAt)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCode(r.code),
        ],
      ),
    );
  }

  Widget _buildCode(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copiar código',
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Código copiado')),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
