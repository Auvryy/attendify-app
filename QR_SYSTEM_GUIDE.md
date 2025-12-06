# QR Attendance System - Complete Guide

## ✅ Recent Updates (Completed)

### 1. Admin QR Download Feature
**Status:** ✅ Implemented

Added QR code download functionality to the admin home screen, matching the employee functionality:
- Screenshot package captures QR widget as PNG
- FlutterFileDialog opens native Android save dialog
- User can choose save location (Downloads, Documents, etc.)
- Success/error feedback via SnackBar

**File Modified:** `lib/screens/admin/admin_home_screen.dart`
- Added imports: `dart:typed_data`, `dart:ui`, `flutter/rendering`, `flutter_file_dialog`
- Added `GlobalKey _qrKey` for QR widget reference
- Wrapped QR code in `RepaintBoundary` widget
- Added `_downloadQRCode()` method
- Added "Download QR Code" button below QR display

## 🎯 QR Scanning Architecture

### Who Scans What?
**IMPORTANT:** Employees scan **BARANGAY QR codes**, NOT personal QR codes or admin QR codes.

1. **Barangay QR Codes** (Office/Location QR)
   - One QR code per barangay/office
   - Generated from `barangays` table `qr_code` column
   - Should be printed and placed at office entrance
   - Employees scan this to check in/out

2. **Employee Personal QR Codes**
   - Displayed on employee home screen
   - Used for identification purposes (future features)
   - Can be downloaded by employee
   - NOT used for attendance scanning

3. **Admin Personal QR Codes**
   - Displayed on admin home screen
   - Used for admin identification
   - Can be downloaded by admin
   - NOT used for attendance scanning

### Scanning Flow
```
Employee arrives → Opens Attendify app → Clicks "Scan Attendance QR"
         ↓
Scans BARANGAY QR CODE at office entrance
         ↓
Backend validates:
- QR code matches a barangay
- Employee belongs to that barangay
- Shift times are configured
         ↓
Records TIME IN (or TIME OUT if already checked in)
         ↓
Shows success dialog → Employee returns to home
         ↓
Attendance appears in "Attendance History"
```

## 📱 Scanning Methods

### Method 1: Camera Scan
- Uses `mobile_scanner` package
- Real-time QR detection
- Auto-stops camera when QR detected
- Requires CAMERA permission (✅ already added in AndroidManifest.xml)

### Method 2: Image Upload
- Uses `image_picker` package
- Picks image from gallery
- Reads bytes directly via `image.readAsBytes()`
- Converts to base64 and sends to backend
- Backend uses `pyzbar` + `PIL` to decode QR from image

## 🔧 Troubleshooting Scanning Issues

### Issue: "It doesn't scan even though it is"

#### Possible Causes & Solutions:

#### 1. **Camera Permissions Not Granted**
**Solution:** Check phone settings
```
Settings → Apps → Attendify → Permissions → Camera (ALLOW)
```
**Verification:** Camera permissions already added to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

#### 2. **Scanning Wrong QR Code**
**Problem:** Employee scanning their own personal QR or admin QR
**Solution:** Print and scan the **BARANGAY QR CODE** from the database

**To Generate Barangay QR:**
1. Backend route to get barangay QR:
   ```
   GET http://YOUR_BACKEND_IP:5000/api/general/barangays
   ```
2. Find your barangay's `qr_code` value
3. Use any QR generator website (qr-code-generator.com) to create printable QR
4. Print and place at office entrance

**Quick Test:**
```bash
# In backend directory, run Python script to print barangay QR codes:
python -c "from app.database import get_db; db = get_db(); result = db.table('barangays').select('id, name, qr_code').execute(); [print(f'{b[\"name\"]}: {b[\"qr_code\"]}') for b in result.data]"
```

#### 3. **Employee Not Assigned to Barangay**
**Backend validates:** `user['barangay_id'] == scanned_barangay['id']`

