import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../data/product_model.dart';
import '../data/shop_model.dart';

class ShopRepository {
  final ApiClient _apiClient;

  ShopRepository(this._apiClient);

  Future<List<ShopModel>> getShops({String? shopType, String? category, String? search}) async {
    try {
      final queryParams = <String, String>{};
      if (shopType != null) queryParams['shopType'] = shopType;
      if (category != null && category != 'All') queryParams['category'] = category;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      
      final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      final endpoint = queryString.isEmpty ? '/shops' : '/shops?$queryString';
      
      final response = await _apiClient.get(endpoint); 
      return (response as List).map((e) => ShopModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductModel>> getProducts(String shopId) async {
    try {
      final response = await _apiClient.get('/products?shopId=$shopId&limit=100');
      // Backend returns paginated { items: [...], meta: {...} }
      final List<dynamic> items = response is Map
          ? (response['items'] as List? ?? [])
          : (response as List? ?? []);
      return items.map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductModel>> searchGlobalProducts({required String query, String? shopType}) async {
    try {
      final keywords = query.trim().split(RegExp(r'\s+')).where((k) => k.isNotEmpty).toList();

      if (keywords.isEmpty) return [];

      final futures = keywords.map((kw) async {
        try {
          final q = Uri.encodeComponent(kw);
          final endpoint = shopType != null
              ? '/products/search?q=$q&shopType=$shopType'
              : '/products/search?q=$q';
          final response = await _apiClient.get(endpoint);
          // searchGlobal returns a raw array
          final List<dynamic> items = response is List ? response : [];
          return items.map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e))).toList();
        } catch (_) {
          return <ProductModel>[];
        }
      });

      final results = await Future.wait(futures);

      final seen = <String>{};
      final merged = <ProductModel>[];
      for (final batch in results) {
        for (final item in batch) {
          if (seen.add(item.id)) {
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
