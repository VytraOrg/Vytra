class ProductModel {
  final String id;
  final String name;
  final String description;
  final String unit;
  final double price;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.unit,
    required this.price,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unnamed Product').toString(),
      description: (json['description'] ?? 'No description').toString(),
      unit: (json['unit'] ?? '1 pc').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'unit': unit,
      'price': price,
    };
  }
}
