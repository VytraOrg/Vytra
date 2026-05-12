import '../domain/entities/product_entity.dart';

class ProductModel extends Product {
  ProductModel({
    required super.id,
    required super.name,
    super.description,
    required super.category,
    required super.price,
    required super.unit,
    super.imageUrl,
    super.isAvailable,
    required super.shopId,
    super.shopName,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      category: json['category'] ?? 'General',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? 'pcs',
      imageUrl: json['imageUrl'],
      isAvailable: json['isAvailable'] ?? true,
      shopId: json['shop'] is Map ? (json['shop']['_id'] ?? '') : (json['shop'] ?? ''),
      shopName: json['shopInfo'] != null ? json['shopInfo']['name'] : (json['shop'] is Map ? json['shop']['name'] : null),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category,
    'price': price,
    'unit': unit,
    'imageUrl': imageUrl,
    'isAvailable': isAvailable,
    'shop': shopId,
  };
}
