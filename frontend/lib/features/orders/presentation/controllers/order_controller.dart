import 'package:flutter/foundation.dart';
import '../../domain/order_model.dart';
import '../../domain/order_repository.dart';

class OrderController extends ChangeNotifier {
  final OrderRepository _repository;

  OrderController(this._repository);

  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _repository.getMyOrders();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> placeOrder(Map<String, dynamic> address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.createOrder(address);
      await fetchOrders(); // Refresh list after placing order
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
