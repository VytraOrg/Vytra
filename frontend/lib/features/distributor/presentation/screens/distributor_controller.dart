import 'package:flutter/foundation.dart';
import 'distributor_models.dart';

/// Single source of truth for the distributor screens.
///
/// Right now it holds demo data in memory. To connect your backend
/// (Firebase / REST), replace the bodies of the methods marked
/// `// TODO(backend)` — every screen listens to this controller, so the UI
/// will update automatically.
class DistributorController extends ChangeNotifier {
  DistributorController._();
  static final DistributorController instance = DistributorController._();

  // ---------------------------------------------------------------- profile
  DistributorProfile profile = const DistributorProfile(
    agencyName: 'Maa Tara Distributors',
    ownerName: 'Ramesh Saha',
    email: 'agency@gmail.com',
    phone: '9830012345',
    address: 'Sahararhat Bazar, Jagannathpur, South 24 Parganas, WB 743503',
    gstNo: '19ABCDE1234F1Z5',
    tradeLicenseNo: 'TL/2026/04512',
    fssaiNo: '12826999000123',
  );

  // ----------------------------------------------------------- agency state
  bool isOpen = true; // manual ON / OFF
  bool isAcceptingOrders = true; // stop taking orders any time
  bool isUpdatingRates = false; // locked while rates are edited

  AgencyStatus get status {
    if (!isOpen) return AgencyStatus.closed;
    if (isUpdatingRates) return AgencyStatus.updating;
    if (!isAcceptingOrders) return AgencyStatus.paused;
    return AgencyStatus.open;
  }

  /// Shopkeeper side must check this before showing "Place order".
  bool get canTakeOrders => status == AgencyStatus.open;

  void setOpen(bool value) {
    isOpen = value;
    notifyListeners();
    _syncAgencyStatus();
  }

  void setAcceptingOrders(bool value) {
    isAcceptingOrders = value;
    notifyListeners();
    _syncAgencyStatus();
  }

  /// Puts the agency into "Updating" mode. Nobody can order until
  /// [finishRateUpdate] or [cancelRateUpdate] is called.
  void startRateUpdate() {
    isUpdatingRates = true;
    notifyListeners();
    _syncAgencyStatus();
  }

  void finishRateUpdate(Map<String, double> newRates) {
    for (final item in inventory) {
      final r = newRates[item.id];
      if (r != null) item.rate = r;
    }
    // TODO(backend): write new rates in one batch, THEN clear the lock.
    isUpdatingRates = false;
    notifyListeners();
    _syncAgencyStatus();
  }

  void cancelRateUpdate() {
    isUpdatingRates = false;
    notifyListeners();
    _syncAgencyStatus();
  }

  void _syncAgencyStatus() {
    // TODO(backend): e.g.
    // FirebaseFirestore.instance.collection('distributors').doc(uid).update({
    //   'isOpen': isOpen,
    //   'isAcceptingOrders': isAcceptingOrders,
    //   'isUpdatingRates': isUpdatingRates,
    //   'status': status.name,
    // });
  }

  void updateProfile(DistributorProfile p) {
    profile = p;
    notifyListeners();
    // TODO(backend): save profile.
  }

