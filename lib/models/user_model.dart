class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? nationality;
  final String? city;
  final String? currentAddress;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? bio;
  final bool isDriver;
  final bool isActive;
  final bool phoneVerified;
  final bool emailVerified;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.nationality,
    this.city,
    this.currentAddress,
    this.state,
    this.postalCode,
    this.country,
    this.bio,
    required this.isDriver,
    required this.isActive,
    required this.phoneVerified,
    required this.emailVerified,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      nationality: json['nationality'],
      city: json['city'],
      currentAddress: json['currentAddress'],
      state: json['state'],
      postalCode: json['postalCode'],
      country: json['country'],
      bio: json['bio'],
      isDriver: json['isDriver'] ?? false,
      isActive: json['isActive'] ?? true,
      phoneVerified: json['phoneVerified'] ?? false,
      emailVerified: json['emailVerified'] ?? false,
      profileImageUrl: json['profileImageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'nationality': nationality,
      'city': city,
      'currentAddress': currentAddress,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'bio': bio,
      'isDriver': isDriver,
      'isActive': isActive,
      'phoneVerified': phoneVerified,
      'emailVerified': emailVerified,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? nationality,
    String? city,
    String? currentAddress,
    String? state,
    String? postalCode,
    String? country,
    String? bio,
    bool? isDriver,
    bool? isActive,
    bool? phoneVerified,
    bool? emailVerified,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      nationality: nationality ?? this.nationality,
      city: city ?? this.city,
      currentAddress: currentAddress ?? this.currentAddress,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      bio: bio ?? this.bio,
      isDriver: isDriver ?? this.isDriver,
      isActive: isActive ?? this.isActive,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      emailVerified: emailVerified ?? this.emailVerified,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  // Convenience getters
  String get fullName => name;
  double? get rating => null; // Will be calculated from ratings
  String get firstName => name.split(' ').first;
  String get lastName => name.split(' ').length > 1 ? name.split(' ').last : '';
  bool get isPassenger => !isDriver;
}
