# QR Upload & Download Features - Implementation Summary

## New Features Added

### 1. Upload QR Image for Scanning
Employees can now upload a QR code image from their device instead of using the camera. This is useful when:
- Testing without a physical QR code
- Camera permissions are denied
- QR code is saved as an image on the device

### 2. Download Your QR Code
Employees can download their personal QR code as an image file to their device. This allows them to:
- Share their QR code with admins
- Keep a backup copy
- Print if needed

## Implementation Details

### Backend Changes

#### Updated Files:
**`requirements.txt`**
- Added `Pillow==10.1.0` - Image processing library
- Added `pyzbar==0.1.9` - QR code decoding from images
- Added `opencv-python-headless==4.8.1.78` - Image processing support

**`app/routes/attendance.py`**
- Updated `/api/attendance/scan` endpoint to accept both:
  - `qr_code` string (existing functionality)
  - `image` base64-encoded image (NEW)
- Added QR code detection from uploaded images using pyzbar
- Automatically decodes QR from image and processes attendance

#### How It Works:
```python
# Backend processes two types of requests:

# 1. Direct QR code string
POST /api/attendance/scan
{
  "qr_code": "ATTENDIFY-MASICO-QR-abc123"
}

# 2. Base64 image upload
POST /api/attendance/scan
{
  "image": "data:image/png;base64,iVBORw0KG..."
}
```

### Flutter Changes

#### Updated Files:

**`pubspec.yaml`**
- Added `qr_code_scanner: ^1.0.1` - QR scanning from images
- Added `path_provider: ^2.1.1` - File system access for downloads

**`lib/services/api_service.dart`**
- Added `scanAttendanceFromImage(base64Image)` method
- Sends base64-encoded image to backend

**`lib/providers/attendance_provider.dart`**
- Added `scanAttendanceFromImage(base64Image)` method
- Handles state management for image-based scanning

**`lib/screens/employee/qr_scanner_screen.dart`**
- Added "Upload QR Image" button at bottom of scanner screen
- Implemented `_pickImageAndScan()` method:
  1. Opens image picker (gallery)
  2. Reads selected image as bytes
  3. Converts to base64
  4. Sends to backend via provider
  5. Shows success/error dialog
- Button is disabled while processing to prevent multiple uploads

**`lib/screens/employee/employee_home_screen.dart`**
- Added `RepaintBoundary` wrapper around QR code widget
- Added "Download QR Code" button below QR display
- Implemented `_downloadQRCode()` method:
  1. Captures QR code widget as PNG image
  2. Saves to app documents directory
  3. Shows success message with file path
- Uses GlobalKey to access QR widget for capture

## Usage Instructions

### For Employees

#### Scanning QR Code from Image:
1. Open the app and tap "Scan Attendance QR"
2. At the bottom of the scanner screen, tap "Upload QR Image"
3. Select a QR code image from your device
4. The app will automatically process it and mark attendance
5. You'll see a success dialog if the scan was successful

#### Downloading Your QR Code:
1. Go to the Employee Home screen
2. Scroll to your QR code display
3. Tap "Download QR Code" button below the QR
4. The QR will be saved to your device
5. You'll see a message showing where it was saved

### Testing the Upload Feature

#### Create a Test QR Image:
1. Go to an online QR generator (e.g., qr-code-generator.com)
2. Enter your barangay QR code (e.g., `ATTENDIFY-MASICO-QR-abc123`)
3. Generate and download the QR code image
4. Save it to your phone

#### Test Upload:
1. Open Attendify app
2. Tap "Scan Attendance QR"
3. Tap "Upload QR Image"
4. Select the downloaded QR image
5. Verify attendance is marked correctly

## Technical Details

### Image Processing Flow (Backend):
```
1. Receive base64 image from Flutter
2. Remove data:image prefix if present
3. Decode base64 to bytes
4. Open image with PIL (Pillow)
5. Decode QR code using pyzbar
6. Extract QR code string
7. Process attendance as normal
```

### QR Download Flow (Flutter):
```
1. User taps Download button
2. Find QR widget using GlobalKey
3. Get RenderRepaintBoundary
4. Convert to UI.Image with 3x pixel ratio
5. Convert to PNG bytes
6. Save to app documents directory
7. Show success message with path
```

## Error Handling

### Upload Errors:
- **No QR code found**: Image doesn't contain a valid QR code
- **Failed to process image**: Invalid image format or corrupted file
- **Network error**: Backend is unreachable
- **Invalid QR code**: QR code doesn't match ATTENDIFY format

### Download Errors:
- **Failed to save**: Insufficient storage or permissions issue
- Shows error snackbar in red

## File Locations

### Downloaded QR Codes:
- **Android**: `/data/user/0/com.example.attendify/app_flutter/my_qr_code.png`
- **iOS**: `Documents/my_qr_code.png`

Files can be accessed through device file manager or transferred to computer.

## Limitations

1. **Image Upload**:
   - Only processes one QR code per image
   - Image must be clear and not blurry
   - Maximum image size limited by Flutter (usually 10MB)

2. **QR Download**:
   - Always overwrites previous download (same filename)
   - Saved to app's private directory (not gallery)
   - Requires manual file transfer to share

## Future Enhancements

Potential improvements for later:
1. Save QR to device gallery instead of app directory
2. Share QR code directly via system share sheet
3. Support scanning multiple QR codes from one image
4. Add image cropping before upload
5. Auto-enhance blurry images before processing
6. Allow custom filename for downloads
7. Batch QR scanning from multiple images

## Troubleshooting

### "No QR code found in image"
- Ensure image contains a clear, visible QR code
- Try taking a better photo with good lighting
- Make sure entire QR code is visible in frame

### "Failed to process image"
- Check image file isn't corrupted
- Verify image format is supported (PNG, JPG)
- Try a different image

### "Failed to save QR code"
- Check device has available storage
- Restart the app and try again
- Check app has necessary permissions

### Backend Errors
- Ensure Python packages are installed: `pip install Pillow pyzbar opencv-python-headless`
- Verify backend is running and accessible
- Check backend logs for detailed error messages

## Testing Checklist

- [ ] Upload clear QR image - should mark attendance
- [ ] Upload blurry QR image - should show error
- [ ] Upload non-QR image - should show "No QR code found"
- [ ] Upload wrong barangay QR - should show validation error
- [ ] Download QR code - should save successfully
- [ ] Download QR code twice - should overwrite previous
- [ ] Upload button disabled while processing
- [ ] Camera still works normally
- [ ] Success/error dialogs show correctly
- [ ] File path shown in success message

## Notes for Developers

- Base64 encoding happens in Flutter, not backend
- Backend uses pyzbar which requires zbar library (included in wheel)
- RepaintBoundary needed to capture widget as image
- GlobalKey used to access widget's RenderObject
- Image picker quality set to 85% to balance quality/size
