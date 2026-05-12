import 'package:flutter/foundation.dart';
import '../../domain/cart_model.dart';
import '../../domain/cart_repository.dart';

class CartController extends ChangeNotifier {
  final CartRepository _repository;

  CartController(this._repository);

  CartModel? _cart;
  CartModel? get cart => _cart;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cart = await _repository.getCart();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(String productId, {int quantity = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cart = await _repository.addItem(productId, quantity);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFromCart(String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cart = await _repository.removeItem(productId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