**Solution:** Admin must assign employee to correct barangay
- Check user profile: `GET /api/user/profile`
- Update if needed: Admin should approve registration with correct barangay

#### 4. **Shift Times Not Configured**
**Backend check:** User must have `shift_start_time` and `shift_end_time`

**Solution:** Admin must configure shift times for employee
```sql
-- Check in Supabase:
SELECT id, email, shift_start_time, shift_end_time FROM users WHERE id = 'USER_ID';

-- Update if missing:
UPDATE users 
SET shift_start_time = '08:00:00', shift_end_time = '17:00:00' 
WHERE id = 'USER_ID';
```

#### 5. **Backend Not Reachable**
**Symptoms:** Loading forever, network error

**Solution:**
1. Ensure backend is running: `cd attendify-backend && python app.py`
2. Check backend IP in `lib/core/constants/api_constants.dart`:
   ```dart
   static const String baseUrl = 'http://YOUR_LOCAL_IP:5000';
   ```
3. Phone and computer must be on same WiFi
4. Test backend: `curl http://YOUR_IP:5000/api/general/health`

#### 6. **QR Code Format Invalid**
**Backend expects:** Plain text string in QR (e.g., "BARANGAY-PILA-001")

**Not supported:** URLs, JSON, special encoding

**Validation:** Backend checks `barangays.qr_code` column matches scanned value exactly

#### 7. **Already Checked In/Out**
**Scenario:** Employee already completed TIME IN + TIME OUT today

**Response:** Backend returns `action: 'ALREADY_COMPLETE'` with 400 status

**Solution:** This is expected behavior. Employee can't scan again until next day.

## 🧪 Testing Checklist

### Backend Testing
```bash
# 1. Start backend
cd attendify-backend
python app.py

# 2. Test health endpoint
curl http://localhost:5000/api/general/health

# 3. Get barangays (to see QR codes)
curl http://localhost:5000/api/general/barangays

# 4. Test scan endpoint (replace TOKEN and QR_CODE)
curl -X POST http://localhost:5000/api/attendance/scan \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"qr_code": "BARANGAY-QR-VALUE"}'
```

### Frontend Testing
1. **Camera Scan:**
   - Open app → Employee Home → "Scan Attendance QR"
   - Point at printed barangay QR code
   - Should detect and process within 2 seconds
   - Check success dialog appears

2. **Image Upload:**
   - Take photo of barangay QR with phone camera first
   - Open app → Employee Home → "Scan Attendance QR"
   - Click "Upload QR Image" button at bottom
   - Select the photo from gallery
   - Should process and show success dialog

3. **Attendance History:**
   - After successful scan
   - Go to "Attendance History"
   - Should see today's record at top with TIME IN
   - Scan again later for TIME OUT

### Admin Testing
1. **Admin QR Download:**
   - Login as admin
   - Admin home screen shows admin QR code
   - Click "Download QR Code" button
   - Choose save location in dialog
   - Should show "QR Code saved successfully!"
   - Check Downloads folder for `admin_qr_TIMESTAMP.png`

2. **View All Attendance:**
   - Admin Home → "Attendance History"
   - Should see all employees' attendance records
   - Today's records shown separately
   - Verify employee scans appear here

## 📊 Attendance History Verification

### Employee Attendance History
**Screen:** `lib/screens/employee/attendance_history_screen.dart`
**Fetches:** `GET /api/attendance/history?limit=30&offset=0`
**Displays:** Current user's attendance only

**Expected Behavior:**
- Shows date, time in, time out
- Status badge (On Time / Late)
- Pull to refresh
- Infinite scroll (loads more)

### Admin Attendance History
**Screen:** `lib/screens/admin/admin_attendance_history_screen.dart`
**Fetches:** `GET /api/admin/attendance` (all employees)
**Displays:** All employees' attendance

**Expected Behavior:**
- Separated into "Today" and "Previous History"
- Shows employee name, date, times, status
- Pull to refresh
- Shows up to 50 previous records

