import 'package:flutter/foundation.dart';
import '../../../orders/domain/order_repository.dart';

class AccountController extends ChangeNotifier {
  final OrderRepository _orderRepository;

  AccountController(this._orderRepository);

  int _totalOrders = 0;
  int get totalOrders => _totalOrders;

  double _totalSpent = 0;
  double get totalSpent => _totalSpent;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      final orders = await _orderRepository.getMyOrders();
      _totalOrders = orders.length;
      _totalSpent = orders.fold(0, (sum, order) => sum + order.totalAmount);
    } catch (e) {
      if (kDebugMode) print('❌ Error loading account stats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
