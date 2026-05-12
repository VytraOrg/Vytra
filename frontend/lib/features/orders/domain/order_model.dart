class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String unit;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.unit,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Product',
      quantity: (json['quantity'] ?? 0).toInt(),
      price: (json['price'] ?? 0.0).toDouble(),
      unit: json['unit']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'quantity': quantity,
    'price': price,
    'unit': unit,
  };
}

class OrderModel {
  final String id;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final dynamic deliveryAddress;

  OrderModel({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.deliveryAddress,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id'] ?? json['id'] ?? '',
      items: (json['items'] as List?)
              ?.map((item) => OrderItem.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'Placed',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      deliveryAddress: json['deliveryAddress'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'items': items.map((e) => e.toJson()).toList(),
    'totalAmount': totalAmount,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'deliveryAddress': deliveryAddress,
  };
}
