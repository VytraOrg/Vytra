class UserModel {
  final String id;
  final String email;
  final String role;
  final String name;
  final String businessName;
  final String phone;
  final String? accessToken;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.name = '',
    this.businessName = '',
    this.phone = '',
    this.accessToken,
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
      accessToken: safeJson['access_token']?.toString() ?? data['accessToken']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'role': role,
    'name': name,
    'businessName': businessName,
    'phone': phone,
    'accessToken': accessToken,
  };
}
