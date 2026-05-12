import '../../../core/network/api_client.dart';
import 'order_model.dart';

class OrderRepository {
  final ApiClient _apiClient;

  OrderRepository(this._apiClient);

  Future<List<OrderModel>> getMyOrders() async {
    try {
      final response = await _apiClient.get('/orders/my');
      return (response as List).map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<OrderModel> createOrder(Map<String, dynamic> deliveryAddress) async {
    try {
      final response = await _apiClient.post('/orders', {'deliveryAddress': deliveryAddress});
      return OrderModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      rethrow;
    }
  }

  Future<OrderModel> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await _apiClient.put('/orders/$orderId/status', {'status': status});
      return OrderModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      rethrow;
    }
  }
}
