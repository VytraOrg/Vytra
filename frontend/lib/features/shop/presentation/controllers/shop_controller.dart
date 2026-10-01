import 'package:flutter/foundation.dart';
import '../../domain/shop_repository.dart';
import '../../data/shop_model.dart';
import '../../data/product_model.dart';

class ShopController extends ChangeNotifier {
  final ShopRepository _repository;

  ShopController(this._repository);

  List<ShopModel> _shops = [];
  List<ShopModel> get shops => _shops;

  List<ProductModel> _searchResults = [];
  List<ProductModel> get searchResults => _searchResults;

  List<String> _suggestions = [];
  List<String> get suggestions => _suggestions;

  List<String> _suggestedCategories = [];
  List<String> get suggestedCategories => _suggestedCategories;

  bool _isAutoCorrected = false;
  bool get isAutoCorrected => _isAutoCorrected;

  String _correctedQuery = '';
  String get correctedQuery => _correctedQuery;

  String? _didYouMean;
  String? get didYouMean => _didYouMean;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchShops({
    String? shopType,
    String? category,
    String? search,
    double? lat,
    double? lng,
    bool forceRefresh = false,
  }) async {
    // Only show full loading spinner if we don't already have cached shops
    if (_shops.isEmpty) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _shops = await _repository.getShops(
        shopType: shopType,
        category: category,
        search: search,
        lat: lat,
        lng: lng,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchGlobal(
    String query, {
    String? category,
    String? shopType,
    double? lat,
    double? lng,
    bool forceRefresh = false,
  }) async {
    final hasQuery = query.trim().isNotEmpty;
    final hasCategory = category != null && category != 'All' && category.trim().isNotEmpty;

    if (!hasQuery && !hasCategory) {
      _searchResults = [];
      _isAutoCorrected = false;
      _correctedQuery = '';
      _didYouMean = null;
      notifyListeners();
      return;
    }

    if (_searchResults.isEmpty) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final payload = await _repository.searchGlobalProducts(
        query: query,
        category: category,
        shopType: shopType,
        lat: lat,
        lng: lng,
        forceRefresh: forceRefresh,
      );
      _searchResults = payload.items;
      _isAutoCorrected = payload.isAutoCorrected;
      _correctedQuery = payload.correctedQuery;
      _didYouMean = payload.didYouMean;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSuggestions(String query, {String? shopType}) async {
    if (query.trim().length < 2) {
      _suggestions = [];
      _suggestedCategories = [];
      notifyListeners();
      return;
    }
    try {
      final res = await _repository.getSuggestions(query: query, shopType: shopType);
      _suggestions = res['suggestions'] ?? [];
      _suggestedCategories = res['categories'] ?? [];
      notifyListeners();
    } catch (_) {
      _suggestions = [];
      _suggestedCategories = [];
    }
  }

  void clearSuggestions() {
    _suggestions = [];
    _suggestedCategories = [];
    notifyListeners();
  }
}

