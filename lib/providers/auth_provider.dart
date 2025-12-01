// lib/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  String? _verificationToken;
  String? _pendingEmail;
  String? _resetToken;

  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => _user?.isAdmin ?? false;
  String? get verificationToken => _verificationToken;
  String? get pendingEmail => _pendingEmail;

  // Initialize - check for existing session
  Future<void> init() async {
    _status = AuthStatus.loading;
    notifyListeners();
    
    await _apiService.init();
    
    if (_apiService.isLoggedIn) {
      await _fetchProfile();
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await _apiService.getProfile();
      // Backend returns {success, data: {user}}
      if (response['success'] == true) {
        final data = response['data'];
        if (data != null && data['user'] != null) {
          _user = UserModel.fromJson(data['user']);
          _status = AuthStatus.authenticated;
          notifyListeners();
          return;
        }
      }
      _status = AuthStatus.unauthenticated;
      await _apiService.clearTokens();
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      await _apiService.clearTokens();
    }
    notifyListeners();
  }

  // ==================== REGISTRATION ====================

  Future<bool> sendRegistrationOtp(String email) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.registerSendOtp(email);
      
      // Backend returns {success, message}
      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Failed to send OTP';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      
      _pendingEmail = email;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyRegistrationOtp(String otp) async {
    if (_pendingEmail == null) {
      _errorMessage = 'Please request OTP first';
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.registerVerifyOtp(_pendingEmail!, otp);
      
      // Backend returns {success, message} on success
      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Invalid OTP';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeRegistration({
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String barangayId,  // Changed to String for UUID
  }) async {
    if (_pendingEmail == null) {
      _errorMessage = 'Please complete email verification first';
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.registerComplete(
        email: _pendingEmail!,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        barangayId: barangayId,
      );
      
      // Backend returns {success, data: {user, access_token, refresh_token}}
      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Registration failed';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      
      final data = response['data'];
      if (data != null && data['user'] != null) {
        _user = UserModel.fromJson(data['user']);
      }
      _pendingEmail = null;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ==================== LOGIN ====================

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      
      print('Auth provider received: $response');
      
      // Backend returns {success, message, data: {user, access_token, refresh_token}}
      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Invalid email or password';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      
      final data = response['data'];
      if (data == null || data['user'] == null) {
        _errorMessage = 'Login failed: No user data received';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      
      _user = UserModel.fromJson(data['user']);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      print('Login exception: $e');
      _errorMessage = 'Network error. Please check your connection.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ==================== PASSWORD RESET ====================

  Future<bool> forgotPassword(String email) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.forgotPassword(email);
      
      if (response['error'] != null) {
        _errorMessage = response['error'];
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      
      _pendingEmail = email;
      // Development mode - OTP might be returned
      if (response['otp'] != null) {
        _errorMessage = 'Development mode - OTP: ${response['otp']}';
      }
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyPasswordOtp(String otp) async {
    if (_pendingEmail == null) {
      _errorMessage = 'Please request password reset first';
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.verifyPasswordOtp(_pendingEmail!, otp);
      
      if (response['error'] != null) {
        _errorMessage = response['error'];
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      
      _resetToken = response['reset_token'];
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String newPassword) async {
    if (_resetToken == null) {
      _errorMessage = 'Please verify OTP first';
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.resetPassword(_resetToken!, newPassword);
      
      if (response['error'] != null) {
        _errorMessage = response['error'];
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      
      _pendingEmail = null;
      _resetToken = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ==================== LOGOUT ====================

  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _apiService.logout();
    } catch (e) {
      // Even if logout fails on server, clear local state
    }
    
    _user = null;
    _pendingEmail = null;
    _verificationToken = null;
    _resetToken = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Update user locally (after profile update)
  void updateUser(UserModel user) {
    _user = user;
    notifyListeners();
  }
}
