// lib/core/constants/api_constants.dart

class ApiConstants {
  // Change this to your deployed backend URL in production
  // For local development with Android emulator, use 10.0.2.2:5000
  // For local development with iOS simulator or physical device on same network, use your computer's IP
  // static const String baseUrl = 'http://10.0.2.2:5000/api';
  
  // For physical device testing on same WiFi network, use your computer's local IP
  static const String baseUrl = 'http://192.168.1.2:5000/api';
  
  // Auth endpoints
  static const String registerSendOtp = '/auth/register/send-otp';
  static const String registerVerifyOtp = '/auth/register/verify-otp';
  static const String registerComplete = '/auth/register/complete';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/password/forgot';
  static const String verifyPasswordOtp = '/auth/password/verify-otp';
  static const String resetPassword = '/auth/password/reset';
  static const String logout = '/auth/logout';
  
  // User endpoints
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/profile';
  static const String settings = '/user/settings';
  static const String changeEmailSendOtp = '/user/email/change/send-otp';
  static const String changeEmailVerify = '/user/email/change/verify';
  static const String changePhoneSendOtp = '/user/phone/change/send-otp';
  static const String changePhoneVerify = '/user/phone/change/verify';
  static const String updatePhone = '/user/phone';
  static const String changePassword = '/user/password/change';
  
  // Attendance endpoints
  static const String attendanceScan = '/attendance/scan';
  static const String attendanceHistory = '/attendance/history';
  static const String attendanceToday = '/attendance/today';
  static const String attendanceEarlyOut = '/attendance/early-out';
  
  // Leave endpoints
  static const String leaveRequest = '/leave/request';
  static const String leaveHistory = '/leave/history';
  static const String leaveDetail = '/leave'; // + /{id}
  static const String leaveReview = '/leave'; // + /{id}/review
  
  // Admin endpoints
  static const String adminDashboard = '/admin/dashboard';
  static const String adminEmployees = '/admin/employees';
  static const String adminEmployee = '/admin/employee'; // + /{id}
  static const String adminLeaveRequests = '/admin/leave-requests';
  static const String adminAttendance = '/admin/attendance';
  
  // Notification endpoints
  static const String notifications = '/notifications';
  static const String notificationMarkRead = '/notifications'; // + /{id}/read
  static const String notificationsMarkAllRead = '/notifications/read-all';
  
  // General endpoints
  static const String health = '/health';
  static const String barangays = '/barangays';
}
