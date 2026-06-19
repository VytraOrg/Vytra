import '../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.email,
    required super.role,
    super.name = '',
    super.businessName = '',
    super.phone = '',
    super.imageUrl = '',
    super.accessToken,
    super.refreshToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Cast to proper Map (handles Hive's LinkedHashMap)
    final safeJson = Map<String, dynamic>.from(json);
    
    // Unwrap if backend returned full { user: {...}, access_token: ... } shape
    Map<String, dynamic> data;
    if (safeJson.containsKey('user') && safeJson['user'] is Map) {
      data = Map<String, dynamic>.from(safeJson['user'] as Map);
    } else {
      data = safeJson;
    }

    return UserModel(
      id: (data['id'] ?? data['_id'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      role: (data['role'] ?? 'Customer').toString(),
      name: (data['name'] ?? '').toString(),
      businessName: (data['businessName'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      accessToken: safeJson['access_token']?.toString() ?? data['accessToken']?.toString(),
      refreshToken: safeJson['refresh_token']?.toString() ?? data['refreshToken']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'role': role,
    'name': name,
    'businessName': businessName,
    'phone': phone,
    'imageUrl': imageUrl,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };
}
