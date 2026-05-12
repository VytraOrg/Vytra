import '../../../core/network/api_client.dart';
import 'cart_model.dart';

class CartRepository {
  final ApiClient _apiClient;

  CartRepository(this._apiClient);

  Future<CartModel> getCart() async {
    try {
      final response = await _apiClient.get('/cart');
      return CartModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      rethrow;
    }
  }

  Future<CartModel> addItem(String productId, int quantity) async {
    try {
      final response = await _apiClient.post('/cart/items', {
        'productId': productId,
        'quantity': quantity,
      });
      return CartModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      rethrow;
    }
  }

  Future<CartModel> removeItem(String productId) async {
    try {
      final response = await _apiClient.delete('/cart/items/$productId');
      return CartModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      rethrow;
    }
  }
}
