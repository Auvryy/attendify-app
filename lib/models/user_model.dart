// lib/models/user_model.dart

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String middleName;
  final String phone;
  final String role;
  final String? employeeId;
  final String barangayId;  // UUID string
  final String? barangayName;
  final String? position;
  final String? profileImageUrl;
  final String? qrCode;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.middleName = '',
    required this.phone,
    required this.role,
    this.employeeId,
    required this.barangayId,
    this.barangayName,
    this.position,
    this.profileImageUrl,
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
      middleName: json['middle_name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'employee',
      employeeId: json['employee_id'],
      barangayId: json['barangay_id']?.toString() ?? '',
      barangayName: json['barangay_name'] ?? json['barangays']?['name'] ?? json['barangay']?['name'],
      position: json['position'],
      profileImageUrl: json['profile_image_url'],
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
      'middle_name': middleName,
      'phone': phone,
      'role': role,
      'employee_id': employeeId,
      'barangay_id': barangayId,
      'barangay_name': barangayName,
      'position': position,
      'profile_image_url': profileImageUrl,
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
    String? middleName,
    String? phone,
    String? role,
    String? employeeId,
    String? barangayId,
    String? barangayName,
    String? position,
    String? profileImageUrl,
    String? qrCode,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      employeeId: employeeId ?? this.employeeId,
      barangayId: barangayId ?? this.barangayId,
      barangayName: barangayName ?? this.barangayName,
      position: position ?? this.position,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      qrCode: qrCode ?? this.qrCode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  // Computed property for formatted name (Last, First Middle)
  String get formattedName {
    if (middleName.isNotEmpty) {
      return '$lastName, $firstName $middleName';
    }
    return '$lastName, $firstName';
  }
}
