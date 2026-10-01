import '../../../../core/network/api_client.dart';
import '../user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password, String role);
  Future<UserModel> register(Map<String, dynamic> userData);
  Future<UserModel> updateProfile(Map<String, dynamic> profileData);
  Future<Map<String, dynamic>> forgotPassword(String email);
  Future<Map<String, dynamic>> verifyResetOtp(String email, String otp);
  Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<UserModel> login(String email, String password, String role) async {
    final response = await apiClient.post('/auth/login', {
      'email': email,
      'password': password,
      'role': role,
    });
    return UserModel.fromJson(response);
  }

  @override
  Future<UserModel> register(Map<String, dynamic> userData) async {
    final response = await apiClient.post('/auth/register', userData);
    return UserModel.fromJson(response);
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> profileData) async {
    final response = await apiClient.patch('/auth/profile', profileData);
    return UserModel.fromJson(response);
  }

  @override
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await apiClient.post('/auth/forgot-password', {
      'email': email,
    });
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<Map<String, dynamic>> verifyResetOtp(String email, String otp) async {
    final response = await apiClient.post('/auth/verify-reset-otp', {
      'email': email,
      'otp': otp,
    });
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword) async {
    final response = await apiClient.post('/auth/reset-password', {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
    return Map<String, dynamic>.from(response);
  }
}
