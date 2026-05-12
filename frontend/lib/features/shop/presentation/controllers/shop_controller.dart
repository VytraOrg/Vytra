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

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchShops({String? shopType, String? category, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _shops = await _repository.getShops(
        shopType: shopType,
        category: category,
        search: search,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchGlobal(String query, {String? shopType}) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _repository.searchGlobalProducts(
        query: query,
        shopType: shopType,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
