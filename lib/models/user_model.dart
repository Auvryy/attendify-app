// lib/models/user_model.dart

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String role;
  final String barangayId;  // UUID string
  final String? barangayName;
  final String? profilePicture;
  final String? qrCode;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.role,
    required this.barangayId,
    this.barangayName,
    this.profilePicture,
    this.qrCode,
    this.isActive = true,
    required this.createdAt,
  });

  // Computed property for full name
  String get fullName => '$firstName $lastName'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'employee',
      barangayId: json['barangay_id']?.toString() ?? '',
      barangayName: json['barangay_name'] ?? json['barangays']?['name'],
      profilePicture: json['profile_picture'],
      qrCode: json['qr_code'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'role': role,
      'barangay_id': barangayId,
      'barangay_name': barangayName,
      'profile_picture': profilePicture,
      'qr_code': qrCode,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isEmployee => role == 'employee';

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? role,
    String? barangayId,
    String? barangayName,
    String? profilePicture,
    String? qrCode,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      barangayId: barangayId ?? this.barangayId,
      barangayName: barangayName ?? this.barangayName,
      profilePicture: profilePicture ?? this.profilePicture,
      qrCode: qrCode ?? this.qrCode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
