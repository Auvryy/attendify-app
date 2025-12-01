// lib/models/leave_request_model.dart

class LeaveRequestModel {
  final String id;
  final String userId;
  final DateTime leaveDate;
  final String reason;
  final String? attachmentUrl;
  final String status; // pending, approved, declined
  final String? adminNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? userName;
  final DateTime createdAt;

  LeaveRequestModel({
    required this.id,
    required this.userId,
    required this.leaveDate,
    required this.reason,
    this.attachmentUrl,
    required this.status,
    this.adminNotes,
    this.reviewedBy,
    this.reviewedAt,
    this.userName,
    required this.createdAt,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      leaveDate: json['leave_date'] != null 
          ? DateTime.parse(json['leave_date']) 
          : DateTime.now(),
      reason: json['reason'] ?? '',
      attachmentUrl: json['attachment_url'],
      status: json['status'] ?? 'pending',
      adminNotes: json['admin_notes'],
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null 
          ? DateTime.parse(json['reviewed_at']) 
          : null,
      userName: json['users']?['full_name'],
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
    String? reason,
    String? attachmentUrl,
    String? status,
    String? adminNotes,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? userName,
    DateTime? createdAt,
  }) {
    return LeaveRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      leaveDate: leaveDate ?? this.leaveDate,
      reason: reason ?? this.reason,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      userName: userName ?? this.userName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
