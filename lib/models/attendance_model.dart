// lib/models/attendance_model.dart

class AttendanceModel {
  final String id;
  final String userId;
  final DateTime date;
  final DateTime? timeIn;
  final DateTime? timeOut;
  final String status; // 'on_time', 'late', 'on_leave', 'absent'
  final String? notes;
  final String? userName;
  final String? employeeId;
  final DateTime createdAt;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.date,
    this.timeIn,
    this.timeOut,
    this.status = 'on_time',
    this.notes,
    this.userName,
    this.employeeId,
    required this.createdAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    // Parse time_in and time_out - they come as TIME format (HH:MM:SS)
    DateTime? parseTime(String? timeStr, String? dateStr) {
      if (timeStr == null) return null;
      try {
        // If it's just a time string, combine with date
        if (!timeStr.contains('T') && dateStr != null) {
          return DateTime.parse('${dateStr}T$timeStr');
        }
        return DateTime.parse(timeStr);
      } catch (e) {
        return null;
      }
    }
    
    final dateStr = json['date']?.toString();
    
    return AttendanceModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      date: dateStr != null 
          ? DateTime.parse(dateStr) 
          : DateTime.now(),
      timeIn: parseTime(json['time_in']?.toString(), dateStr),
      timeOut: parseTime(json['time_out']?.toString(), dateStr),
      status: json['status'] ?? 'on_time',
      notes: json['notes'],
      userName: json['users'] != null 
          ? '${json['users']['first_name'] ?? ''} ${json['users']['last_name'] ?? ''}'.trim()
          : null,
      employeeId: json['users']?['employee_id'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0],
      'time_in': timeIn?.toIso8601String(),
      'time_out': timeOut?.toIso8601String(),
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AttendanceStatus get statusEnum {
    switch (status) {
      case 'late':
        return AttendanceStatus.late;
      case 'on_leave':
        return AttendanceStatus.onLeave;
      case 'absent':
        return AttendanceStatus.absent;
      case 'on_time':
      default:
        return AttendanceStatus.onTime;
    }
  }
  
  bool get isLate => status == 'late';

  String get formattedTimeIn {
    if (timeIn == null) return '--';
    final hour = timeIn!.hour;
    final minute = timeIn!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:$minute $period';
  }

  String get formattedTimeOut {
    if (timeOut == null) return '--';
    final hour = timeOut!.hour;
    final minute = timeOut!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:$minute $period';
  }
}

enum AttendanceStatus {
  onTime,
  late,
  absent,
  onLeave,
}
