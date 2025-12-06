# QR Attendance System - Testing Guide

## Overview
The QR attendance system allows employees to scan barangay QR codes for time in/out tracking. Each barangay has a unique QR code, and employees must belong to that barangay to mark attendance.

## Features Implemented

### Backend (Flask - `attendance.py`)
- **POST `/api/attendance/scan`** - Main QR scanning endpoint
  - Validates QR code format: `ATTENDIFY-{BARANGAY}-QR-{hash}`
  - Checks employee belongs to scanned barangay
  - Determines TIME_IN or TIME_OUT based on existing attendance
  - Calculates late duration (grace period: 15 minutes)
  - Detects early checkout (30+ minutes before shift end)
  - Returns action type and attendance data

- **POST `/api/attendance/early-out`** - Submit early checkout with reason
  - Requires `attendance_id` and `reason`
  - Updates time_out and early_out_reason
  - Calculates hours worked

- **GET `/api/attendance/today`** - Get today's attendance record
- **GET `/api/attendance/history`** - Get attendance history with pagination

### Database Schema Updates (Supabase)
```sql
-- barangays table
ALTER TABLE barangays ADD COLUMN qr_code TEXT UNIQUE;

-- users table  
ALTER TABLE users ADD COLUMN shift_start_time TIME DEFAULT '08:00:00';
ALTER TABLE users ADD COLUMN shift_end_time TIME DEFAULT '17:00:00';
ALTER TABLE users ADD COLUMN late_grace_minutes INTEGER DEFAULT 15;

-- attendance table
ALTER TABLE attendance ADD COLUMN early_out_reason TEXT;
ALTER TABLE attendance ADD COLUMN late_duration_minutes INTEGER DEFAULT 0;
ALTER TABLE attendance ADD COLUMN shift_start TIME;
ALTER TABLE attendance ADD COLUMN shift_end TIME;

-- attendance_corrections table (for future use)
CREATE TABLE attendance_corrections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    attendance_id UUID REFERENCES attendance(id) ON DELETE CASCADE,
    request_type TEXT CHECK (request_type IN ('time_out', 'time_in_out')),
    reason TEXT NOT NULL,
    requested_time_out TIMESTAMP WITH TIME ZONE,
    requested_time_in TIMESTAMP WITH TIME ZONE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### Flutter (Mobile App)

#### Updated Files:
1. **`lib/core/constants/api_constants.dart`**
   - Added `attendanceEarlyOut = '/attendance/early-out'`

2. **`lib/services/api_service.dart`**
   - Added `submitEarlyOut(attendanceId, reason)` method
   - Existing methods: `scanAttendance()`, `getTodayAttendance()`, `getAttendanceHistory()`

3. **`lib/providers/attendance_provider.dart`**
   - Added `submitEarlyOut(attendanceId, reason)` method
   - Existing methods: `scanAttendance()`, `fetchTodayAttendance()`, `fetchAttendanceHistory()`

4. **`lib/screens/employee/qr_scanner_screen.dart`** (NEW)
   - Full-screen camera QR scanner using `mobile_scanner` package
   - Custom scanner overlay with corner brackets
   - Success dialogs for TIME_IN and TIME_OUT
   - Early checkout reason prompt dialog
   - Already complete attendance detection
   - Error handling with retry option

5. **`lib/screens/employee/employee_home_screen.dart`**
   - Added "Scan Attendance QR" button above menu items
   - Button navigates to QR scanner screen

## Testing Instructions

### 1. Generate QR Codes for Barangays
Run this SQL in Supabase to generate QR codes:

```sql
-- Update barangays with QR codes (replace with actual IDs)
UPDATE barangays 
SET qr_code = 'ATTENDIFY-SANMIGUEL-QR-' || SUBSTRING(MD5(RANDOM()::TEXT), 1, 8)
WHERE name = 'San Miguel';

UPDATE barangays 
SET qr_code = 'ATTENDIFY-MASICO-QR-' || SUBSTRING(MD5(RANDOM()::TEXT), 1, 8)
WHERE name = 'Masico';

UPDATE barangays 
SET qr_code = 'ATTENDIFY-PANSOL-QR-' || SUBSTRING(MD5(RANDOM()::TEXT), 1, 8)
WHERE name = 'Pansol';

