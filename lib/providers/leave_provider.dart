// lib/providers/leave_provider.dart

import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/leave_request_model.dart';

class LeaveProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _errorMessage;
  List<LeaveRequestModel> _leaveHistory = [];
  List<LeaveRequestModel> _pendingRequests = []; // For admin
  int _totalRecords = 0;
  int _currentPage = 1;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<LeaveRequestModel> get leaveHistory => _leaveHistory;
  List<LeaveRequestModel> get pendingRequests => _pendingRequests;
  int get totalRecords => _totalRecords;
  bool get hasMore => _leaveHistory.length < _totalRecords;

  // ==================== FILE LEAVE REQUEST ====================

  Future<bool> fileLeaveRequest({
    required String leaveDate,
    required String reason,
    String? leaveType,
    String? attachmentUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.fileLeaveRequest(
        leaveDate: leaveDate,
        reason: reason,
        leaveType: leaveType,
        attachmentUrl: attachmentUrl,
      );
      
      if (response['error'] != null) {
        _errorMessage = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Add the new request to history
      if (response['leave_request'] != null) {
        _leaveHistory.insert(0, LeaveRequestModel.fromJson(response['leave_request']));
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

  // ==================== LEAVE HISTORY ====================

  Future<bool> fetchLeaveHistory({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _leaveHistory = [];
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getLeaveHistory(page: _currentPage);
      
      if (response['error'] != null) {
        _errorMessage = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final List<dynamic> records = response['leave_requests'] ?? [];
      final newRecords = records.map((r) => LeaveRequestModel.fromJson(r)).toList();
      
      if (refresh) {
        _leaveHistory = newRecords;
      } else {
        _leaveHistory.addAll(newRecords);
      }
      
      _totalRecords = response['total'] ?? _leaveHistory.length;
      _currentPage++;
      
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

  // ==================== LEAVE DETAIL ====================

  Future<LeaveRequestModel?> getLeaveDetail(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getLeaveDetail(id);
      
      if (response['error'] != null) {
        _errorMessage = response['error'];
        _isLoading = false;
        notifyListeners();
        return null;
      }
      
      _isLoading = false;
      notifyListeners();
      return LeaveRequestModel.fromJson(response['leave_request']);
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ==================== ADMIN: GET LEAVE REQUESTS ====================

  Future<bool> fetchAdminLeaveRequests({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getAdminLeaveRequests(status: status);
      
      if (response['error'] != null) {
        _errorMessage = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final List<dynamic> records = response['leave_requests'] ?? [];
      _pendingRequests = records.map((r) => LeaveRequestModel.fromJson(r)).toList();
      
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

  // ==================== ADMIN: REVIEW LEAVE REQUEST ====================

  Future<bool> reviewLeaveRequest({
    required String id,
    required String status, // 'approved' or 'declined'
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.reviewLeaveRequest(
        id: id,
        status: status,
      );
      
      if (response['error'] != null) {
        _errorMessage = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Remove from pending list on review
      _pendingRequests.removeWhere((r) => r.id == id);
      
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

  // Clear data
  void clear() {
    _leaveHistory = [];
    _pendingRequests = [];
    _totalRecords = 0;
    _currentPage = 1;
    notifyListeners();
  }
}
