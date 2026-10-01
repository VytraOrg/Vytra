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

  // Track in-flight operations per product to prevent spamming
  final Set<String> _pendingProductIds = <String>{};
  bool isProductPending(String productId) => _pendingProductIds.contains(productId);

  int getProductQuantity(String productId) {
    if (_cart == null) return 0;
    try {
      final item = _cart!.items.firstWhere(
        (it) => it.productId == productId,
      );
      return item.quantity;
    } catch (_) {
      return 0;
    }
  }

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
    if (_pendingProductIds.contains(productId)) return;

    _pendingProductIds.add(productId);
    notifyListeners();

    try {
      _cart = await _repository.addItem(productId, quantity);
    } catch (e) {
      _error = e.toString();
    } finally {
      _pendingProductIds.remove(productId);
      notifyListeners();
    }
  }

  Future<void> removeFromCart(String productId) async {
    if (_pendingProductIds.contains(productId)) return;

    _pendingProductIds.add(productId);
    notifyListeners();

    try {
      _cart = await _repository.removeItem(productId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _pendingProductIds.remove(productId);
      notifyListeners();
    }
  }
}