  // ---------------------------------------------------------------- orders
  final List<DistributorOrder> orders = [
    DistributorOrder(
      id: 'ORD-1048',
      shopName: 'New Shop Test',
      ownerName: 'Guddu Pandit',
      address: 'Station Road, Sahararhat, WB 743503',
      phone: '9876543210',
      placedAt: DateTime.now().subtract(const Duration(minutes: 25)),
      items: const [
        OrderItem(name: 'Fortune Sunflower Oil', unit: '1 L', qty: 12, rate: 142, gstPercent: 5),
        OrderItem(name: 'Aashirvaad Atta', unit: '5 kg', qty: 6, rate: 248, gstPercent: 5),
        OrderItem(name: 'Tata Salt', unit: '1 kg', qty: 20, rate: 26, gstPercent: 0),
        OrderItem(name: 'Parle-G Biscuit', unit: 'Pack', qty: 48, rate: 9, gstPercent: 18),
      ],
    ),
    DistributorOrder(
      id: 'ORD-1047',
      shopName: 'RBI Shop',
      ownerName: 'Sanjay Mondal',
      address: 'Sahararhat Jagannathpur, Near Bus Stand, WB 743503',
      phone: '9123456780',
      placedAt: DateTime.now().subtract(const Duration(hours: 3)),
      status: DeliveryStatus.accepted,
      items: const [
        OrderItem(name: 'Amul Butter', unit: '500 g', qty: 10, rate: 265, gstPercent: 12),
        OrderItem(name: 'Mother Dairy Dahi', unit: '400 g', qty: 15, rate: 38, gstPercent: 5),
      ],
    ),
    DistributorOrder(
      id: 'ORD-1045',
      shopName: 'Laxmi Bhandar',
      ownerName: 'Pradip Das',
      address: 'Falta Main Road, Ward 4, WB 743504',
      phone: '9007711223',
      placedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      status: DeliveryStatus.dispatched,
      items: const [
        OrderItem(name: 'Basmati Rice', unit: '5 kg', qty: 8, rate: 520, gstPercent: 5),
        OrderItem(name: 'Moong Dal', unit: '1 kg', qty: 10, rate: 118, gstPercent: 0),
        OrderItem(name: 'Haldiram Bhujia', unit: '400 g', qty: 12, rate: 98, gstPercent: 12),
      ],
    ),
    DistributorOrder(
      id: 'ORD-1041',
      shopName: 'Ma Kali Stores',
      ownerName: 'Bapi Ghosh',
      address: 'Diamond Harbour Road, Usthi, WB 743375',
      phone: '9733344556',
      placedAt: DateTime.now().subtract(const Duration(days: 2)),
      status: DeliveryStatus.delivered,
      items: const [
        OrderItem(name: 'Surf Excel', unit: '1 kg', qty: 10, rate: 135, gstPercent: 18),
        OrderItem(name: 'Lifebuoy Soap', unit: '4 pack', qty: 12, rate: 120, gstPercent: 18),
      ],
    ),
  ];

  List<DistributorOrder> recentOrders(int n) {
    final sorted = [...orders]..sort((a, b) => b.placedAt.compareTo(a.placedAt));
    return sorted.take(n).toList();
  }

  DistributorOrder? orderById(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  Iterable<DistributorOrder> get _activeOrders =>
      orders.where((o) => o.status != DeliveryStatus.cancelled);

  int get totalOrders => _activeOrders.length;

  /// Sum of all (non-cancelled) orders, incl. GST.
  double get totalOrderValue =>
      _activeOrders.fold<double>(0, (s, o) => s + o.grandTotal);

  int countByStatus(DeliveryStatus s) =>
      orders.where((o) => o.status == s).length;

  void updateOrderStatus(String id, DeliveryStatus s) {
    final o = orderById(id);
    if (o == null) return;
    o.status = s;
    notifyListeners();
    // TODO(backend): update order + push notification to shopkeeper
    // (e.g. on `dispatched`: "Your order ORD-1048 is on the way").
  }

  // ------------------------------------------------------------- inventory
  final List<InventoryItem> inventory = [
    InventoryItem(id: 'p1', name: 'Fortune Sunflower Oil', category: 'Staples', unit: '1 L', rate: 142, stock: 120),
    InventoryItem(id: 'p2', name: 'Aashirvaad Atta', category: 'Staples', unit: '5 kg', rate: 248, stock: 64),
    InventoryItem(id: 'p3', name: 'Tata Salt', category: 'Staples', unit: '1 kg', rate: 26, stock: 300),
    InventoryItem(id: 'p4', name: 'Basmati Rice', category: 'Staples', unit: '5 kg', rate: 520, stock: 40),
    InventoryItem(id: 'p5', name: 'Amul Butter', category: 'Dairy', unit: '500 g', rate: 265, stock: 35),
    InventoryItem(id: 'p6', name: 'Mother Dairy Dahi', category: 'Dairy', unit: '400 g', rate: 38, stock: 0, isAvailable: false),
    InventoryItem(id: 'p7', name: 'Parle-G Biscuit', category: 'Snacks', unit: 'Pack', rate: 9, stock: 600),
    InventoryItem(id: 'p8', name: 'Haldiram Bhujia', category: 'Snacks', unit: '400 g', rate: 98, stock: 80),
    InventoryItem(id: 'p9', name: 'Surf Excel', category: 'Home Care', unit: '1 kg', rate: 135, stock: 55),
  ];

  void setProductAvailable(String id, bool value) {
    for (final p in inventory) {
      if (p.id == id) p.isAvailable = value;
    }
    notifyListeners();
    // TODO(backend): update product availability.
  }
}