-- Verify QR codes
SELECT id, name, qr_code FROM barangays;
```

### 2. Print QR Codes
Use an online QR code generator (like qr-code-generator.com) to create printable QR codes:
1. Get QR code text from database (e.g., `ATTENDIFY-MASICO-QR-a1b2c3d4`)
2. Generate QR code image
3. Print and place at each barangay location

### 3. Test on Physical Device
**Important:** Camera requires physical device - emulator won't work!

#### Setup:
1. Connect phone via USB or use same WiFi network
2. Update API URL in `api_constants.dart`:
   ```dart
   // For WiFi testing, use your computer's IP
   static const String baseUrl = 'http://192.168.1.XXX:5000/api';
   ```
3. Ensure Flask backend is running: `python app.py`

#### Test Scenarios:

**Scenario 1: Normal Time In**
- Employee scans barangay QR before 8:15 AM
- Expected: "Time In Recorded" success dialog
- Verify in database: `status = 'on_time'`

**Scenario 2: Late Time In**
- Employee scans barangay QR after 8:15 AM (grace period)
- Expected: "Time In Recorded" with "You are X minutes late" message
- Verify in database: `status = 'late'`, `late_duration_minutes > 0`

**Scenario 3: Normal Time Out**
- Employee scans barangay QR after shift end (5:00 PM)
- Expected: "Time Out Recorded" with hours worked
- Verify in database: `time_out` is set

**Scenario 4: Early Checkout (with reason)**
- Employee scans barangay QR before 4:30 PM (30 min before shift end)
- Expected: "Early Checkout" dialog asking for reason
- Enter reason (min 10 characters) and submit
- Expected: "Early Checkout Recorded" success dialog
- Verify in database: `time_out` is set, `early_out_reason` contains text

**Scenario 5: Already Complete**
- Employee scans QR after both time in and time out are recorded
- Expected: "Attendance Complete" dialog showing today's times

**Scenario 6: Wrong Barangay**
- Employee from "Masico" scans "San Miguel" QR code
- Expected: "Invalid QR code" or "You don't belong to this barangay" error

**Scenario 7: Invalid QR Code**
- Scan random QR code (not ATTENDIFY format)
- Expected: "Invalid QR code format" error

### 4. Verify Backend Logs
Check Flask console for:
- QR code validation messages
- Barangay matching results
- Late calculations
- Error messages

### 5. Database Verification
```sql
-- Check today's attendance
SELECT 
    u.name,
    b.name as barangay,
    a.date,
    a.time_in,
    a.time_out,
    a.status,
    a.late_duration_minutes,
    a.early_out_reason
FROM attendance a
JOIN users u ON a.user_id = u.id
JOIN barangays b ON u.barangay_id = b.id
WHERE a.date = CURRENT_DATE
ORDER BY a.time_in DESC;
```

## Known Limitations
1. No auto-timeout for missed time-out (requires cron job - future feature)
2. Attendance corrections require admin approval (UI pending)
3. QR codes are static - no rotation for security (future enhancement)
4. No offline mode - requires internet connection

## Troubleshooting

### Camera Not Working
- Ensure physical device is used (not emulator)
- Check camera permissions in Android/iOS settings
- Verify `mobile_scanner` package is installed: `flutter pub get`

### "Network Error"
- Check Flask backend is running on correct port (5000)
- Verify API URL in `api_constants.dart` matches your setup
- For Android emulator: use `10.0.2.2:5000`
- For physical device: use computer's local IP

### "Invalid QR Code"
- Verify QR code format: `ATTENDIFY-{BARANGAY}-QR-{hash}`
- Check barangay QR codes exist in database
- Ensure barangay name matches exactly (case-sensitive)

### "You don't belong to this barangay"
- Verify user's `barangay_id` matches the scanned barangay
- Check user-barangay relationship in database

### Late Calculation Wrong
- Check user's `shift_start_time` in database
- Verify `late_grace_minutes` setting (default: 15)
- Ensure server timezone matches expected timezone

## Next Steps
1. ✅ Backend attendance endpoints
2. ✅ Flutter QR scanner screen
3. ✅ Integration with AttendanceProvider
4. ⏳ Admin QR code generation screen (print barangay QR codes)
5. ⏳ Attendance correction request UI (employee side)
6. ⏳ Admin attendance correction approval screen
7. ⏳ Auto-timeout cron job for missed time-outs
8. ⏳ Attendance reports and analytics
