# Push Notifications Setup Guide

## Overview
To implement real-time push notifications for attendance updates, leave requests, and important announcements, you'll need to integrate Firebase Cloud Messaging (FCM).

## Requirements
1. Firebase project setup
2. Flutter Firebase packages
3. Backend FCM integration

## Frontend Setup (Flutter)

### 1. Add Dependencies to pubspec.yaml
```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.6
  flutter_local_notifications: ^16.3.0
```

### 2. Initialize Firebase
Create `lib/services/firebase_service.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  // Initialize Firebase and request permissions
  static Future<void> initialize() async {
    await Firebase.initializeApp();
    
    // Request permission (iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token and send to backend
    String? token = await _messaging.getToken();
    if (token != null) {
      // Send token to backend to store in user record
      await _saveTokenToBackend(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveTokenToBackend);

    // Setup local notifications
    await _setupLocalNotifications();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  }

  static Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(settings);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Show local notification when app is in foreground
    const AndroidNotificationDetails androidDetails = 
        AndroidNotificationDetails(
      'attendify_channel',
      'Attendify Notifications',
      channelDescription: 'Notifications for attendance and leave updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Attendify',
      message.notification?.body ?? '',
      details,
    );
  }

  static Future<void> _saveTokenToBackend(String token) async {
    // TODO: Implement API call to save FCM token
    // Example: await ApiService().saveFCMToken(token);
    print('FCM Token: $token');
  }
}

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.notification?.title}');
}
```

### 3. Update main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseService.initialize();
  
  runApp(const MyApp());
}
```

## Backend Setup (Python/Flask)

### 1. Install Firebase Admin SDK
```bash
pip install firebase-admin
```

### 2. Setup Firebase Service
Create `app/services/fcm_service.py`:
```python
import firebase_admin
from firebase_admin import credentials, messaging
import os

class FCMService:
    _initialized = False
    
    @classmethod
    def initialize(cls):
        if not cls._initialized:
            # Download service account key from Firebase Console
            cred = credentials.Certificate('path/to/serviceAccountKey.json')
            firebase_admin.initialize_app(cred)
            cls._initialized = True
    
    @staticmethod
    def send_notification(fcm_token, title, body, data=None):
        """Send push notification to a single device"""
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data or {},
                token=fcm_token,
            )
            
            response = messaging.send(message)
            print(f'Successfully sent message: {response}')
            return True
        except Exception as e:
            print(f'Error sending notification: {e}')
            return False
    
    @staticmethod
    def send_to_multiple(fcm_tokens, title, body, data=None):
        """Send push notification to multiple devices"""
        try:
            message = messaging.MulticastMessage(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data or {},
                tokens=fcm_tokens,
            )
            
            response = messaging.send_multicast(message)
            print(f'Successfully sent to {response.success_count} devices')
            return response
        except Exception as e:
            print(f'Error sending notifications: {e}')
            return None
```

### 3. Add FCM Token Column to Users Table
```sql
ALTER TABLE users ADD COLUMN fcm_token TEXT;
```

### 4. Update User Profile Endpoint
In `app/routes/user.py`:
```python
@user_bp.route('/fcm-token', methods=['POST'])
@token_required
def save_fcm_token():
    """Save FCM token for push notifications"""
    data = request.get_json()
    token = data.get('fcm_token')
    
    if not token:
        return format_response(False, 'FCM token required', status_code=400)
    
    db = get_db()
    result = db.table('users').update({
        'fcm_token': token
    }).eq('id', request.user_id).execute()
    
    return format_response(True, 'FCM token saved')
```

### 5. Send Notifications on Events

#### Attendance Recorded
In `app/routes/attendance.py`:
```python
from app.services.fcm_service import FCMService

# After successful attendance recording
if fcm_token:
    FCMService.send_notification(
        fcm_token=fcm_token,
        title='Attendance Recorded',
        body=f'Time {"In" if action == "TIME_IN" else "Out"} recorded at {time_str}',
        data={
            'type': 'attendance',
            'action': action,
            'status': status
        }
    )
```

#### Leave Request Update
In `app/routes/leave.py`:
```python
# After leave approval/rejection
if employee_fcm_token:
    FCMService.send_notification(
        fcm_token=employee_fcm_token,
        title=f'Leave Request {status.title()}',
        body=f'Your leave request has been {status}',
        data={
            'type': 'leave',
            'leave_id': leave_id,
            'status': status
        }
    )
```

#### Admin Notifications
```python
# Notify admin of new leave request
admin_tokens = get_admin_fcm_tokens(barangay_id)
if admin_tokens:
    FCMService.send_to_multiple(
        fcm_tokens=admin_tokens,
        title='New Leave Request',
        body=f'{employee_name} submitted a leave request',
        data={
            'type': 'leave_pending',
            'leave_id': leave_id
        }
    )
```

## Notification Types

### For Employees:
1. **Attendance Recorded** - Time in/out confirmation
2. **Late Arrival** - Warning when checking in late
3. **Leave Status** - Approved/rejected/pending updates
4. **Announcements** - Important barangay announcements

### For Admins:
1. **New Leave Request** - Employee submitted leave
2. **New Registration** - Employee registration pending approval
3. **Attendance Summary** - Daily attendance reports
4. **System Alerts** - Critical system notifications

## Testing
1. Use Firebase Console to send test messages
2. Test foreground, background, and terminated states
3. Verify notification permissions on both iOS and Android
4. Test notification data payload handling

## Production Checklist
- [ ] Firebase project created
- [ ] Service account key downloaded
- [ ] FCM dependencies added to Flutter
- [ ] Firebase initialized in main.dart
- [ ] Backend FCM service implemented
- [ ] User FCM token storage added
- [ ] Notification triggers implemented
- [ ] iOS push notification certificate configured
- [ ] Android FCM configuration added
- [ ] Notification icons and sounds configured
- [ ] Permission handling tested
- [ ] Background message handling tested
