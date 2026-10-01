import 'package:flutter/foundation.dart';
import '../domain/entities/user_entity.dart';
import '../domain/repositories/i_auth_repository.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/register_usecase.dart';
import '../domain/usecases/get_cached_user_usecase.dart';
import '../../../core/cache/cache_manager.dart';
import '../data/user_model.dart';

class AuthController with ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final GetCachedUserUseCase _getCachedUserUseCase;
  final IAuthRepository? _authRepository;

  AuthController({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required GetCachedUserUseCase getCachedUserUseCase,
    IAuthRepository? authRepository,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _getCachedUserUseCase = getCachedUserUseCase,
        _authRepository = authRepository {
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

    // Persist to remote backend so it survives logout / login
    if (_authRepository != null) {
      try {
        await _authRepository.updateProfile({'phone': newPhone});
      } catch (e) {
        if (kDebugMode) print('⚠️ Failed to sync phone to remote backend: $e');
      }
    }
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

    // Persist to remote backend so it survives logout / login
    if (_authRepository != null) {
      try {
        await _authRepository.updateProfile({'imageUrl': newImageUrl});
      } catch (e) {
        if (kDebugMode) print('⚠️ Failed to sync avatar to remote backend: $e');
      }
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await CacheManager.clearAll(); // Security: Clear all cached data on logout
    notifyListeners();
  }

  Future<String?> sendPasswordResetOtp(String email) async {
    _setLoading(true);
    _error = null;
    try {
      if (_authRepository == null) throw Exception('Auth repository not available');
      await _authRepository.forgotPassword(email.trim().toLowerCase());
      return null;
    } catch (e) {
      final msg = e.toString().replaceAll('AppError: ', '').replaceAll('Exception: ', '');
      _error = msg;
      return msg;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> verifyResetOtp(String email, String otp) async {
    _setLoading(true);
    _error = null;
    try {
      if (_authRepository == null) throw Exception('Auth repository not available');
      await _authRepository.verifyResetOtp(email.trim().toLowerCase(), otp.trim());
      return null;
    } catch (e) {
      final msg = e.toString().replaceAll('AppError: ', '').replaceAll('Exception: ', '');
      _error = msg;
      return msg;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> resetPassword(String email, String otp, String newPassword) async {
    _setLoading(true);
    _error = null;
    try {
      if (_authRepository == null) throw Exception('Auth repository not available');
      await _authRepository.resetPassword(email.trim().toLowerCase(), otp.trim(), newPassword);
      return null;
    } catch (e) {
      final msg = e.toString().replaceAll('AppError: ', '').replaceAll('Exception: ', '');
      _error = msg;
      return msg;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
