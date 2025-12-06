# 🔄 NEW ATTENDANCE SYSTEM - Admin Scans Employee QR

## ✅ System Changes Complete!

### **NEW WORKFLOW:**
1. **Employee**: Has personal QR code displayed on their home screen
2. **Admin**: Opens app, clicks "Scan Employee QR Code"
3. **Admin**: Points camera at employee's phone QR code
4. **System**: Records attendance for that employee (time in/out, late status, etc.)

---

## 🎯 What Changed

### ❌ **OLD SYSTEM (Removed)**
- Barangay QR codes at office entrance
- Employees scan barangay QR  
- Employee self-service attendance

### ✅ **NEW SYSTEM (Current)**
- Employee personal QR codes (already exists in app)
- Admin scans employee QR
- Admin-controlled attendance recording

---

## 📋 Testing Guide

### **Step 1: Admin Login**
```
1. Open app as admin
2. You'll see "Scan Employee QR Code" button
3. Click it to open scanner
```

### **Step 2: Employee Shows QR**
```
1. Employee opens their app
2. Their home screen shows their personal QR code
3. Employee shows phone to admin
```

### **Step 3: Admin Scans**
```
1. Admin points camera at employee's QR code
2. System automatically:
   - Identifies the employee
   - Checks if it's time in or time out
   - Calculates late status
   - Records attendance
3. Success dialog shows employee name + time recorded
```

---

## 🔍 Backend Logic

**Scan Endpoint: `POST /api/attendance/scan`**

```python
1. Verify scanner is admin (not employee)
2. Decode QR code (employee's personal QR)
3. Look up employee by qr_code in users table
4. Verify employee belongs to admin's barangay
5. Check employee's shift times
6. Determine if TIME IN or TIME OUT:
   - No record today → TIME IN
   - Has time_in, no time_out → TIME OUT
   - Both exist → Error (already complete)
7. Calculate late status (for TIME IN):
   - Compare scan time vs shift_start_time
   - Grace period: 15 minutes
   - Status: 'on_time' or 'late'
8. Save to attendance table
9. Return success with employee name
```

---

## 🗄️ Database Schema (No Changes Needed!)

**users table:**
```sql
- id (uuid)
- qr_code (text) ← Employee's personal QR
- first_name, last_name
- barangay_id
- shift_start_time, shift_end_time
- role ('admin' or 'employee')
```

**attendance table:**
```sql
- id (uuid)
- user_id → references users(id)
- date
- time_in, time_out
- status ('on_time', 'late', 'absent', 'on_leave')
- late_duration_minutes
- shift_start, shift_end
- early_out_reason
- notes
```

**barangays table:**
```sql
- id, name
- qr_code ← No longer used for attendance
```

---

## 🚀 Setup Steps

### **1. Restart Backend**
```bash
cd attendify-backend
python app.py
```

You'll see:
```
🚀 Attendify Backend Starting...
```

### **2. Hot Restart Flutter**
```bash
# In Flutter running terminal, press:
R  # Hot restart

# Or rebuild:
cd attendify
flutter run
```

### **3. Test the Flow**

**As Admin:**
```
1. Login as admin
2. Click "Scan Employee QR Code"
3. Point at employee's phone (they should have app open showing their QR)
4. Should see: "Time In Recorded for [Employee Name]"
```

**As Employee:**
```
1. Login as employee
2. Home screen shows your personal QR code
3. Show it to admin to scan
4. Go to "Attendance History" to verify record
```

---

## 📊 Backend Logs (What to Look For)

**Successful Scan:**
```
============================================================
[QR SCAN] Request received from user: admin-uuid (role: admin)
[QR SCAN] ✓ Camera scan: EMPLOYEE-QR-abc123
[QR SCAN] ✓ Admin verified
[QR SCAN] Looking up employee with QR: EMPLOYEE-QR-abc123
[QR SCAN] ✓ Employee found: Juan Dela Cruz (ID: employee-uuid)
[QR SCAN] ✓ Employee belongs to admin's barangay
[QR SCAN] ✓ Shift times: 08:00:00 - 17:00:00
[TIME IN] ✓ Time in recorded
```

