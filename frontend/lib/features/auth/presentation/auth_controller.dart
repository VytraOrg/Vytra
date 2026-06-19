import 'package:flutter/material.dart';
import '../domain/entities/user_entity.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/register_usecase.dart';
import '../domain/usecases/get_cached_user_usecase.dart';
import '../../../core/cache/cache_manager.dart';
import '../data/user_model.dart';

class AuthController with ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final GetCachedUserUseCase _getCachedUserUseCase;

  AuthController({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required GetCachedUserUseCase getCachedUserUseCase,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _getCachedUserUseCase = getCachedUserUseCase {
    initSession();
  }

  UserEntity? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserEntity? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void initSession() {
    _currentUser = _getCachedUserUseCase();
    notifyListeners();
  }

  Future<bool> login(String email, String password, String role) async {
    _setLoading(true);
    _error = null;
    try {
      _currentUser = await _loginUseCase(email, password, role);
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
      _currentUser = await _registerUseCase(userData);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePhone(String newPhone) async {
    if (_currentUser == null) return;
    final updatedUser = UserModel(
      id: _currentUser!.id,
      email: _currentUser!.email,
      role: _currentUser!.role,
      name: _currentUser!.name,
      businessName: _currentUser!.businessName,
      phone: newPhone,
      imageUrl: _currentUser!.imageUrl,
      accessToken: _currentUser!.accessToken,
      refreshToken: _currentUser!.refreshToken,
    );
    _currentUser = updatedUser;
    await CacheManager.saveUser(updatedUser.toJson());
    notifyListeners();
  }

  Future<void> updateAvatar(String newImageUrl) async {
    if (_currentUser == null) return;
    final updatedUser = UserModel(
      id: _currentUser!.id,
      email: _currentUser!.email,
      role: _currentUser!.role,
      name: _currentUser!.name,
      businessName: _currentUser!.businessName,
      phone: _currentUser!.phone,
      imageUrl: newImageUrl,
      accessToken: _currentUser!.accessToken,
      refreshToken: _currentUser!.refreshToken,
    );
    _currentUser = updatedUser;
    await CacheManager.saveUser(updatedUser.toJson());
    notifyListeners();
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
