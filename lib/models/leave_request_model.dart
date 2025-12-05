// lib/models/leave_request_model.dart

class LeaveRequestModel {
  final String id;
  final String userId;
  final DateTime leaveDate;
  final String leaveType;
  final String reason;
  final String? attachmentUrl;
  final String status; // pending, approved, declined
  final String? adminNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? userName;
  final String? userFirstName;
  final String? userLastName;
  final String? userProfileImageUrl;
  final DateTime createdAt;

  LeaveRequestModel({
    required this.id,
    required this.userId,
    required this.leaveDate,
    this.leaveType = 'other',
    required this.reason,
    this.attachmentUrl,
    required this.status,
    this.adminNotes,
    this.reviewedBy,
    this.reviewedAt,
    this.userName,
    this.userFirstName,
    this.userLastName,
    this.userProfileImageUrl,
    required this.createdAt,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    // Handle user name from nested users object
    String? fullName;
    String? firstName;
    String? lastName;
    String? profileImageUrl;
    
    if (json['users'] != null) {
      firstName = json['users']['first_name'];
      lastName = json['users']['last_name'];
      fullName = '$firstName $lastName'.trim();
      profileImageUrl = json['users']['profile_image_url'];
    }
    
    return LeaveRequestModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      leaveDate: json['leave_date'] != null 
          ? DateTime.parse(json['leave_date']) 
          : DateTime.now(),
      leaveType: json['leave_type'] ?? 'other',
      reason: json['reason'] ?? '',
      attachmentUrl: json['attachment_url'],
      status: json['status'] ?? 'pending',
      adminNotes: json['admin_notes'],
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null 
          ? DateTime.parse(json['reviewed_at']) 
          : null,
      userName: fullName ?? json['user_name'],
      userFirstName: firstName,
      userLastName: lastName,
      userProfileImageUrl: profileImageUrl,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'leave_date': leaveDate.toIso8601String().split('T')[0],
      'leave_type': leaveType,
      'reason': reason,
      'attachment_url': attachmentUrl,
      'status': status,
      'admin_notes': adminNotes,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isDeclined => status == 'declined';
  
  String get leaveTypeName {
    switch (leaveType) {
      case 'sick': return 'Sick Leave';
      case 'vacation': return 'Vacation Leave';
      case 'emergency': return 'Emergency Leave';
      case 'personal': return 'Personal Leave';
      default: return 'Other';
    }
  }

  String get formattedLeaveDate {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[leaveDate.month - 1]} ${leaveDate.day}, ${leaveDate.year}';
  }

  LeaveRequestModel copyWith({
    String? id,
    String? userId,
    DateTime? leaveDate,
    String? leaveType,
    String? reason,
    String? attachmentUrl,
    String? status,
    String? adminNotes,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? userName,
    String? userFirstName,
    String? userLastName,
    String? userProfileImageUrl,
    DateTime? createdAt,
  }) {
    return LeaveRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      leaveDate: leaveDate ?? this.leaveDate,
      leaveType: leaveType ?? this.leaveType,
      reason: reason ?? this.reason,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      userName: userName ?? this.userName,
      userFirstName: userFirstName ?? this.userFirstName,
      userLastName: userLastName ?? this.userLastName,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
