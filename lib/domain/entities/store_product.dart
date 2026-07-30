class StoreProduct {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int pointsCost;
  final int stock;
  final String category;

  StoreProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.pointsCost,
    this.stock = 10,
    this.category = 'General',
  });

  StoreProduct copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? pointsCost,
    int? stock,
    String? category,
  }) {
    return StoreProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      pointsCost: pointsCost ?? this.pointsCost,
      stock: stock ?? this.stock,
      category: category ?? this.category,
    );
  }
}
