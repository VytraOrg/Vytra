import '../entities/user_entity.dart';

abstract class IAuthRepository {
  Future<UserEntity> login(String email, String password, String role);
  Future<UserEntity> register(Map<String, dynamic> userData);
  Future<UserEntity> updateProfile(Map<String, dynamic> profileData);
  Future<void> forgotPassword(String email);
  Future<void> verifyResetOtp(String email, String otp);
  Future<void> resetPassword(String email, String otp, String newPassword);
  UserEntity? getCachedUser();
}
