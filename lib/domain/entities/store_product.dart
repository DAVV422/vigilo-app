class StoreProduct {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int pointsCost;
  final int stock;
  final String category;
  final bool active;

  StoreProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.pointsCost,
    this.stock = 10,
    this.category = 'General',
    this.active = true,
  });

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    return StoreProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      pointsCost: (json['pointsCost'] as num).toInt(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? 'General',
      active: json['active'] as bool? ?? true,
    );
  }

  StoreProduct copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? pointsCost,
    int? stock,
    String? category,
    bool? active,
  }) {
    return StoreProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      pointsCost: pointsCost ?? this.pointsCost,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      active: active ?? this.active,
    );
  }
}
