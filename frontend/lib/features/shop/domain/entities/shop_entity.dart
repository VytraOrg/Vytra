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
  final String? verificationRejectedReason;
  final String? verificationRejectedNotes;
  
  // New verification fields
  final String? verificationNotes;
  final String? ownerName;
  final String? ownerPhone;
  final String? address;
  final String? district;
  final String? state;
  final String? pincode;
  final String? gstNumber;
  final String? tradeLicenseNumber;
  final double? latitude;
  final double? longitude;

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
    this.verificationRejectedReason,
    this.verificationRejectedNotes,
    this.verificationNotes,
    this.ownerName,
    this.ownerPhone,
    this.address,
    this.district,
    this.state,
    this.pincode,
    this.gstNumber,
    this.tradeLicenseNumber,
    this.latitude,
    this.longitude,
  });
}
