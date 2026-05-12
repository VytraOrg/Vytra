class CartItemModel {
  final String productId;
  final String name;
  final double price;
  final int quantity;

  CartItemModel({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Product',
      price: (json['price'] ?? 0.0).toDouble(),
      quantity: (json['quantity'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'price': price,
    'quantity': quantity,
  };
}

class CartModel {
  final String userId;
  final List<CartItemModel> items;

  CartModel({
    required this.userId,
    required this.items,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      userId: json['userId']?.toString() ?? '',
      items: (json['items'] as List?)
              ?.map((item) => CartItemModel.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
    );
  }

  double get totalAmount {
    return items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }
}
