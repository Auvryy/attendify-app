// lib/models/registration_request_model.dart

class RegistrationRequestModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String phone;
  final String barangayId;
  final String? barangayName;
  final String? fullAddress;
  final String status; // pending, approved, rejected
  final String? rejectionReason;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RegistrationRequestModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.phone,
    required this.barangayId,
    this.barangayName,
    this.fullAddress,
    required this.status,
    this.rejectionReason,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory RegistrationRequestModel.fromJson(Map<String, dynamic> json) {
    // Handle nested barangay data
    String? barangayName;
    if (json['barangays'] != null && json['barangays'] is Map) {
      barangayName = json['barangays']['name'];
    }
    
    return RegistrationRequestModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      middleName: json['middle_name'],
      phone: json['phone'] ?? '',
      barangayId: json['barangay_id']?.toString() ?? '',
      barangayName: barangayName,
      fullAddress: json['full_address'],
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejection_reason'],
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null 
          ? DateTime.tryParse(json['reviewed_at']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  RegistrationRequestModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? middleName,
    String? phone,
    String? barangayId,
    String? barangayName,
    String? fullAddress,
    String? status,
    String? rejectionReason,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RegistrationRequestModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      phone: phone ?? this.phone,
      barangayId: barangayId ?? this.barangayId,
      barangayName: barangayName ?? this.barangayName,
      fullAddress: fullAddress ?? this.fullAddress,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
