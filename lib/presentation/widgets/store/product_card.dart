// lib/presentation/widgets/store/product_card.dart
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../domain/entities/store_product.dart';

IconData categoryIconFor(String category) {
  switch (category.toUpperCase()) {
    case 'ECOLOGICO':
    case 'ECOLÓGICO':
      return Icons.eco_outlined;
    case 'MASCOTAS':
      return Icons.pets;
    case 'VEHICULOS':
    case 'VEHÍCULOS':
      return Icons.directions_bike;
    case 'ACCESORIOS':
      return Icons.star_border;
    default:
      return Icons.redeem_outlined;
  }
}

/// Tarjeta de un producto real de `StoreRepository`. Reemplaza el antiguo
/// `ProductItem` (con colores por ítem inventados a mano, sin relación al
/// backend) por una presentación neutra y consistente: un solo acento de
/// color (el mismo para toda la tienda) en vez de una paleta distinta por
/// tarjeta, que es más propia de una vitrina de juegos que de un canje serio.
class ProductCard extends StatelessWidget {
  final StoreProduct product;
  final int userPoints;
  final VoidCallback? onRedeem;

  const ProductCard({
    super.key,
    required this.product,
    required this.userPoints,
    this.onRedeem,
  });

  bool get canAfford => userPoints >= product.pointsCost && product.stock > 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 96,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.vertical(top: Radius.circular(7.0)),
            ),
            child: Center(
              child: product.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(7.0)),
                      child: Image.network(
                        product.imageUrl,
                        height: 96,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          categoryIconFor(product.category),
                          size: 36,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Icon(categoryIconFor(product.category), size: 36, color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    '${product.pointsCost} pts',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.stock > 0 ? 'Stock: ${product.stock}' : 'Agotado',
                        style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                      ),
                      SizedBox(
                        height: 30,
                        child: ElevatedButton(
                          onPressed: canAfford ? onRedeem : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          child: const Text('Canjear'),
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
    );
  }
}
