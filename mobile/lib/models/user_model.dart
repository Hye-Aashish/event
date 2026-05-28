class UserModel {
  final String id;
  final String phone;
  final String name;
  final String? email;
  final String role;
  final bool isVerified;
  final String verificationStatus; // none, pending, approved, rejected
  final String? verificationSelfie;
  final String? verificationIdCard;
  final String? verificationReason;
  final String? profilePhoto;
  final String? aadhaarNumber;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.phone,
    required this.name,
    this.email,
    required this.role,
    required this.isVerified,
    required this.verificationStatus,
    this.verificationSelfie,
    this.verificationIdCard,
    this.verificationReason,
    this.profilePhoto,
    this.aadhaarNumber,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      phone: json['phone'] ?? json['phoneNumber'] ?? '',
      name: json['name'] ?? 'Guest',
      email: json['email'],
      role: json['role'] ?? 'user',
      isVerified: json['isVerified'] ?? false,
      verificationStatus: json['verificationStatus'] ?? 'none',
      verificationSelfie: json['verificationSelfie'],
      verificationIdCard: json['verificationIdCard'],
      verificationReason: json['verificationReason'],
      profilePhoto: json['profilePhoto'],
      aadhaarNumber: json['aadhaarNumber'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'name': name,
        'email': email,
        'role': role,
        'isVerified': isVerified,
        'verificationStatus': verificationStatus,
        'verificationSelfie': verificationSelfie,
        'verificationIdCard': verificationIdCard,
        'verificationReason': verificationReason,
        'profilePhoto': profilePhoto,
        'aadhaarNumber': aadhaarNumber,
        'createdAt': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    String? id,
    String? phone,
    String? name,
    String? email,
    String? role,
    bool? isVerified,
    String? verificationStatus,
    String? verificationSelfie,
    String? verificationIdCard,
    String? verificationReason,
    String? profilePhoto,
    String? aadhaarNumber,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationSelfie: verificationSelfie ?? this.verificationSelfie,
      verificationIdCard: verificationIdCard ?? this.verificationIdCard,
      verificationReason: verificationReason ?? this.verificationReason,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
