class UserModel {
  final String id;
  final String phone;
  final String name;
  final String? email;
  final String role;
  final bool isVerified;
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
    this.profilePhoto,
    this.aadhaarNumber,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      phone: json['phone'] ?? '',
      name: json['name'] ?? 'Guest',
      email: json['email'],
      role: json['role'] ?? 'user',
      isVerified: json['isVerified'] ?? false,
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
      profilePhoto: profilePhoto ?? this.profilePhoto,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
