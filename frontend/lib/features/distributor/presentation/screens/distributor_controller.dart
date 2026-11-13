import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import 'distributor_models.dart';

/// Single source of truth for the distributor screens.
/// Wired directly to live NestJS `/api/v1/distributors` endpoints.
class DistributorController extends ChangeNotifier {
  DistributorController._();
  static final DistributorController instance = DistributorController._();

  ApiClient? _apiClient;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ---------------------------------------------------------------- profile
  DistributorProfile profile = const DistributorProfile(
    agencyName: 'Loading Agency...',
    ownerName: '',
    email: '',
    phone: '',
    address: '',
    gstNo: '',
    tradeLicenseNo: '',
    fssaiNo: '',
  );

  // ----------------------------------------------------------- agency state
  bool isOpen = true;
  bool isAcceptingOrders = true;
  bool isUpdatingRates = false;

  AgencyStatus get status {
    if (!isOpen) return AgencyStatus.closed;
    if (isUpdatingRates) return AgencyStatus.updating;
    if (!isAcceptingOrders) return AgencyStatus.paused;
    return AgencyStatus.open;
  }

  bool get canTakeOrders => status == AgencyStatus.open;

  // ---------------------------------------------------------------- data lists
  List<DistributorOrder> orders = [];
  List<InventoryItem> inventory = [];

  // ------------------------------------------------------------ initialization
  Future<void> init(ApiClient client) async {
    _apiClient = client;
    await loadData();
  }

  Future<void> loadData() async {
    if (_apiClient == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final futures = await Future.wait([
        _apiClient!.get('/distributors/my'),
        _apiClient!.get('/distributors/inventory'),
        _apiClient!.get('/distributors/orders'),
      ]);

      // 1. Profile & Status
      final profileRes = futures[0];
      if (profileRes != null && profileRes is Map) {
        final map = Map<String, dynamic>.from(profileRes);
        profile = DistributorProfile.fromJson(map);
        isOpen = map['isOpen'] ?? true;
        isAcceptingOrders = map['isAcceptingOrders'] ?? true;
        isUpdatingRates = map['isUpdatingRates'] ?? false;
      }

      // 2. Inventory
      final invRes = futures[1];
      if (invRes != null && invRes is List) {
        inventory = invRes
            .map((item) => InventoryItem.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      // 3. Orders
      final ordersRes = futures[2];
      if (ordersRes != null && ordersRes is List) {
        orders = ordersRes
            .map((item) => DistributorOrder.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('[DistributorController] Error loading live data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------- agency actions
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

  void startRateUpdate() {
    isUpdatingRates = true;
    notifyListeners();
    _syncAgencyStatus();
  }

  Future<void> finishRateUpdate(Map<String, double> newRates) async {
    for (final item in inventory) {
      final r = newRates[item.id];
      if (r != null) item.rate = r;
    }
    isUpdatingRates = false;
    notifyListeners();

    try {
      await _apiClient?.put('/distributors/inventory/rates', {'rates': newRates});
    } catch (e) {
      debugPrint('[DistributorController] Error batch updating rates: $e');
    }
  }

  void cancelRateUpdate() {
    isUpdatingRates = false;
    notifyListeners();
    _syncAgencyStatus();
  }

  Future<void> _syncAgencyStatus() async {
    try {
      await _apiClient?.put('/distributors/my/status', {
        'isOpen': isOpen,
        'isAcceptingOrders': isAcceptingOrders,
        'isUpdatingRates': isUpdatingRates,
        'status': status.name,
      });
    } catch (e) {
      debugPrint('[DistributorController] Error syncing agency status: $e');
    }
  }

  Future<void> updateProfile(DistributorProfile p) async {
    profile = p;
    notifyListeners();

    try {
      await _apiClient?.put('/distributors/my/profile', p.toJson());
    } catch (e) {
      debugPrint('[DistributorController] Error saving profile: $e');
    }
  }

  // ---------------------------------------------------------------- orders
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

  double get totalOrderValue =>
      _activeOrders.fold<double>(0, (s, o) => s + o.grandTotal);

  int countByStatus(DeliveryStatus s) =>
      orders.where((o) => o.status == s).length;

  Future<void> updateOrderStatus(String id, DeliveryStatus s) async {
    final o = orderById(id);
    if (o == null) return;
    o.status = s;
    notifyListeners();

    try {
      await _apiClient?.put('/distributors/orders/$id/status', {'status': s.name});
    } catch (e) {
      debugPrint('[DistributorController] Error updating order status: $e');
    }
  }

  // ------------------------------------------------------------- inventory
  Future<void> setProductAvailable(String id, bool value) async {
    for (final p in inventory) {
      if (p.id == id) p.isAvailable = value;
    }
    notifyListeners();

    try {
      await _apiClient?.put('/distributors/inventory/$id/availability', {'isAvailable': value});
    } catch (e) {
      debugPrint('[DistributorController] Error toggling availability: $e');
    }
  }

  Future<void> addProduct({
    required String name,
    required String category,
    required String unit,
    required double rate,
    required int stock,
    double gstPercent = 5,
  }) async {
    try {
      final res = await _apiClient?.post('/distributors/inventory', {
        'name': name,
        'category': category,
        'unit': unit,
        'rate': rate,
        'stock': stock,
        'gstPercent': gstPercent,
        'isAvailable': true,
      });
      if (res != null && res is Map) {
        inventory.insert(0, InventoryItem.fromJson(Map<String, dynamic>.from(res)));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[DistributorController] Error adding product: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    inventory.removeWhere((p) => p.id == id);
    notifyListeners();

    try {
      await _apiClient?.delete('/distributors/inventory/$id');
    } catch (e) {
      debugPrint('[DistributorController] Error deleting product: $e');
    }
  }
}
