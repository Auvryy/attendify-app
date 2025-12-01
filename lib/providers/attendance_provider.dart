// lib/providers/attendance_provider.dart

import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/attendance_model.dart';

class AttendanceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _errorMessage;
  List<AttendanceModel> _attendanceHistory = [];
  AttendanceModel? _todayAttendance;
  int _totalRecords = 0;
  int _currentPage = 1;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<AttendanceModel> get attendanceHistory => _attendanceHistory;
  AttendanceModel? get todayAttendance => _todayAttendance;
  int get totalRecords => _totalRecords;
  bool get hasMore => _attendanceHistory.length < _totalRecords;

  // ==================== SCAN QR ====================

  Future<Map<String, dynamic>?> scanAttendance(String qrCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.scanAttendance(qrCode);
      
      if (response['error'] != null) {
        _errorMessage = response['error'];
        _isLoading = false;
        notifyListeners();
        return null;
      }
      
      // Update today's attendance
      if (response['attendance'] != null) {
        _todayAttendance = AttendanceModel.fromJson(response['attendance']);
      }
      
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ==================== ATTENDANCE HISTORY ====================

  Future<bool> fetchAttendanceHistory({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _attendanceHistory = [];
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getAttendanceHistory(page: _currentPage);
      
      if (response['error'] != null) {
        _errorMessage = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final List<dynamic> records = response['attendance'] ?? [];
      final newRecords = records.map((r) => AttendanceModel.fromJson(r)).toList();
      
      if (refresh) {
        _attendanceHistory = newRecords;
      } else {
        _attendanceHistory.addAll(newRecords);
      }
      
      _totalRecords = response['total'] ?? _attendanceHistory.length;
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

  // ==================== TODAY'S ATTENDANCE ====================

  Future<bool> fetchTodayAttendance() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getTodayAttendance();
      
      if (response['error'] != null) {
        _errorMessage = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      if (response['attendance'] != null) {
        _todayAttendance = AttendanceModel.fromJson(response['attendance']);
      } else {
        _todayAttendance = null;
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

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear data
  void clear() {
    _attendanceHistory = [];
    _todayAttendance = null;
    _totalRecords = 0;
    _currentPage = 1;
    notifyListeners();
  }
}
