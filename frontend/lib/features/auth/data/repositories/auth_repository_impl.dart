import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<UserEntity> login(String email, String password, String role) async {
    final userModel = await remoteDataSource.login(email, password, role);
    await localDataSource.saveUser(userModel);
    return userModel;
  }

  @override
  Future<UserEntity> register(Map<String, dynamic> userData) async {
    final userModel = await remoteDataSource.register(userData);
    await localDataSource.saveUser(userModel);
    return userModel;
  }

  @override
  Future<UserEntity> updateProfile(Map<String, dynamic> profileData) async {
    final userModel = await remoteDataSource.updateProfile(profileData);
    await localDataSource.saveUser(userModel);
    return userModel;
  }

  @override
  UserEntity? getCachedUser() {
    return localDataSource.getCachedUser();
  }
}
