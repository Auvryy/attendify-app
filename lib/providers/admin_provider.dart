// lib/providers/admin_provider.dart

import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/leave_request_model.dart';
import '../models/registration_request_model.dart';

class AdminProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardData;
  List<UserModel> _employees = [];
  List<AttendanceModel> _attendanceRecords = [];
  List<LeaveRequestModel> _leaveRequests = [];
  List<RegistrationRequestModel> _pendingRegistrations = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get dashboardData => _dashboardData;
  List<UserModel> get employees => _employees;
  List<AttendanceModel> get attendanceRecords => _attendanceRecords;
  List<LeaveRequestModel> get leaveRequests => _leaveRequests;
  List<RegistrationRequestModel> get pendingRegistrations =>
      _pendingRegistrations;

  // Dashboard stats
  int get totalEmployees => _dashboardData?['total_employees'] ?? 0;
  int get presentToday => _dashboardData?['present_today'] ?? 0;
  int get lateToday => _dashboardData?['late_today'] ?? 0;
  int get onLeaveToday => _dashboardData?['on_leave_today'] ?? 0;
  int get pendingLeaves => _dashboardData?['pending_leave_requests'] ?? 0;
  int get pendingRegistrationsCount =>
      _dashboardData?['pending_registrations'] ?? 0;

  // ==================== DASHBOARD ====================

  Future<bool> fetchDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getAdminDashboard();

      if (response['error'] != null) {
        _errorMessage = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _dashboardData = response;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== EMPLOYEES ====================

  Future<bool> fetchEmployees({int? barangayId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getAdminEmployees(
        barangayId: barangayId,
      );

      print('[ADMIN PROVIDER] fetchEmployees response: $response');

      if (response['error'] != null) {
        _errorMessage = response['error'];
        print('[ADMIN PROVIDER] fetchEmployees error: $_errorMessage');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final List<dynamic> records = response['employees'] ?? [];
      print('[ADMIN PROVIDER] fetchEmployees records count: ${records.length}');
      _employees = records.map((r) => UserModel.fromJson(r)).toList();
      print(
        '[ADMIN PROVIDER] fetchEmployees parsed employees: ${_employees.length}',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('[ADMIN PROVIDER] fetchEmployees exception: $e');
      _errorMessage = 'Network error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<UserModel?> getEmployeeDetail(String id) async {
    // Don't call notifyListeners here to avoid setState during build
    // This method returns data directly, caller handles its own state

    try {
      final response = await _apiService.getAdminEmployee(id);

      if (response['error'] != null) {
        _errorMessage = response['error'];
        return null;
      }

      return UserModel.fromJson(response['employee']);
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      return null;
    }
  }

  Future<bool> updateEmployeeStatus(String id, bool isActive) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.updateEmployeeStatus(id, isActive);

      if (response['error'] != null) {
        _errorMessage = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Update the employee in the list
      final index = _employees.indexWhere((e) => e.id == id);
      if (index != -1) {
        _employees[index] = _employees[index].copyWith(isActive: isActive);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmployee({
    required String id,
    String? firstName,
    String? lastName,
    String? middleName,
    String? position,
    String? fullAddress,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.updateEmployee(
        id: id,
        firstName: firstName,
        lastName: lastName,
        middleName: middleName,
        position: position,
        fullAddress: fullAddress,
        phone: phone,
      );

      if (response['error'] != null) {
        _errorMessage = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Refetch employee to get updated data
      await fetchEmployees();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== ATTENDANCE ====================

  Future<bool> fetchAttendance({String? date, int? barangayId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getAdminAttendance(
        date: date,
        barangayId: barangayId,
      );

      if (response['error'] != null) {
        _errorMessage = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final List<dynamic> records = response['attendance'] ?? [];
      _attendanceRecords = records
          .map((r) => AttendanceModel.fromJson(r))
          .toList();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==================== LEAVE REQUESTS ====================

  Future<bool> fetchLeaveRequests({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getAdminLeaveRequests(status: status);

      print('[ADMIN PROVIDER] fetchLeaveRequests response: $response');

      if (response['error'] != null) {
        _errorMessage = response['error'];
        print('[ADMIN PROVIDER] fetchLeaveRequests error: $_errorMessage');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final List<dynamic> records = response['leave_requests'] ?? [];
      print(
        '[ADMIN PROVIDER] fetchLeaveRequests records count: ${records.length}',
      );
      _leaveRequests = records
          .map((r) => LeaveRequestModel.fromJson(r))
          .toList();
      print(
        '[ADMIN PROVIDER] fetchLeaveRequests parsed: ${_leaveRequests.length}',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('[ADMIN PROVIDER] fetchLeaveRequests exception: $e');
      _errorMessage = 'Network error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reviewLeaveRequest({
    required String id,
    required String status, // 'approved' or 'declined'
    String? adminNotes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.reviewLeaveRequest(
        id: id,
        status: status,
        adminNotes: adminNotes,
      );

      if (response['error'] != null) {
        _errorMessage = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Remove the reviewed leave request from the list
      _leaveRequests.removeWhere((r) => r.id == id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear data
  void clear() {
    _dashboardData = null;
    _employees = [];
    _attendanceRecords = [];
    _leaveRequests = [];
    _pendingRegistrations = [];
    notifyListeners();
  }

  // ==================== PENDING REGISTRATIONS ====================

  Future<bool> fetchPendingRegistrations({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getPendingRegistrations(
        status: status,
      );

      print('[ADMIN PROVIDER] Pending registrations response: $response');

      if (response['error'] != null) {
        _errorMessage = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final List<dynamic> records = response['registrations'] ?? [];
      print('[ADMIN PROVIDER] Records count: ${records.length}');
      _pendingRegistrations = records
          .map((r) => RegistrationRequestModel.fromJson(r))
          .toList();
      print(
        '[ADMIN PROVIDER] Parsed registrations: ${_pendingRegistrations.length}',
      );
      for (var reg in _pendingRegistrations) {
        print(
          '[ADMIN PROVIDER] Registration: ${reg.email}, status: ${reg.status}, isPending: ${reg.isPending}',
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('[ADMIN PROVIDER] Error fetching pending: $e');
      _errorMessage = 'Network error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> approveRegistration(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.approveRegistration(id);

      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Failed to approve registration';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Remove from pending list
      _pendingRegistrations.removeWhere((r) => r.id == id);

      // Update dashboard count
      if (_dashboardData != null) {
        _dashboardData!['pending_registrations'] =
            (_dashboardData!['pending_registrations'] ?? 1) - 1;
        _dashboardData!['total_employees'] =
            (_dashboardData!['total_employees'] ?? 0) + 1;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectRegistration(String id, {String? reason}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.rejectRegistration(id, reason: reason);

      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Failed to reject registration';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Remove from pending list
      _pendingRegistrations.removeWhere((r) => r.id == id);

      // Update dashboard count
      if (_dashboardData != null) {
        _dashboardData!['pending_registrations'] =
            (_dashboardData!['pending_registrations'] ?? 1) - 1;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
