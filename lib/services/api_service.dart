// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _accessToken;
  String? _refreshToken;

  // Initialize tokens from storage
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  // Save tokens to storage
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  // Clear tokens from storage
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  bool get isLoggedIn => _accessToken != null;

  // Headers with auth token
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  // Generic API call handler
  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final body = jsonDecode(response.body);
    
    if (response.statusCode == 401 && _refreshToken != null) {
      // Try to refresh token
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        // Retry would need to be handled by caller
        return {'error': 'token_refreshed', 'retry': true};
      }
    }
    
    return body;
  }

  Future<bool> _refreshAccessToken() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshToken}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _refreshToken}),
      );
      
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        await _saveTokens(body['access_token'], body['refresh_token']);
        return true;
      }
    } catch (e) {
      // Token refresh failed
    }
    await clearTokens();
    return false;
  }

  // ==================== AUTH ENDPOINTS ====================

  Future<Map<String, dynamic>> registerSendOtp(String email) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerSendOtp}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> registerVerifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerVerifyOtp}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp_code': otp}),  // Backend expects 'otp_code'
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> registerComplete({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String barangayId,  // Changed to String for UUID
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerComplete}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'barangay_id': barangayId,
      }),
    );
    
    final body = jsonDecode(response.body);
    // Backend returns {success, data: {access_token, refresh_token, user}}
    if (response.statusCode == 201 && body['success'] == true) {
      final data = body['data'];
      if (data != null && data['access_token'] != null) {
        await _saveTokens(data['access_token'], data['refresh_token']);
      }
    }
    return body;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    final body = jsonDecode(response.body);
    // Backend returns {success, data: {access_token, refresh_token, user}}
    if (response.statusCode == 200 && body['success'] == true) {
      final data = body['data'];
      if (data != null && data['access_token'] != null) {
        await _saveTokens(data['access_token'], data['refresh_token']);
      }
    }
    return body;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.forgotPassword}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> verifyPasswordOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyPasswordOtp}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp_code': otp}),  // Backend expects 'otp_code'
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> resetPassword(String resetToken, String newPassword) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.resetPassword}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'reset_token': resetToken, 'new_password': newPassword}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> logout() async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logout}'),
      headers: _headers,
    );
    await clearTokens();
    return jsonDecode(response.body);
  }

  // ==================== USER ENDPOINTS ====================

  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profile}'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateProfile}'),
      headers: _headers,
      body: jsonEncode({
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (phone != null) 'phone': phone,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getSettings() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.settings}'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.settings}'),
      headers: _headers,
      body: jsonEncode(settings),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> changeEmailSendOtp(String newEmail) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.changeEmailSendOtp}'),
      headers: _headers,
      body: jsonEncode({'new_email': newEmail}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> changeEmailVerify(String otp, String newEmail) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.changeEmailVerify}'),
      headers: _headers,
      body: jsonEncode({'otp': otp, 'new_email': newEmail}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> changePhoneSendOtp(String newPhone) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.changePhoneSendOtp}'),
      headers: _headers,
      body: jsonEncode({'new_phone': newPhone}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> changePhoneVerify(String otp, String newPhone) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.changePhoneVerify}'),
      headers: _headers,
      body: jsonEncode({'otp': otp, 'new_phone': newPhone}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.changePassword}'),
      headers: _headers,
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    return jsonDecode(response.body);
  }

  // ==================== ATTENDANCE ENDPOINTS ====================

  Future<Map<String, dynamic>> scanAttendance(String qrCode) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.attendanceScan}'),
      headers: _headers,
      body: jsonEncode({'qr_code': qrCode}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getAttendanceHistory({int page = 1, int limit = 20}) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.attendanceHistory}?page=$page&limit=$limit'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getTodayAttendance() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.attendanceToday}'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // ==================== LEAVE ENDPOINTS ====================

  Future<Map<String, dynamic>> fileLeaveRequest({
    required String leaveDate,
    required String reason,
    String? attachmentUrl,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.leaveRequest}'),
      headers: _headers,
      body: jsonEncode({
        'leave_date': leaveDate,
        'reason': reason,
        if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getLeaveHistory({int page = 1, int limit = 20}) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.leaveHistory}?page=$page&limit=$limit'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getLeaveDetail(String id) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.leaveDetail}/$id'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // ==================== ADMIN ENDPOINTS ====================

  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminDashboard}'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getAdminEmployees({int? barangayId}) async {
    String url = '${ApiConstants.baseUrl}${ApiConstants.adminEmployees}';
    if (barangayId != null) {
      url += '?barangay_id=$barangayId';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getAdminEmployee(String id) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminEmployee}/$id'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateEmployeeStatus(String id, bool isActive) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminEmployee}/$id/status'),
      headers: _headers,
      body: jsonEncode({'is_active': isActive}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getAdminLeaveRequests({String? status}) async {
    String url = '${ApiConstants.baseUrl}${ApiConstants.adminLeaveRequests}';
    if (status != null) {
      url += '?status=$status';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> reviewLeaveRequest({
    required String id,
    required String action,
    String? adminNotes,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.leaveReview}/$id/review'),
      headers: _headers,
      body: jsonEncode({
        'action': action,
        if (adminNotes != null) 'admin_notes': adminNotes,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getAdminAttendance({
    String? date,
    int? barangayId,
  }) async {
    String url = '${ApiConstants.baseUrl}${ApiConstants.adminAttendance}';
    List<String> params = [];
    if (date != null) params.add('date=$date');
    if (barangayId != null) params.add('barangay_id=$barangayId');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // ==================== NOTIFICATION ENDPOINTS ====================

  Future<Map<String, dynamic>> getNotifications({int page = 1, int limit = 20}) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}?page=$page&limit=$limit'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> markNotificationRead(String id) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notificationMarkRead}/$id/read'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> markAllNotificationsRead() async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notificationsMarkAllRead}'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // ==================== GENERAL ENDPOINTS ====================

  Future<Map<String, dynamic>> healthCheck() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.health}'),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getBarangays() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.barangays}'),
    );
    final body = jsonDecode(response.body);
    // Backend returns {success, message, data: {barangays: [...]}}
    // Extract barangays from nested structure
    if (body['success'] == true && body['data'] != null) {
      return {
        'barangays': body['data']['barangays'] ?? [],
      };
    }
    return {'error': body['message'] ?? 'Failed to fetch barangays'};
  }
}
