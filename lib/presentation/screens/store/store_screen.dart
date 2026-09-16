// lib/presentation/screens/store/store_screen.dart
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

import '../../widgets/store/product_card.dart';
import '../../../widgets/main_app_bar.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({Key? key}) : super(key: key);

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  int _userPoints = 120;
  String _selectedCategory = 'Todos';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Todos',
    'Vehículos',
    'Mascotas',
    'Ecológico',
    'Accesorios',
  ];

  final List<ProductItem> _allProducts = const [
    ProductItem(
      id: '1',
      title: 'Bicicleta Eléctrica',
      subtitle: 'Movilidad sostenible para la ciudad...',
      category: 'Vehículos',
      pointsCost: 5000,
      stock: 20,
      categoryIcon: Icons.directions_bike,
      imageUrl: '',
      bgColor: Color(0xFFF3F5FA),
      categoryColor: Color(0xFFFFF0E3),
      categoryTextColor: Color(0xFFA14C19),
    ),
    ProductItem(
      id: '2',
      title: 'Alimento Premium Mascotas',
      subtitle: 'Nutrición balanceada...',
      category: 'Mascotas',
      pointsCost: 50,
      stock: 15,
      categoryIcon: Icons.pets,
      imageUrl: '',
      bgColor: Color(0xFFE9F8F4),
      categoryColor: Color(0xFFE0F9E6),
      categoryTextColor: Color(0xFF147522),
    ),
    ProductItem(
      id: '3',
      title: 'Batería Solar',
      subtitle: 'Cargador portátil 10000mAh solar.',
      category: 'Ecológico',
      pointsCost: 800,
      stock: 5,
      categoryIcon: Icons.eco_outlined,
      imageUrl: '',
      bgColor: Color(0xFFF1F3FA),
      categoryColor: Color(0xFFFFF0E6),
      categoryTextColor: Color(0xFF885721),
    ),
    ProductItem(
      id: '4',
      title: 'Kit de Llaveros Vigilo',
      subtitle: 'Edición comunitaria, s...',
      category: 'Accesorios',
      pointsCost: 120,
      stock: 42,
      categoryIcon: Icons.star_border,
      imageUrl: '',
      bgColor: Color(0xFFF4EFF4),
      categoryColor: Color(0xFFFFECEE),
      categoryTextColor: Color(0xFFA71F22),
    ),
    ProductItem(
      id: '5',
      title: 'Termo Reutilizable 1L',
      subtitle: 'Acero inoxidable, mantiene temperatura.',
      category: 'Ecológico',
      pointsCost: 300,
      stock: 10,
      categoryIcon: Icons.eco_outlined,
      imageUrl: '',
      bgColor: Color(0xFFF1F3FA),
      categoryColor: Color(0xFFFFF0E6),
      categoryTextColor: Color(0xFF885721),
    ),
    ProductItem(
      id: '6',
      title: 'Correa Reflectiva para Perros',
      subtitle: 'Seguridad nocturna garantizada.',
      category: 'Mascotas',
      pointsCost: 150,
      stock: 25,
      categoryIcon: Icons.pets,
      imageUrl: '',
      bgColor: Color(0xFFE9F8F4),
      categoryColor: Color(0xFFE0F9E6),
      categoryTextColor: Color(0xFF147522),
    ),
    ProductItem(
      id: '7',
      title: 'Casco de Bicicleta Urbano',
      subtitle: 'Protección ligera y aerodinámica.',
      category: 'Vehículos',
      pointsCost: 1200,
      stock: 8,
      categoryIcon: Icons.directions_bike,
      imageUrl: '',
      bgColor: Color(0xFFF3F5FA),
      categoryColor: Color(0xFFFFF0E3),
      categoryTextColor: Color(0xFFA14C19),
    ),
    ProductItem(
      id: '8',
      title: 'Paraguas Compacto Vigilo',
      subtitle: 'Resistente a vientos fuertes.',
      category: 'Accesorios',
      pointsCost: 450,
      stock: 12,
      categoryIcon: Icons.star_border,
      imageUrl: '',
      bgColor: Color(0xFFF4EFF4),
      categoryColor: Color(0xFFFFECEE),
      categoryTextColor: Color(0xFFA71F22),
    ),
  ];

  List<ProductItem> get _filteredProducts {
    return _allProducts.where((product) {
      final matchesCategory = _selectedCategory == 'Todos' ||
          product.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesQuery = _searchQuery.isEmpty ||
          product.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _handleRedeem(ProductItem product) {
    if (_userPoints >= product.pointsCost) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text(
            'Confirmar Canje',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          content: Text(
            '¿Deseas canjear "${product.title}" por ${product.pointsCost} puntos?',
            style: const TextStyle(color: AppColors.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.outline),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _userPoints -= product.pointsCost;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('¡Canjeaste "${product.title}" con éxito!'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const MainAppBar(title: 'Tienda'),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Sub-header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: const Text(
                'Tienda de Recompensas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
              ),
            ),
          ),
          
          // 1. Cabecera Hero de Saldo
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF004D25), // Dark green background
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.monetization_on_outlined, // S points icon
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'TUS PUNTOS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF6EDD95), // Light green text
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$_userPoints',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      'pts',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF6EDD95), // Light green text
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Barra de Búsqueda
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar productos, cupones...',
                  hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.black87),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(
                      color: Color(0xFF004D25),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Categorías horizontales
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;

                  // Define icons per category
                  IconData catIcon;
                  switch (category) {
                    case 'Todos':
                      catIcon = Icons.grid_view;
                      break;
                    case 'Vehículos':
                      catIcon = Icons.directions_bike;
                      break;
                    case 'Mascotas':
                      catIcon = Icons.pets;
                      break;
                    case 'Ecológico':
                      catIcon = Icons.eco_outlined;
                      break;
                    case 'Accesorios':
                      catIcon = Icons.star_border;
                      break;
                    default:
                      catIcon = Icons.category;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Row(
                        children: [
                          Icon(
                            catIcon,
                            size: 14,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF004D25), // Dark green
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0), // Less rounded corners
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF004D25) : Colors.grey.shade300,
                        ),
                      ),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),

          // 4. Grilla de Productos (2 columnas)
          products.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No se encontraron recompensas.',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 0.55, // Increased height to avoid overflow
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          userPoints: _userPoints,
                          onRedeem: () => _handleRedeem(product),
                        );
                      },
                      childCount: products.length,
                    ),
                  ),
                ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }
}
