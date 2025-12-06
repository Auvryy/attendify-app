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
    required String firstName,
    required String lastName,
    required String phone,
    required String barangayId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerComplete}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
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
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      
      print('[LOGIN API] Response status: ${response.statusCode}');
      print('[LOGIN API] Response body: ${response.body}');
      
      final body = jsonDecode(response.body);
      print('[LOGIN API] Parsed success: ${body['success']}');
      print('[LOGIN API] Parsed message: ${body['message']}');
      // Backend returns {success, data: {access_token, refresh_token, user}}
      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'];
        if (data != null && data['access_token'] != null) {
          await _saveTokens(data['access_token'], data['refresh_token']);
        }
      }
      return body;
    } catch (e) {
      print('Login error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
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

  Future<Map<String, dynamic>> resetPassword(String email, String newPassword) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.resetPassword}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'new_password': newPassword}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> logout() async {
    // Save current token before clearing
    final token = _accessToken;
    
    // Clear tokens first to prevent any retries with invalid token
    await clearTokens();
    
    // Only call logout API if we had a token
    if (token != null && token.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logout}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        return jsonDecode(response.body);
      } catch (e) {
        // Ignore errors - we've already cleared local tokens
        return {'success': true, 'message': 'Logged out locally'};
      }
    }
    
    return {'success': true, 'message': 'Logged out'};
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
    String? middleName,
    String? phone,
    String? profileImageUrl,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateProfile}'),
      headers: _headers,
      body: jsonEncode({
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (middleName != null) 'middle_name': middleName,
        if (phone != null) 'phone': phone,
        if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      }),
    );
    return jsonDecode(response.body);
  }

  // Direct phone update without OTP
  Future<Map<String, dynamic>> updatePhone(String newPhone) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updatePhone}'),
      headers: _headers,
      body: jsonEncode({'phone': newPhone}),
    );
    return jsonDecode(response.body);
  }

  // ==================== FILE UPLOAD ENDPOINTS ====================

  Future<Map<String, dynamic>> uploadFile(String filePath, String folder) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/upload'),
      );
      
      request.headers.addAll({
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      });
      
      request.fields['folder'] = folder;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Upload failed: $e'};
    }
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

  Future<Map<String, dynamic>> scanAttendanceFromImage(String base64Image) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.attendanceScan}'),
      headers: _headers,
      body: jsonEncode({'image': base64Image}),
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

  Future<Map<String, dynamic>> submitEarlyOut(String attendanceId, String reason) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.attendanceEarlyOut}'),
      headers: _headers,
      body: jsonEncode({
        'attendance_id': attendanceId,
        'reason': reason,
      }),
    );
    return jsonDecode(response.body);
  }

  // ==================== LEAVE ENDPOINTS ====================

  Future<Map<String, dynamic>> fileLeaveRequest({
    required String leaveDate,
    required String reason,
    String? leaveType,
    String? attachmentUrl,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.leaveRequest}'),
      headers: _headers,
      body: jsonEncode({
        'leave_date': leaveDate,
        'reason': reason,
        if (leaveType != null) 'leave_type': leaveType,
        if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      }),
    );
    final body = jsonDecode(response.body);
    if (body['success'] == true) {
      return body['data'] ?? {'success': true};
    }
    return {'error': body['message'] ?? 'Failed to submit leave request'};
  }

  Future<Map<String, dynamic>> getLeaveHistory({int page = 1, int limit = 20}) async {
    // Use correct backend endpoint: /api/leave/my-requests
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/leave/my-requests'),
      headers: _headers,
    );
    final body = jsonDecode(response.body);
    if (body['success'] == true && body['data'] != null) {
      return body['data'];
    }
    return {'error': body['message'] ?? 'Failed to fetch leave history'};
  }

  Future<Map<String, dynamic>> getLeaveDetail(String id) async {
    // Use correct backend endpoint: /api/leave/request/<id>
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/leave/request/$id'),
      headers: _headers,
    );
    final body = jsonDecode(response.body);
    if (body['success'] == true && body['data'] != null) {
      return body['data'];
    }
    return {'error': body['message'] ?? 'Failed to fetch leave detail'};
  }

  // ==================== ADMIN ENDPOINTS ====================

  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminDashboard}'),
      headers: _headers,
    );
    final body = jsonDecode(response.body);
    // Backend returns {success, data: {...dashboard stats}}
    if (body['success'] == true && body['data'] != null) {
      return body['data'];
    }
    return {'error': body['message'] ?? 'Failed to fetch dashboard'};
  }

  Future<Map<String, dynamic>> getAdminEmployees({int? barangayId}) async {
    String url = '${ApiConstants.baseUrl}${ApiConstants.adminEmployees}';
    if (barangayId != null) {
      url += '?barangay_id=$barangayId';
    }
    print('[API] getAdminEmployees url: $url');
    print('[API] getAdminEmployees headers: $_headers');
    
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    
    print('[API] getAdminEmployees status: ${response.statusCode}');
    print('[API] getAdminEmployees body: ${response.body}');
    
    final body = jsonDecode(response.body);
    // Backend returns {success, data: {employees: [...]}}
    if (body['success'] == true && body['data'] != null) {
      return body['data'];
    }
    return {'error': body['message'] ?? 'Failed to fetch employees'};
  }

  Future<Map<String, dynamic>> getAdminEmployee(String id) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminEmployees}/$id'),
      headers: _headers,
    );
    final body = jsonDecode(response.body);
    // Backend returns {success, data: {employee: {...}}}
    if (body['success'] == true && body['data'] != null) {
      return body['data'];
    }
    return {'error': body['message'] ?? 'Failed to fetch employee'};
  }

  Future<Map<String, dynamic>> updateEmployeeStatus(String id, bool isActive) async {
    final endpoint = isActive ? 'activate' : 'deactivate';
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminEmployees}/$id/$endpoint'),
      headers: _headers,
    );
    final body = jsonDecode(response.body);
    if (body['success'] == true) {
      return body['data'] ?? {'success': true};
    }
    return {'error': body['message'] ?? 'Failed to update employee status'};
  }

  Future<Map<String, dynamic>> updateEmployee({
    required String id,
    String? firstName,
    String? lastName,
    String? middleName,
    String? position,
    String? fullAddress,
    String? phone,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminEmployees}/$id'),
      headers: _headers,
      body: jsonEncode({
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (middleName != null) 'middle_name': middleName,
        if (position != null) 'position': position,
        if (fullAddress != null) 'full_address': fullAddress,
        if (phone != null) 'phone': phone,
      }),
    );
    final body = jsonDecode(response.body);
    if (body['success'] == true) {
      return body['data'] ?? {'success': true};
    }
    return {'error': body['message'] ?? 'Failed to update employee'};
  }

  Future<Map<String, dynamic>> getAdminLeaveRequests({String? status}) async {
    // Use correct backend endpoint: /api/leave/all
    String url = '${ApiConstants.baseUrl}/leave/all';
    if (status != null) {
      url += '?status=$status';
    }
    print('[API] getAdminLeaveRequests url: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    
    print('[API] getAdminLeaveRequests status: ${response.statusCode}');
    print('[API] getAdminLeaveRequests body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
    
    // Check if response is HTML (error page)
    if (response.body.startsWith('<!') || response.body.startsWith('<html')) {
      return {'error': 'Server returned HTML instead of JSON. Check if backend is running.'};
    }
    
    final body = jsonDecode(response.body);
    // Backend returns {success, data: {leave_requests: [...]}}
    if (body['success'] == true && body['data'] != null) {
      return body['data'];
    }
    return {'error': body['message'] ?? 'Failed to fetch leave requests'};
  }

  Future<Map<String, dynamic>> reviewLeaveRequest({
    required String id,
    required String status,
    String? adminNotes,
  }) async {
    // Use correct backend endpoint: PUT /api/leave/review/<id>
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/leave/review/$id'),
      headers: _headers,
      body: jsonEncode({
        'status': status, // 'approved' or 'declined'
        if (adminNotes != null) 'admin_notes': adminNotes,
      }),
    );
    final body = jsonDecode(response.body);
    if (body['success'] == true) {
      return body['data'] ?? {'success': true};
    }
    return {'error': body['message'] ?? 'Failed to review leave request'};
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
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}?limit=$limit'),
      headers: _headers,
    );
    print('[API] getNotifications response: ${response.body}');
    final body = jsonDecode(response.body);
    // Backend returns {success, data: {notifications: [...]}}
    if (body['success'] == true && body['data'] != null) {
      return body['data'];
    }
    return {'error': body['message'] ?? 'Failed to fetch notifications'};
  }

  Future<Map<String, dynamic>> markNotificationRead(String id) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}/$id/read'),
      headers: _headers,
    );
    final body = jsonDecode(response.body);
    if (body['success'] == true) {
      return body['data'] ?? {'success': true};
    }
    return {'error': body['message'] ?? 'Failed to mark notification as read'};
  }

  Future<Map<String, dynamic>> markAllNotificationsRead() async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notificationsMarkAllRead}'),
      headers: _headers,
    );
    final body = jsonDecode(response.body);
    if (body['success'] == true) {
      return body['data'] ?? {'success': true};
    }
    return {'error': body['message'] ?? 'Failed to mark all notifications as read'};
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

  // ==================== PENDING REGISTRATIONS ENDPOINTS ====================

  Future<Map<String, dynamic>> getPendingRegistrations({String? status}) async {
    String url = '${ApiConstants.baseUrl}/admin/pending-registrations';
    if (status != null) {
      url += '?status=$status';
    }
    print('[API] Fetching pending registrations from: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    print('[API] Response status: ${response.statusCode}');
    print('[API] Response body: ${response.body}');
    final body = jsonDecode(response.body);
    if (body['success'] == true && body['data'] != null) {
      final registrations = body['data']['registrations'] ?? [];
      print('[API] Found ${registrations.length} registrations');
      return {'registrations': registrations};
    }
    print('[API] Error or no data: ${body['message']}');
    return {'error': body['message'] ?? 'Failed to fetch registrations'};
  }

  Future<Map<String, dynamic>> approveRegistration(String id) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/pending-registrations/$id/approve'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> rejectRegistration(String id, {String? reason}) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/pending-registrations/$id/reject'),
      headers: _headers,
      body: jsonEncode({
        if (reason != null) 'reason': reason,
      }),
    );
    return jsonDecode(response.body);
  }
}
