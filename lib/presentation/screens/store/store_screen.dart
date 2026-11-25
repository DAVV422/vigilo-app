// lib/presentation/screens/store/store_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../domain/entities/store_product.dart';
import '../../providers/providers.dart';
import 'my_redemptions_screen.dart';
import '../../widgets/store/product_card.dart';
import '../../../widgets/main_app_bar.dart';
import '../../../../core/errors/describe_error.dart';
import '../../../../core/logging/app_logger.dart';

/// Tienda de canje contra `StoreRepository` (backend real). Reemplaza la
/// versión anterior, que tenía 8 productos hardcodeados y un saldo de
/// puntos local (`_userPoints = 120`) completamente desconectado de
/// `authProvider` — un canje ahí no descontaba nada real ni validaba stock.
class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  static const _log = AppLogger('Tienda');
  String _selectedCategory = 'Todos';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<StoreProduct> _products = [];
  bool _isLoading = true;
  String? _loadError;
  bool _isRedeeming = false;

  /// Para poder refrescar la pestaña de canjes tras canjear, sin obligar al
  /// usuario a tirar de la lista para ver el código que acaba de generar.
  final _redemptionsKey = GlobalKey<MyRedemptionsScreenState>();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final products = await ref.read(storeRepositoryProvider).getProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _loadError = describeError(e, st, log: _log, operation: 'cargar la tienda');
        _isLoading = false;
      });
    }
  }

  List<String> get _categories {
    final set = <String>{'Todos', ...(_products.map((p) => p.category))};
    return set.toList();
  }

  List<StoreProduct> get _filteredProducts {
    return _products.where((product) {
      final matchesCategory = _selectedCategory == 'Todos' || product.category == _selectedCategory;
      final matchesQuery = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Future<void> _handleRedeem(StoreProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar canje'),
        content: Text('¿Deseas canjear "${product.name}" por ${product.pointsCost} puntos?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmed != true || _isRedeeming) return;

    setState(() => _isRedeeming = true);
    try {
      final result = await ref.read(storeRepositoryProvider).redeem(product.id);
      await ref.read(authProvider.notifier).reloadUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Canje confirmado. Código: ${result.redemption.code}'),
          backgroundColor: AppColors.primary,
        ),
      );
      await _loadProducts();
      // El canje recién hecho tiene que estar en la otra pestaña cuando el
      // usuario cambie a ella, con su código ya visible.
      await _redemptionsKey.currentState?.load();
    } catch (e, st) {
      if (!mounted) return;
      final message = describeError(e, st, log: _log, operation: 'completar el canje', whereToCheck: 'Mis Canjes');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isRedeeming = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userPoints = ref.watch(authProvider)?.points ?? 0;

    // El catálogo y el resultado de canjear viven en la misma pantalla a
    // propósito: esconder "Mis canjes" tras un ícono repetiría el problema
    // que ya tenía CollectionsScreen, y gastar una pestaña de la barra
    // inferior no es opción cuando con el rol de recolector ya son cinco.
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const MainAppBar(title: 'Tienda'),
        body: Column(
          children: [
            const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.onSurfaceVariant,
              indicatorColor: AppColors.primary,
              tabs: [Tab(text: 'Catálogo'), Tab(text: 'Mis canjes')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildCatalog(userPoints),
                  MyRedemptionsScreen(key: _redemptionsKey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// El catálogo tal cual estaba: no se reescribió nada de la carga, los
  /// filtros, la búsqueda ni el canje, solo se movió dentro de la pestaña.
  Widget _buildCatalog(int userPoints) {
    return RefreshIndicator(
        onRefresh: _loadProducts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _buildBalanceCard(userPoints)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: const InputDecoration(
                    hintText: 'Buscar productos...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
            if (_products.isNotEmpty)
              SliverToBoxAdapter(child: _buildCategoryChips()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ..._buildContentSlivers(),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
    );
  }

  Widget _buildBalanceCard(int userPoints) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu saldo',
                  style: TextStyle(fontSize: 11, color: AppColors.primaryFixed, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$userPoints',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Text('pts', style: TextStyle(fontSize: 13, color: AppColors.primaryFixed)),
                  ],
                ),
              ],
            ),
            const Icon(Icons.monetization_on_outlined, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = category),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildContentSlivers() {
    if (_isLoading) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      ];
    }
    if (_loadError != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, color: AppColors.outline, size: 40),
                  const SizedBox(height: 12),
                  Text(_loadError!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: _loadProducts, child: const Text('Reintentar')),
                ],
              ),
            ),
          ),
        ),
      ];
    }
    final products = _filteredProducts;
    if (products.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text('No se encontraron recompensas.', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: 0.62,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                userPoints: ref.watch(authProvider)?.points ?? 0,
                onRedeem: _isRedeeming ? null : () => _handleRedeem(product),
              );
            },
            childCount: products.length,
          ),
        ),
      ),
    ];
  }
}