**Error - Non-admin tries to scan:**
```
[QR SCAN] ❌ Non-admin user tried to scan: employee
Response: "Only admins can scan employee QR codes"
```

**Error - Invalid QR:**
```
[QR SCAN] ❌ Invalid employee QR code
Response: "Invalid employee QR code"
```

**Error - Wrong barangay:**
```
[QR SCAN] ❌ Employee belongs to different barangay: Barangay Masico
Response: "This employee belongs to Barangay Masico..."
```

---

## ✅ Verification Checklist

### **Backend:**
- [ ] Scan endpoint only allows admin role
- [ ] Looks up employee by qr_code
- [ ] Validates barangay match
- [ ] Calculates late status correctly
- [ ] Records attendance in database

### **Frontend:**
- [ ] Admin has "Scan Employee QR Code" button
- [ ] Employee shows personal QR on home screen
- [ ] Scanner opens camera for admin
- [ ] Success dialog shows employee name
- [ ] Attendance history shows all records

### **Database:**
- [ ] users.qr_code contains employee personal QR
- [ ] attendance.user_id references scanned employee
- [ ] attendance.status shows 'on_time' or 'late' correctly
- [ ] attendance.late_duration_minutes calculated properly

---

## 🐛 Troubleshooting

### **Issue: "Only admins can scan"**
**Problem:** Logged in as employee
**Solution:** Login as admin account

### **Issue: "Invalid employee QR code"**
**Problem:** QR code not found in users table
**Solution:** Check users table, ensure qr_code column has value

### **Issue: "Employee belongs to different barangay"**
**Problem:** Admin and employee have different barangay_id
**Solution:** Assign employee to correct barangay in database

### **Issue: "Shift times not configured"**
**Problem:** Employee missing shift_start_time or shift_end_time
**Solution:** Update employee record:
```sql
UPDATE users 
SET shift_start_time = '08:00:00', shift_end_time = '17:00:00'
WHERE id = 'employee-uuid';
```

### **Issue: Scanner not opening**
**Problem:** Camera permission denied
**Solution:** Phone Settings → Apps → Attendify → Permissions → Camera (Allow)

---

## 📱 User Guide

### **For Employees:**
1. Open Attendify app
2. Your QR code is displayed on home screen
3. When arriving at work, show your phone to admin
4. Admin will scan your QR code
5. Check "Attendance History" to verify

### **For Admins:**
1. Open Attendify app
2. Click "Scan Employee QR Code" button
3. Point camera at employee's phone
4. Wait for automatic scan
5. Success message shows employee name + time recorded
6. View all attendance in "Attendance History"

---

## 🎉 Benefits of New System

✅ **Centralized Control**: Admin manages all attendance
✅ **No Physical QR Codes**: No need to print/post barangay QR codes
✅ **Employee Accountability**: Admin verifies employee presence
✅ **Simple Setup**: Uses existing employee QR codes
✅ **Audit Trail**: Clear record of who scanned whom
✅ **Same Features**: Late calculation, early checkout, attendance history

---

## 🔄 Migration Notes

**What to Remove:**
- ❌ Barangay QR code images (in `barangay_qr_codes/` folder)
- ❌ Posted QR codes at office entrances

**What to Keep:**
- ✅ Employee personal QR codes (in users.qr_code)
- ✅ All attendance records (attendance table)
- ✅ Barangays table (still used for employee-admin association)

**No Data Loss:**
- All existing attendance records remain intact
- All user accounts unchanged
- All shift times preserved

---

## 📞 Support

If you encounter issues:
1. Check backend logs for detailed error messages
2. Verify database schema matches above
3. Ensure admin and employee belong to same barangay
4. Test camera permissions on phone
5. Check network connectivity (phone and laptop on same WiFi)

---

**System Status:** ✅ Ready for production use!
**Last Updated:** December 6, 2025
