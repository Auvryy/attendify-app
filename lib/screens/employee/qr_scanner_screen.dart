// lib/screens/employee/qr_scanner_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/attendance_provider.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrCode = barcodes.first.rawValue;
    if (qrCode == null || qrCode.isEmpty) return;

    print('\n${'='*60}');
    print('[QR SCAN] QR Code detected: $qrCode');
    print('[QR SCAN] Barcode format: ${barcodes.first.format}');

    setState(() => _isProcessing = true);

    // Stop camera while processing
    await cameraController.stop();

    if (!mounted) return;

    print('[QR SCAN] Sending to backend...');
    final provider = context.read<AttendanceProvider>();
    final result = await provider.scanAttendance(qrCode);

    print('[QR SCAN] Backend response: $result');

    if (!mounted) return;

    if (result != null && result['success'] == true) {
      print('[QR SCAN] ✓ Success!');
      _handleSuccess(result);
    } else {
      print('[QR SCAN] ❌ Failed: ${result?["message"] ?? "Unknown error"}');
      _handleError(result ?? {'message': 'Scan failed'});
    }

    setState(() => _isProcessing = false);
  }

  void _handleSuccess(Map<String, dynamic> result) {
    final action = result['data']?['action'];
    final timeStr = result['message']; // "Time In Recorded: 5:28 PM"
    final status = result['data']?['status'];
    final lateMinutes = result['data']?['late_minutes'] ?? 0;
    final hoursWorked = result['data']?['hours_worked'];
    final employeeName = result['data']?['employee_name'] ?? 'Employee';

    print('[QR SCAN SUCCESS] action: $action, status: $status, late_minutes: $lateMinutes, employee: $employeeName');

    if (action == 'TIME_IN') {
      // Extract time from message (e.g., "Time In Recorded: 5:28 PM" -> "5:28 PM")
      String displayTime = timeStr;
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          displayTime = '${parts[1].trim()}:${parts.length > 2 ? parts[2].trim() : ''}';
        }
      }

      // Determine status display
      String statusInfo;
      Color statusColor;
      IconData statusIcon;
      
      if (status == 'late' && lateMinutes > 0) {
        statusInfo = 'Late ($lateMinutes min)';
        statusColor = AppColors.error;
        statusIcon = Icons.warning_rounded;
      } else {
        statusInfo = 'On Time';
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
      }

      _showSuccessDialog(
        title: employeeName,
        message: displayTime,
        icon: statusIcon,
        color: statusColor,
        additionalInfo: statusInfo,
      );
    } else if (action == 'TIME_OUT') {
      // Extract time from message
      String displayTime = timeStr;
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          displayTime = '${parts[1].trim()}:${parts.length > 2 ? parts[2].trim() : ''}';
        }
      }

      // Determine early/overtime status
      final timeStatus = result['data']?['time_status'];
      final earlyMinutes = result['data']?['early_minutes'] ?? 0;
      final overtimeMinutes = result['data']?['overtime_minutes'] ?? 0;
      
      String statusInfo;
      Color statusColor;
      IconData statusIcon;
      
      if (timeStatus == 'early' && earlyMinutes > 0) {
        statusInfo = 'Early ($earlyMinutes min)';
        statusColor = AppColors.warning;
        statusIcon = Icons.access_time;
      } else if (timeStatus == 'overtime' && overtimeMinutes > 0) {
        statusInfo = 'Overtime (+$overtimeMinutes min)';
        statusColor = AppColors.info;
        statusIcon = Icons.add_alarm;
      } else {
        statusInfo = hoursWorked != null ? '${hoursWorked}h worked' : 'On Time';
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
      }
      
      _showSuccessDialog(
        title: employeeName,
        message: displayTime,
        icon: statusIcon,
        color: statusColor,
        additionalInfo: statusInfo,
      );
    }
  }

  void _handleError(Map<String, dynamic> result) {
    final action = result['data']?['action'];

    if (action == 'EARLY_OUT_REASON_REQUIRED') {
      _showEarlyOutDialog(result['data']);
    } else if (action == 'ALREADY_COMPLETE') {
      _showAlreadyCompleteDialog(result['data']);
    } else {
      _showErrorDialog(result['message'] ?? 'Scan failed');
    }
  }

  void _pickImageAndScan() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isProcessing = true);

      // Stop camera while processing
      await cameraController.stop();

      // Read image as base64 directly from XFile (no File path needed)
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      if (!mounted) return;

      final provider = context.read<AttendanceProvider>();
      final result = await provider.scanAttendanceFromImage(base64Image);

      if (!mounted) return;

      if (result != null && result['success'] == true) {
        _handleSuccess(result);
      } else {
        _showErrorDialog(result?['message'] ?? 'Failed to scan QR from image');
      }

      setState(() => _isProcessing = false);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorDialog('Failed to process image: $e');
    }
  }

  void _showSuccessDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    String? additionalInfo,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with colored background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: 50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Attendance Recorded',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Body content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Employee name
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Attendance has been successfully recorded.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Time info box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.access_time,
                            color: Colors.amber.shade800,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                message,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            additionalInfo ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Stay on scanner to scan another
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: color, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Scan Another',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context); // Go back to home
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error, color: AppColors.error),
            SizedBox(width: 8),
            Text('Scan Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              cameraController.start(); // Resume camera
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAlreadyCompleteDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Attendance Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You have already completed attendance for today.'),
            const SizedBox(height: 16),
            Text('Time In: ${data['time_in']}'),
            Text('Time Out: ${data['time_out']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEarlyOutDialog(Map<String, dynamic> data) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Early Checkout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are leaving ${data['early_minutes']} minutes early.',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text('Please provide a reason:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., Medical emergency, family matter...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              cameraController.start(); // Resume camera
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.length < 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a detailed reason (min 10 characters)'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);

              final provider = context.read<AttendanceProvider>();
              final result = await provider.submitEarlyOut(
                data['attendance_id'],
                reason,
              );

              if (!mounted) return;

              if (result != null && result['success'] == true) {
                _showSuccessDialog(
                  title: 'Early Checkout Recorded',
                  message: result['message'] ?? 'Early checkout recorded',
                  icon: Icons.logout,
                  color: AppColors.warning,
                  additionalInfo: result['data'] != null 
                      ? 'Hours worked: ${result['data']['hours_worked']} hrs'
                      : null,
                );
              } else {
                _showErrorDialog(result?['message'] ?? 'Failed to record early checkout');
              }
            },
            child: const Text(
              'Submit',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          // Scanning overlay
          CustomPaint(
            painter: ScannerOverlay(),
            child: const SizedBox.expand(),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'Position the QR code within the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_isProcessing) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Upload image button
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _pickImageAndScan,
                icon: const Icon(Icons.upload_file, color: Colors.white),
                label: const Text(
                  'Upload QR Image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for scanner overlay
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final scanAreaSize = size.width * 0.7;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Draw semi-transparent overlay
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(scanRect, const Radius.circular(16)),
          ),
      ),
      paint,
    );

    // Draw corner brackets
    final bracketPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final bracketLength = 30.0;

    // Top-left corner
    canvas.drawLine(Offset(left, top + bracketLength), Offset(left, top), bracketPaint);
    canvas.drawLine(Offset(left, top), Offset(left + bracketLength, top), bracketPaint);

    // Top-right corner
    canvas.drawLine(Offset(left + scanAreaSize - bracketLength, top), Offset(left + scanAreaSize, top), bracketPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top), Offset(left + scanAreaSize, top + bracketLength), bracketPaint);

    // Bottom-left corner
    canvas.drawLine(Offset(left, top + scanAreaSize - bracketLength), Offset(left, top + scanAreaSize), bracketPaint);
    canvas.drawLine(Offset(left, top + scanAreaSize), Offset(left + bracketLength, top + scanAreaSize), bracketPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(left + scanAreaSize - bracketLength, top + scanAreaSize), Offset(left + scanAreaSize, top + scanAreaSize), bracketPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top + scanAreaSize - bracketLength), Offset(left + scanAreaSize, top + scanAreaSize), bracketPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
