// lib/presentation/widgets/store/product_card.dart
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';


class ProductItem {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final int pointsCost;
  final int stock;
  final IconData categoryIcon;
  final String? imageUrl;
  final Color bgColor;
  final Color categoryColor;
  final Color categoryTextColor;

  const ProductItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.pointsCost,
    required this.stock,
    required this.categoryIcon,
    this.imageUrl,
    required this.bgColor,
    required this.categoryColor,
    required this.categoryTextColor,
  });
}

class ProductCard extends StatelessWidget {
  final ProductItem product;
  final int userPoints;
  final VoidCallback? onRedeem;

  const ProductCard({
    Key? key,
    required this.product,
    required this.userPoints,
    this.onRedeem,
  }) : super(key: key);

  bool get canAfford => userPoints >= product.pointsCost && product.stock > 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cuadro de Imagen superior
          Container(
            height: 100, // Reduced from 120 to avoid overflow on smaller screens
            width: double.infinity,
            decoration: BoxDecoration(
              color: product.bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11.0),
              ),
            ),
            child: Center(
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(
                      product.imageUrl!,
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        product.categoryIcon,
                        size: 48,
                        color: product.categoryTextColor,
                      ),
                    )
                  : Icon(
                      product.categoryIcon,
                      size: 48,
                      color: product.categoryTextColor,
                    ),
            ),
          ),

          // Información del Producto
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge de Categoría
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: product.categoryColor,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(product.categoryIcon, size: 10, color: product.categoryTextColor),
                        const SizedBox(width: 4),
                        Text(
                          product.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: product.categoryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Título
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onBackground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Subtítulo
                  Text(
                    product.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),

                  // Costo en puntos
                  Row(
                    children: [
                      const Icon(
                        Icons.star_outline_rounded,
                        size: 16,
                        color: Color(0xFF8D5B35), // Color similar a bronce/naranja del mockup
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product.pointsCost}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Fila inferior: Stock y Botón
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Stock:\n${product.stock}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: canAfford ? (onRedeem ?? () {}) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canAfford ? const Color(0xFF004D25) : const Color(0xFFD6DBE1),
                            foregroundColor: canAfford ? Colors.white : Colors.grey.shade600,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            disabledBackgroundColor: const Color(0xFFD6DBE1),
                            disabledForegroundColor: Colors.grey.shade500,
                          ),
                          icon: Icon(
                            canAfford ? Icons.shopping_bag_outlined : Icons.lock_outline,
                            size: 14,
                            color: canAfford ? Colors.white : Colors.grey.shade500,
                          ),
                          label: const Text(
                            'Canjear',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
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
    );
  }
}
