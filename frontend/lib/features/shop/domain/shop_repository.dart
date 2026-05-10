import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/cache/cache_manager.dart';
import '../data/product_model.dart';

class ShopRepository {
  final ApiClient _apiClient;

  ShopRepository(this._apiClient);

  /// Fetches fresh shops directly from the API.
  Future<List<Map<String, dynamic>>> getShops({String? shopType, String? category, String? search}) async {
    try {
      final queryParams = <String>[];
      if (shopType != null) queryParams.add('shopType=$shopType');
      if (category != null && category != 'All') queryParams.add('category=$category');
      if (search != null && search.isNotEmpty) queryParams.add('search=$search');
      
      final endpoint = queryParams.isEmpty ? '/shops' : '/shops?${queryParams.join('&')}';
      final response = await _apiClient.get(endpoint); 
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductModel>> getProducts(String shopName) async {
    try {
      final response = await _apiClient.get('/products?shop=$shopName');
      return (response as List).map((e) => ProductModel.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Global search across all shops for specific products (Swiggy/Zomato style).
  /// Supports space-separated multi-keyword queries by firing parallel requests.
  Future<List<Map<String, dynamic>>> searchGlobalProducts({required String query, String? shopType}) async {
    try {
      // Split into individual keywords and search each in parallel
      final keywords = query.trim().split(RegExp(r'\s+')).where((k) => k.isNotEmpty).toList();

      if (keywords.length <= 1) {
        // Single keyword — direct call
        final q = Uri.encodeComponent(keywords.isEmpty ? query : keywords.first);
        final endpoint = shopType != null
            ? '/products/search?q=$q&shopType=$shopType'
            : '/products/search?q=$q';
        final response = await _apiClient.get(endpoint);
        return List<Map<String, dynamic>>.from(response);
      }

      // Multiple keywords — fire in parallel and merge
      final futures = keywords.map((kw) async {
        try {
          final q = Uri.encodeComponent(kw);
          final endpoint = shopType != null
              ? '/products/search?q=$q&shopType=$shopType'
              : '/products/search?q=$q';
          final response = await _apiClient.get(endpoint);
          return List<Map<String, dynamic>>.from(response);
        } catch (_) {
          return <Map<String, dynamic>>[];
        }
      });

      final results = await Future.wait(futures);

      // Merge and deduplicate by product _id
      final seen = <String>{};
      final merged = <Map<String, dynamic>>[];
      for (final batch in results) {
        for (final item in batch) {
          final id = (item['_id'] ?? item['id'] ?? '').toString();
          if (id.isNotEmpty && seen.add(id)) {
            merged.add(item);
          }
        }
      }
      return merged;
    } catch (e) {
      rethrow;
    }
  }
}
