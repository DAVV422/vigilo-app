import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/store_product.dart';
import '../domain/entities/user.dart';
import '../presentation/providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Vehículos': return Icons.directions_bike;
      case 'Mascotas': return Icons.pets;
      case 'Hogar': return Icons.home;
      case 'Ecológico': return Icons.eco;
      case 'Accesorios': return Icons.watch;
      case 'Cupones': return Icons.local_offer;
      default: return Icons.grid_view;
    }
  }

  String _generateCode() {
    final rand = Random();
    final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final part1 = List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
    final part2 = List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'VGL-$part1-$part2';
  }

  void _confirmRedeem(BuildContext context, WidgetRef ref, StoreProduct product) {
    final user = ref.read(authProvider);
    if (user == null) return;

    if (user.points < product.pointsCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Te faltan ${product.pointsCost - user.points} pts. ¡Sigue reportando!'),
          backgroundColor: AppColors.secondary,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.shopping_cart_checkout, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(child: Text('Canjear ${product.name}', style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                product.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.card_giftcard, size: 60, color: AppColors.primary.withOpacity(0.5)),
              ),
            ),
            const SizedBox(height: 16),
            Text(product.description, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Costo:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, color: AppColors.primary, size: 18),
                      const SizedBox(width: 4),
                      Text('${product.pointsCost} pts', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Saldo después:', style: TextStyle(color: Colors.grey[600])),
                  Text('${user.points - product.pointsCost} pts', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton.icon(
            onPressed: () async {
              final code = _generateCode();
              final updatedUser = user.copyWith(points: user.points - product.pointsCost);
              await ref.read(userRepositoryProvider).updateUser(updatedUser);
              await ref.read(authProvider.notifier).reloadUser();
              if (context.mounted) {
                Navigator.pop(ctx);
                _showSuccessDialog(context, product, code);
              }
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Confirmar Canje'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, StoreProduct product, String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 56),
            SizedBox(height: 12),
            Text('¡Canje Exitoso!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Has canjeado "${product.name}" correctamente.', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Text('CÓDIGO DE CANJE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(
                    code,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 3, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Presenta este código en el punto de entrega para recoger tu producto.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Los puntos han sido descontados de tu cuenta.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Listo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Marketplace Vigilo',
        subtitle: 'Canjea tus puntos por productos',
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          if (user != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.ecoGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tus Puntos', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('${user.points} pts', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar productos, cupones...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: ['Todos', 'Vehículos', 'Mascotas', 'Hogar', 'Ecológico', 'Accesorios', 'Cupones']
                  .map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(30.0),
                            border: isSelected ? null : Border.all(color: Colors.grey.shade300, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(category),
                                size: 16,
                                color: isSelected ? Colors.white : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                category,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey.shade800,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: productsAsync.when(
              data: (allProducts) {
                final products = allProducts.where((p) {
                  final matchesSearch = p.name.toLowerCase().contains(_searchQuery) ||
                      p.description.toLowerCase().contains(_searchQuery);
                  final matchesCategory = _selectedCategory == 'Todos' || p.category == _selectedCategory;
                  return matchesSearch && matchesCategory;
                }).toList();
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No hay productos disponibles', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('Pronto tendremos novedades', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.58,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final canAfford = user != null && user.points >= product.pointsCost;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (canAfford) {
                                _confirmRedeem(context, ref, product);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Necesitas ${product.pointsCost} pts. Te faltan ${product.pointsCost - (user?.points ?? 0)} pts.'),
                                    backgroundColor: Colors.grey,
                                  ),
                                );
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // A. Bloque Superior (Área de Imagen)
                                Container(
                                  height: 110,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                  ),
                                  child: Center(
                                    child: Image.network(
                                      product.imageUrl,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.card_giftcard, color: AppColors.primary, size: 40),
                                    ),
                                  ),
                                ),
                                // B. Bloque Inferior (Área de Información)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Etiqueta de Categoría
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(_getCategoryIcon(product.category), size: 10, color: Colors.orange.shade800),
                                              const SizedBox(width: 4),
                                              Text(
                                                product.category,
                                                style: TextStyle(
                                                  color: Colors.orange.shade800,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        // Título del Producto
                                        Text(
                                          product.name,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        // Descripción Corta
                                        Text(
                                          product.description,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        // Proveedor
                                        Text(
                                          'Por: Supermercado Hipermaxi',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 10,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Spacer(),
                                        // Fila Inferior (Precio y Botón)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            // Lado Izquierdo (Precio y Stock)
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.star, color: Colors.amber, size: 14),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      '${product.pointsCost}',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                        color: canAfford ? Colors.black87 : Colors.grey,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 2),
                                                    const Text(
                                                      'pts',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  'Stock: ${product.stock}',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade400,
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Lado Derecho (Botón de Acción)
                                            SizedBox(
                                              height: 28,
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  if (canAfford) {
                                                    _confirmRedeem(context, ref, product);
                                                  } else {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Necesitas ${product.pointsCost} pts.'),
                                                        backgroundColor: Colors.grey,
                                                      ),
                                                    );
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: canAfford ? AppColors.primary : Colors.grey.shade300,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                icon: const Icon(Icons.redeem, size: 12),
                                                label: const Text(
                                                  'Canjear',
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text('Error al cargar productos', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}