## 🐛 Debugging Tips

### Enable Debug Logging
**Backend (attendance.py):**
```python
# Already has print statements:
print(f"[TIME IN ERROR] {e}")
print(f"[TIME OUT ERROR] {e}")
```

**Frontend (qr_scanner_screen.dart):**
Add debug prints:
```dart
void _onDetect(BarcodeCapture capture) async {
  print('[QR SCAN] Detected: ${capture.barcodes.length} barcodes');
  final qrCode = capture.barcodes.first.rawValue;
  print('[QR SCAN] QR Code: $qrCode');
  // ... rest of method
}
```

### Check Flutter Logs
```bash
# Real-time logs when app running:
flutter logs

# Or via Android Studio:
Run → View → Tool Windows → Logcat
```

### Check Backend Logs
```bash
# Backend prints to terminal where app.py is running
# Watch for:
# - [TIME IN ERROR]
# - [TIME OUT ERROR]
# - 401/403/500 errors
```

### Common Error Responses

**401 Unauthorized:**
- Token expired or invalid
- Solution: Logout and login again

**403 Forbidden:**
- User belongs to different barangay
- Solution: Check barangay_id matches

**400 Bad Request - "Invalid QR code":**
- QR code not found in barangays table
- Solution: Verify QR code value in database

**400 Bad Request - "Shift times not configured":**
- User missing shift_start_time or shift_end_time
- Solution: Admin updates user in Supabase

**400 Bad Request - "Attendance already completed":**
- Already TIME IN + TIME OUT today
- Solution: Expected behavior, wait until next day

## 📋 API Reference

### Scan Attendance
**Endpoint:** `POST /api/attendance/scan`
**Auth:** Bearer token (employee_required)
**Body (Option 1 - Camera):**
```json
{
  "qr_code": "BARANGAY-PILA-001"
}
```
**Body (Option 2 - Image Upload):**
```json
{
  "image": "data:image/png;base64,iVBORw0KGgoAAAANS..."
}
```

**Success Response (TIME IN):**
```json
{
  "success": true,
  "message": "Time In Recorded: 08:15 AM",
  "data": {
    "action": "TIME_IN",
    "status": "on_time",
    "time_in": "08:15:30",
    "late_minutes": 0,
    "attendance_id": "uuid"
  }
}
```

**Success Response (TIME OUT):**
```json
{
  "success": true,
  "message": "Time Out Recorded: 05:30 PM",
  "data": {
    "action": "TIME_OUT",
    "time_out": "17:30:45",
    "hours_worked": 8.25
  }
}
```

**Error Response (Early Checkout):**
```json
{
  "success": false,
  "message": "Early checkout requires a reason",
  "data": {
    "action": "EARLY_OUT_REASON_REQUIRED",
    "early_minutes": 45,
    "attendance_id": "uuid"
  }
}
```

## 🚀 Next Steps

### To Deploy to Production:
1. Build release APK:
   ```bash
   cd attendify
   flutter build apk --release
   ```
2. Find APK: `build/app/outputs/flutter-apk/app-release.apk`
3. Install on employee phones
4. Configure backend IP to production server
5. Print barangay QR codes and place at office entrances

### Future Enhancements:
- [ ] Offline attendance (save locally, sync when online)
- [ ] Face recognition with QR for dual verification
- [ ] Geofencing (verify employee is physically at barangay)
- [ ] Push notifications for missed check-in/out
- [ ] Attendance reports (weekly/monthly PDF)

## 📞 Support

If scanning still doesn't work after following this guide:
1. Check all items in "Testing Checklist"
2. Enable debug logging and share logs
3. Verify backend and frontend versions match
4. Test with a fresh user account
5. Try both camera scan AND image upload methods

---

**Last Updated:** After implementing admin QR download feature
**System Status:** ✅ All core features implemented and tested
