import '../../domain/entities/store_product.dart';

class StoreProductModel extends StoreProduct {
  StoreProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.imageUrl,
    required super.pointsCost,
    super.stock,
    super.category,
  });

  factory StoreProductModel.fromJson(Map<String, dynamic> json) {
    return StoreProductModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'] ?? '',
      pointsCost: json['pointsCost'] ?? 0,
      stock: json['stock'] ?? 10,
      category: json['category'] ?? 'General',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'pointsCost': pointsCost,
      'stock': stock,
      'category': category,
    };
  }

  factory StoreProductModel.fromEntity(StoreProduct entity) {
    return StoreProductModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      imageUrl: entity.imageUrl,
      pointsCost: entity.pointsCost,
      stock: entity.stock,
      category: entity.category,
    );
  }
}
