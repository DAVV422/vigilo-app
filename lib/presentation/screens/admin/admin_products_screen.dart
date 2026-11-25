import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/store_product.dart';
import '../../../domain/repositories/store_repository.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import 'admin_product_form_screen.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/admin_scaffold.dart';

const _log = AppLogger('AdminTienda');

/// Catálogo de la tienda, del lado de quien lo carga.
///
/// Es la pantalla que cierra el agujero que originó todo el plan: hasta
/// ahora el catálogo solo se podía poblar por script, y por eso la Tienda
/// del ciudadano estuvo vacía hasta que la sembramos.
class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  List<StoreProduct> _products = [];
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
      final list = await ref.read(storeRepositoryProvider).getAllProducts();
      if (!mounted) return;
      setState(() {
        // Los inactivos al final: lo que se administra a diario es lo que
        // está publicado.
        _products = [...list]..sort((a, b) {
            if (a.active != b.active) return a.active ? -1 : 1;
            return a.pointsCost.compareTo(b.pointsCost);
          });
        _isLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      // Se guarda la excepción cruda, no el mensaje: AdminAsyncView
      // necesita el statusCode para distinguir un 403.
      describeError(e, st, log: _log, operation: 'cargar el catálogo');
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Future<void> _openForm([StoreProduct? product]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminProductFormScreen(product: product)),
    );
    if (changed == true) await _load();
  }

  Future<void> _toggleActive(StoreProduct product) async {
    try {
      await ref
          .read(storeRepositoryProvider)
          .updateProduct(product.id, ProductInput(active: !product.active));
      await _load();
    } catch (e, st) {
      if (!mounted) return;
      final message = describeError(
        e,
        st,
        log: _log,
        operation: product.active ? 'desactivar el producto' : 'activar el producto',
        whereToCheck: 'el catálogo',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Catálogo de la tienda',
      onRefresh: _load,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: AdminAsyncView(
        isLoading: _isLoading,
        error: _error,
        onRetry: _load,
        isEmpty: _products.isEmpty,
        emptyIcon: Icons.storefront_outlined,
        emptyTitle: 'El catálogo está vacío',
        emptyMessage:
            'Sin productos, los puntos que la gente acumula no tienen contra '
            'qué canjearse. Creá el primero con el botón de abajo.',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: _products.map(_buildCard).toList(),
        ),
      ),
    );
  }

  Widget _buildCard(StoreProduct p) {
    final outOfStock = p.stock <= 0;

    return Opacity(
      opacity: p.active ? 1 : 0.6,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border.all(
            color: outOfStock && p.active ? AppColors.warning : AppColors.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () => _openForm(p),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  p.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                  // Las URLs del demo apuntan a un CDN externo y pueden
                  // caerse; un catálogo roto no debe romper la pantalla.
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.image_not_supported_outlined,
                    size: 28,
                    color: AppColors.outline,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.pointsCost} pts · ${p.category}',
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          outOfStock ? 'Sin stock' : 'Stock: ${p.stock}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: outOfStock ? FontWeight.w700 : FontWeight.w400,
                            color: outOfStock ? AppColors.warning : AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (!p.active) ...[
                          const SizedBox(width: 8),
                          const Text(
                            'Desactivado',
                            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Un interruptor y no un menú: activar y desactivar es la
              // operación más frecuente y la única reversible de la pantalla.
              Switch(
                value: p.active,
                onChanged: (_) => _toggleActive(p),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
