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
}

/// What a shopkeeper sees when trying to order from this agency.
/// open     -> orders allowed
/// paused   -> agency is ON but has stopped taking orders
/// updating -> rates are being changed, ordering is locked
/// closed   -> agency switched OFF
enum AgencyStatus { open, paused, updating, closed }

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
