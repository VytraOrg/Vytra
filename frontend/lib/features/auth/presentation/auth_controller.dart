import 'package:flutter/material.dart';
import '../domain/auth_repository.dart';
import '../data/user_model.dart';
import '../../../core/cache/cache_manager.dart';

class AuthController with ChangeNotifier {
  final AuthRepository _repository;

  AuthController(this._repository) {
    initSession();
  }

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void initSession() {
    _currentUser = _repository.getCachedUser();
    notifyListeners();
  }

  Future<bool> login(String email, String password, String role) async {
    _setLoading(true);
    _error = null;
    try {
      _currentUser = await _repository.login(email, password, role);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _setLoading(true);
    _error = null;
    try {
      _currentUser = await _repository.register(userData);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await CacheManager.clearAll(); // Security: Clear all cached data on logout
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
