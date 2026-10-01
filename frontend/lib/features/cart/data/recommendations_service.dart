import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_constants.dart';
import '../../shop/data/product_model.dart';

class RecommendationsService {
  final http.Client _client;

  RecommendationsService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches intelligent cart recommendations based on products currently in the cart
  Future<List<ProductModel>> getCartRecommendations({
    List<String> productIds = const [],
    String? shopId,
    int limit = 8,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      if (productIds.isNotEmpty) {
        queryParams['productIds'] = productIds.join(',');
      }
      if (shopId != null && shopId.isNotEmpty) {
        queryParams['shopId'] = shopId;
      }

      final uri = Uri.parse('$apiBaseUrl/recommendations/cart').replace(queryParameters: queryParams);
      final response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = (decoded['data'] as List?) ?? [];
        return list
            .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
