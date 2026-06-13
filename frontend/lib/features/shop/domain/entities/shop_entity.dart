class Shop {
  final String id;
  final String name;
  final String category;
  final String shopType;
  final String? description;
  final String? imageUrl;
  final double rating;
  final int totalReviews;
  final String status;
  final String verificationStatus;
  final String? gstCertificateUrl;
  final String? tradeLicenseUrl;

  Shop({
    required this.id,
    required this.name,
    required this.category,
    required this.shopType,
    this.description,
    this.imageUrl,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.status = 'Open',
    this.verificationStatus = 'Unverified',
    this.gstCertificateUrl,
    this.tradeLicenseUrl,
  });
}
