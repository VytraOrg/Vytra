import '../../../core/network/api_client.dart';
import '../../../core/cache/cache_manager.dart';
import '../data/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<UserModel> login(String email, String password, String role) async {
    final response = await _apiClient.post('/auth/login', {
      'email': email,
      'password': password,
      'role': role,
    });

    final user = UserModel.fromJson(response);
    await CacheManager.saveUser(user.toJson()); 
    return user;
  }

  Future<UserModel> register(Map<String, dynamic> userData) async {
    final response = await _apiClient.post('/auth/register', userData);
    final user = UserModel.fromJson(response);
    await CacheManager.saveUser(user.toJson()); 
    return user;
  }

  UserModel? getCachedUser() {
    final data = CacheManager.getUser();
    return data != null ? UserModel.fromJson(data) : null;
  }
}
