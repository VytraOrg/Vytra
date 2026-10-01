import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../data/product_model.dart';
import '../data/shop_model.dart';

class SearchResultPayload {
  final List<ProductModel> items;
  final bool isAutoCorrected;
  final String originalQuery;
  final String correctedQuery;
  final String? didYouMean;

  SearchResultPayload({
    required this.items,
    this.isAutoCorrected = false,
    this.originalQuery = '',
    this.correctedQuery = '',
    this.didYouMean,
  });
}

class ShopRepository {
  final ApiClient _apiClient;

  ShopRepository(this._apiClient);

  Future<List<ShopModel>> getShops({
    String? shopType,
    String? category,
    String? search,
    double? lat,
    double? lng,
    bool forceRefresh = false,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (shopType != null) queryParams['shopType'] = shopType;
      if (category != null && category != 'All') queryParams['category'] = category;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (lat != null) queryParams['lat'] = lat.toString();
      if (lng != null) queryParams['lng'] = lng.toString();
      
      final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      final endpoint = queryString.isEmpty ? '/shops' : '/shops?$queryString';
      
      final response = await _apiClient.get(
        endpoint,
        useCache: true,
        maxAge: const Duration(minutes: 5),
        forceRefresh: forceRefresh,
      ); 
      return (response as List).map((e) => ShopModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductModel>> getProducts(String shopId, {bool forceRefresh = false}) async {
    try {
      final response = await _apiClient.get(
        '/products?shopId=$shopId&limit=100',
        useCache: true,
        maxAge: const Duration(minutes: 5),
        forceRefresh: forceRefresh,
      );
      // Backend returns paginated { items: [...], meta: {...} }
      final List<dynamic> items = response is Map
          ? (response['items'] as List? ?? [])
          : (response as List? ?? []);
      return items.map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<SearchResultPayload> searchGlobalProducts({
    required String query,
    String? category,
    String? shopType,
    double? lat,
    double? lng,
    bool forceRefresh = false,
  }) async {
    try {
      final trimmed = query.trim();
      final hasQuery = trimmed.isNotEmpty;
      final hasCategory = category != null && category != 'All' && category.trim().isNotEmpty;

      if (!hasQuery && !hasCategory) return SearchResultPayload(items: []);

      final queryParams = <String, String>{};
      if (hasQuery) queryParams['q'] = Uri.encodeComponent(trimmed);
      if (hasCategory) queryParams['category'] = Uri.encodeComponent(category.trim());
      if (shopType != null) queryParams['shopType'] = shopType;
      if (lat != null) queryParams['lat'] = lat.toString();
      if (lng != null) queryParams['lng'] = lng.toString();

      final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      final endpoint = '/products/search?$queryString';
      final response = await _apiClient.get(
        endpoint,
        useCache: true,
        maxAge: const Duration(minutes: 3),
        forceRefresh: forceRefresh,
      );

      if (response is Map) {
        final List<dynamic> rawItems = response['items'] as List? ?? [];
        final items = rawItems.map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e))).toList();
        return SearchResultPayload(
          items: items,
          isAutoCorrected: response['isAutoCorrected'] == true,
          originalQuery: response['originalQuery'] ?? query,
          correctedQuery: response['correctedQuery'] ?? query,
          didYouMean: response['didYouMean'],
        );
      } else if (response is List) {
        final items = response.map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e))).toList();
        return SearchResultPayload(items: items);
      }

      return SearchResultPayload(items: []);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, List<String>>> getSuggestions({required String query, String? shopType}) async {
    try {
      final trimmed = query.trim();
      if (trimmed.length < 2) return {'suggestions': [], 'categories': []};

      final q = Uri.encodeComponent(trimmed);
      final endpoint = shopType != null
          ? '/products/suggestions?q=$q&shopType=$shopType'
          : '/products/suggestions?q=$q';
      final response = await _apiClient.get(endpoint);
      if (response is Map) {
        final suggestions = List<String>.from(response['suggestions'] ?? []);
        final categories = List<String>.from(response['categories'] ?? []);
        return {'suggestions': suggestions, 'categories': categories};
      }
      return {'suggestions': [], 'categories': []};
    } catch (_) {
      return {'suggestions': [], 'categories': []};
    }
  }
}

