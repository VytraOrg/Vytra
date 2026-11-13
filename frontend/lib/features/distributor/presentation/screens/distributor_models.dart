// Data models for the Distributor module.

enum DeliveryStatus { pending, accepted, dispatched, delivered, cancelled }

extension DeliveryStatusX on DeliveryStatus {
  String get label {
    switch (this) {
      case DeliveryStatus.pending:
        return 'Pending';
      case DeliveryStatus.accepted:
        return 'Accepted';
      case DeliveryStatus.dispatched:
        return 'Dispatched';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// The next step in the delivery flow (null when the flow is finished).
  DeliveryStatus? get next {
    switch (this) {
      case DeliveryStatus.pending:
        return DeliveryStatus.accepted;
      case DeliveryStatus.accepted:
        return DeliveryStatus.dispatched;
      case DeliveryStatus.dispatched:
        return DeliveryStatus.delivered;
      case DeliveryStatus.delivered:
      case DeliveryStatus.cancelled:
        return null;
    }
  }

  static DeliveryStatus fromString(String? val) {
    switch ((val ?? '').toLowerCase()) {
      case 'accepted':
      case 'processing':
        return DeliveryStatus.accepted;
      case 'dispatched':
      case 'shipped':
        return DeliveryStatus.dispatched;
      case 'delivered':
        return DeliveryStatus.delivered;
      case 'cancelled':
        return DeliveryStatus.cancelled;
      case 'pending':
      case 'placed':
      default:
        return DeliveryStatus.pending;
    }
  }
}

/// What a shopkeeper sees when trying to order from this agency.
/// open     -> orders allowed
/// paused   -> agency is ON but has stopped taking orders
/// updating -> rates are being changed, ordering is locked
/// closed   -> agency switched OFF
enum AgencyStatus { open, paused, updating, closed }

extension AgencyStatusX on AgencyStatus {
  static AgencyStatus fromString(String? val) {
    switch ((val ?? '').toLowerCase()) {
      case 'closed':
        return AgencyStatus.closed;
      case 'paused':
        return AgencyStatus.paused;
      case 'updating':
        return AgencyStatus.updating;
      case 'open':
      default:
        return AgencyStatus.open;
    }
  }
}

class OrderItem {
  final String name;
  final String unit;
  final int qty;
  final double rate;
  final double gstPercent;

  const OrderItem({
    required this.name,
    required this.unit,
    required this.qty,
    required this.rate,
    this.gstPercent = 5,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'Unit',
      qty: (json['qty'] ?? json['quantity'] ?? 1) is num
          ? (json['qty'] ?? json['quantity'] as num).toInt()
          : int.tryParse(json['qty']?.toString() ?? '') ?? 1,
      rate: (json['rate'] ?? json['price'] ?? 0) is num
          ? (json['rate'] ?? json['price'] as num).toDouble()
          : double.tryParse(json['rate']?.toString() ?? '') ?? 0.0,
      gstPercent: (json['gstPercent'] ?? 5) is num
          ? (json['gstPercent'] as num).toDouble()
          : double.tryParse(json['gstPercent']?.toString() ?? '') ?? 5.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'unit': unit,
        'qty': qty,
        'rate': rate,
        'gstPercent': gstPercent,
      };

  double get amount => qty * rate;
  double get gstAmount => amount * gstPercent / 100;
}

class DistributorOrder {
  final String id;
  final String shopName;
  final String ownerName;
  final String address;
  final String phone;
  final DateTime placedAt;
  final List<OrderItem> items;
  DeliveryStatus status;

  DistributorOrder({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.address,
    required this.phone,
    required this.placedAt,
    required this.items,
    this.status = DeliveryStatus.pending,
  });

  factory DistributorOrder.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];

    final rawDate = json['placedAt'] ?? json['createdAt'];
    DateTime date = DateTime.now();
    if (rawDate != null) {
      date = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    }

    return DistributorOrder(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      shopName: json['shopName']?.toString() ?? 'Local Store',
      ownerName: json['ownerName']?.toString() ?? 'Shopkeeper',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      placedAt: date,
      items: itemsList,
      status: DeliveryStatusX.fromString(json['status']?.toString()),
    );
  }

  int get totalQty => items.fold<int>(0, (s, i) => s + i.qty);
  double get subtotal => items.fold<double>(0, (s, i) => s + i.amount);
  double get gstTotal => items.fold<double>(0, (s, i) => s + i.gstAmount);
  double get grandTotal => subtotal + gstTotal;
}

class InventoryItem {
  final String id;
  final String name;
  final String category;
  final String unit;
  double rate;
  int stock;
  bool isAvailable;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.rate,
    required this.stock,
    this.isAvailable = true,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      unit: json['unit']?.toString() ?? 'Unit',
      rate: (json['rate'] ?? json['price'] ?? 0) is num
          ? (json['rate'] ?? json['price'] as num).toDouble()
          : double.tryParse(json['rate']?.toString() ?? '') ?? 0.0,
      stock: (json['stock'] ?? json['stockQuantity'] ?? 0) is num
          ? (json['stock'] ?? json['stockQuantity'] as num).toInt()
          : int.tryParse(json['stock']?.toString() ?? '') ?? 0,
      isAvailable: json['isAvailable'] == true || json['isAvailable'] == null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'unit': unit,
        'rate': rate,
        'stock': stock,
        'isAvailable': isAvailable,
      };
}

class DistributorProfile {
  final String agencyName;
  final String ownerName;
  final String email;
  final String phone;
  final String address;
  final String gstNo;
  final String tradeLicenseNo;
  final String fssaiNo;

  const DistributorProfile({
    required this.agencyName,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.address,
    required this.gstNo,
    required this.tradeLicenseNo,
    required this.fssaiNo,
  });

  factory DistributorProfile.fromJson(Map<String, dynamic> json) {
    return DistributorProfile(
      agencyName: json['agencyName']?.toString() ?? '',
      ownerName: json['ownerName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      gstNo: json['gstNo']?.toString() ?? '',
      tradeLicenseNo: json['tradeLicenseNo']?.toString() ?? '',
      fssaiNo: json['fssaiNo']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'agencyName': agencyName,
        'ownerName': ownerName,
        'email': email,
        'phone': phone,
        'address': address,
        'gstNo': gstNo,
        'tradeLicenseNo': tradeLicenseNo,
        'fssaiNo': fssaiNo,
      };

  bool get isComplianceComplete =>
      gstNo.isNotEmpty && tradeLicenseNo.isNotEmpty && fssaiNo.isNotEmpty;

  DistributorProfile copyWith({
    String? agencyName,
    String? ownerName,
    String? email,
    String? phone,
    String? address,
    String? gstNo,
    String? tradeLicenseNo,
    String? fssaiNo,
  }) {
    return DistributorProfile(
      agencyName: agencyName ?? this.agencyName,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      gstNo: gstNo ?? this.gstNo,
      tradeLicenseNo: tradeLicenseNo ?? this.tradeLicenseNo,
      fssaiNo: fssaiNo ?? this.fssaiNo,
    );
  }
}
