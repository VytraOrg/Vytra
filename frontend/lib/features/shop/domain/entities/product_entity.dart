class Product {
  final String id;
  final String name;
  final String? description;
  final String category;
  final double price;
  final String unit;
  final String? imageUrl;
  final bool isAvailable;
  final String shopId;
  final String? shopName;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.price,
    required this.unit,
    this.imageUrl,
    this.isAvailable = true,
    required this.shopId,
    this.shopName,
  });
}
