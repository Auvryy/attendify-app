// lib/providers/user_provider.dart

import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/barangay_model.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;
  Map<String, dynamic>? _settings;
  List<BarangayModel> _barangays = [];
  String? _otpForDev; // For development mode

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
  Map<String, dynamic>? get settings => _settings;
  List<BarangayModel> get barangays => _barangays;
  String? get otpForDev => _otpForDev;

  // ==================== PROFILE ====================

  Future<bool> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getProfile();
      
      // Backend returns {success, data: {user}}
      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Failed to fetch profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final data = response['data'];
      if (data != null && data['user'] != null) {
        _user = UserModel.fromJson(data['user']);
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

  Future<UserModel?> getProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getProfile();
      
      // Backend returns {success, data: {user}}
      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Failed to fetch profile';
        _isLoading = false;
        notifyListeners();
        return null;
      }
      
      final data = response['data'];
      if (data != null && data['user'] != null) {
        _user = UserModel.fromJson(data['user']);
      }
      _isLoading = false;
      notifyListeners();
      return _user;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<UserModel?> updateProfile({
    String? firstName,
    String? lastName,
    String? middleName,
    String? phone,
    String? profileImageUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        middleName: middleName,
        phone: phone,
        profileImageUrl: profileImageUrl,
      );
      
      // Backend returns {success, data: {user}}
      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Failed to update profile';
        _isLoading = false;
        notifyListeners();
        return null;
      }
      
      final data = response['data'];
      if (data != null && data['user'] != null) {
        _user = UserModel.fromJson(data['user']);
      }
      _isLoading = false;
      notifyListeners();
      return _user;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Direct phone update without OTP
  Future<bool> updatePhone(String newPhone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.updatePhone(newPhone);
      
      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Failed to update phone';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Update local user with new phone
      if (_user != null) {
        _user = _user!.copyWith(phone: newPhone);
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

  // Upload file
  Future<String?> uploadFile(String filePath, String folder) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.uploadFile(filePath, folder);
      
      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Failed to upload file';
        _isLoading = false;
        notifyListeners();
        return null;
      }
      
      _isLoading = false;
      notifyListeners();
      return response['data']?['url'];
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Set user (for after login/register)
  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  // Clear user (for logout)
  void clearUser() {
    _user = null;
    notifyListeners();
  }

  // ==================== SETTINGS ====================

  Future<bool> getSettings() async {
    _errorMessage = null;
    // Don't set loading to avoid setState during build issues

    try {
      final response = await _apiService.getSettings();
      
      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Failed to get settings';
        notifyListeners();
        return false;
      }
      
      // Backend returns {success, data: {...settings}}
      _settings = response['data'];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSettings(Map<String, dynamic> newSettings) async {
    _errorMessage = null;

    try {
      final response = await _apiService.updateSettings(newSettings);
      
      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Failed to update settings';
        notifyListeners();
        return false;
      }
      
      // Backend returns {success, data: {settings: {...}}}
      if (response['data'] != null && response['data']['settings'] != null) {
        _settings = response['data']['settings'];
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // ==================== EMAIL CHANGE ====================

  Future<bool> changeEmailSendOtp(String newEmail) async {
    _isLoading = true;
    _errorMessage = null;
    _otpForDev = null;
    notifyListeners();

    try {
      final response = await _apiService.changeEmailSendOtp(newEmail);
      
      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Failed to send OTP';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Development mode - OTP might be returned
      if (response['otp'] != null) {
        _otpForDev = response['otp'];
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

  Future<bool> changeEmailVerify(String newEmail, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.changeEmailVerify(otp, newEmail);
      
      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Invalid verification code';
        _isLoading = false;
        notifyListeners();
        return false;
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

  // ==================== PHONE CHANGE ====================

  Future<bool> changePhoneSendOtp(String newPhone) async {
    _isLoading = true;
    _errorMessage = null;
    _otpForDev = null;
    notifyListeners();

    try {
      final response = await _apiService.changePhoneSendOtp(newPhone);
      
      if (response['error'] != null) {
        _errorMessage = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Development mode - OTP might be returned
      if (response['otp'] != null) {
        _otpForDev = response['otp'];
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

  Future<bool> changePhoneVerify(String otp, String newPhone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.changePhoneVerify(otp, newPhone);
      
      if (response['error'] != null) {
        _errorMessage = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
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

  // ==================== PASSWORD CHANGE ====================

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.changePassword(currentPassword, newPassword);
      
      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Failed to change password';
        _isLoading = false;
        notifyListeners();
        return false;
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

  // ==================== BARANGAYS ====================

  Future<bool> fetchBarangays() async {
    // Don't set loading state initially to avoid setState during build
    _errorMessage = null;

    try {
      final response = await _apiService.getBarangays();
      
      if (response['error'] != null) {
        _errorMessage = response['error'];
        notifyListeners();
        return false;
      }
      
      final List<dynamic> barangayList = response['barangays'] ?? [];
      _barangays = barangayList.map((b) => BarangayModel.fromJson(b)).toList();
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    _otpForDev = null;
    notifyListeners();
  }
}
