// lib/providers/notification_provider.dart

import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _errorMessage;
  List<NotificationModel> _notifications = [];
  int _totalRecords = 0;
  int _currentPage = 1;
  int _unreadCount = 0;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<NotificationModel> get notifications => _notifications;
  int get totalRecords => _totalRecords;
  bool get hasMore => _notifications.length < _totalRecords;
  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;

  // ==================== FETCH NOTIFICATIONS ====================

  Future<bool> fetchNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _notifications = [];
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getNotifications(page: _currentPage);
      
      print('[NotificationProvider] Response: $response');
      
      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Failed to fetch notifications';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final data = response['data'] ?? {};
      print('[NotificationProvider] Data: $data');
      
      final List<dynamic> records = data['notifications'] ?? [];
      print('[NotificationProvider] Records count: ${records.length}');
      
      final newRecords = records.map((r) => NotificationModel.fromJson(r)).toList();
      
      if (refresh) {
        _notifications = newRecords;
      } else {
        _notifications.addAll(newRecords);
      }
      
      _totalRecords = data['total'] ?? _notifications.length;
      _unreadCount = data['unread_count'] ?? _notifications.where((n) => !n.isRead).length;
      _currentPage++;
      
      print('[NotificationProvider] Total notifications: ${_notifications.length}, unread: $_unreadCount');
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      print('[NotificationProvider] Error: $e');
      print('[NotificationProvider] Stack trace: $stackTrace');
      _errorMessage = 'Network error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== MARK AS READ ====================

  Future<bool> markAsRead(String id) async {
    _errorMessage = null;

    try {
      final response = await _apiService.markNotificationRead(id);
      
      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Failed to mark as read';
        notifyListeners();
        return false;
      }
      
      // Update the notification in the list
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        final notification = _notifications[index];
        if (!notification.isRead) {
          _notifications[index] = NotificationModel(
            id: notification.id,
            userId: notification.userId,
            title: notification.title,
            message: notification.message,
            type: notification.type,
            isRead: true,
            createdAt: notification.createdAt,
          );
          _unreadCount = (_unreadCount - 1).clamp(0, _totalRecords);
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // ==================== MARK ALL AS READ ====================

  Future<bool> markAllAsRead() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.markAllNotificationsRead();
      
      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Failed to mark all as read';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Update all notifications in the list
      _notifications = _notifications.map((n) => NotificationModel(
        id: n.id,
        userId: n.userId,
        title: n.title,
        message: n.message,
        type: n.type,
        isRead: true,
        createdAt: n.createdAt,
      )).toList();
      _unreadCount = 0;
      
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
    _notifications = [];
    _totalRecords = 0;
    _currentPage = 1;
    _unreadCount = 0;
    notifyListeners();
  }
}
