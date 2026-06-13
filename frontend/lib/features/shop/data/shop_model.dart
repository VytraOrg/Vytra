import '../domain/entities/shop_entity.dart';

class ShopModel extends Shop {
  ShopModel({
    required super.id,
    required super.name,
    required super.category,
    required super.shopType,
    super.description,
    super.imageUrl,
    super.rating,
    super.totalReviews,
    super.status,
    super.verificationStatus,
    super.gstCertificateUrl,
    super.tradeLicenseUrl,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'Retail',
      shopType: json['shopType'] ?? 'Retailer',
      description: json['description'],
      imageUrl: json['imageUrl'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? 'Open',
      verificationStatus: json['verificationStatus'] ?? 'Unverified',
      gstCertificateUrl: json['gstCertificateUrl'],
      tradeLicenseUrl: json['tradeLicenseUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'shopType': shopType,
    'description': description,
    'imageUrl': imageUrl,
    'rating': rating,
    'totalReviews': totalReviews,
    'status': status,
    'verificationStatus': verificationStatus,
    'gstCertificateUrl': gstCertificateUrl,
    'tradeLicenseUrl': tradeLicenseUrl,
  };
}
