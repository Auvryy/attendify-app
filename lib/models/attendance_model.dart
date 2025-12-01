// lib/models/attendance_model.dart

class AttendanceModel {
  final String id;
  final String oderId;
  final DateTime date;
  final DateTime? timeIn;
  final DateTime? timeOut;
  final bool isLate;
  final String? notes;
  final String? userName;
  final DateTime createdAt;

  AttendanceModel({
    required this.id,
    required this.oderId,
    required this.date,
    this.timeIn,
    this.timeOut,
    this.isLate = false,
    this.notes,
    this.userName,
    required this.createdAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? '',
      oderId: json['user_id'] ?? '',
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
      timeIn: json['time_in'] != null 
          ? DateTime.parse(json['time_in']) 
          : null,
      timeOut: json['time_out'] != null 
          ? DateTime.parse(json['time_out']) 
          : null,
      isLate: json['is_late'] ?? false,
      notes: json['notes'],
      userName: json['users']?['full_name'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': oderId,
      'date': date.toIso8601String().split('T')[0],
      'time_in': timeIn?.toIso8601String(),
      'time_out': timeOut?.toIso8601String(),
      'is_late': isLate,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AttendanceStatus get status {
    if (timeIn == null && timeOut == null) {
      return AttendanceStatus.absent;
    }
    if (isLate) {
      return AttendanceStatus.late;
    }
    return AttendanceStatus.onTime;
  }

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
