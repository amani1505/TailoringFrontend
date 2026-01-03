class Tailor {
  final String id;
  final String businessName;
  final String ownerName;
  final String email;
  final String? phoneNumber;
  final String? address;
  final String? city;
  final String? country;
  final String? bio;
  final String? profileImage;
  final List<String>? specialties;
  final double rating;
  final int totalOrders;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tailor({
    required this.id,
    required this.businessName,
    required this.ownerName,
    required this.email,
    this.phoneNumber,
    this.address,
    this.city,
    this.country,
    this.bio,
    this.profileImage,
    this.specialties,
    this.rating = 0.0,
    this.totalOrders = 0,
    this.isActive = true,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tailor.fromJson(Map<String, dynamic> json) {
    return Tailor(
      id: json['id'] as String,
      businessName: json['businessName'] as String,
      ownerName: json['ownerName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      bio: json['bio'] as String?,
      profileImage: json['profileImage'] as String?,
      specialties: json['specialties'] != null
          ? List<String>.from(json['specialties'] as List)
          : null,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessName': businessName,
      'ownerName': ownerName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'city': city,
      'country': country,
      'bio': bio,
      'profileImage': profileImage,
      'specialties': specialties,
      'rating': rating,
      'totalOrders': totalOrders,
      'isActive': isActive,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
