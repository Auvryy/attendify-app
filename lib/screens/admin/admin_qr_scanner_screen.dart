// lib/screens/admin/admin_qr_scanner_screen.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/attendance_provider.dart';

class AdminQRScannerScreen extends StatefulWidget {
  const AdminQRScannerScreen({super.key});

  @override
  State<AdminQRScannerScreen> createState() => _AdminQRScannerScreenState();
}

class _AdminQRScannerScreenState extends State<AdminQRScannerScreen> {
  MobileScannerController? _scannerController;
  bool _isTorchOn = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isProcessing = false;
  bool _scanPaused = false;
  final ImagePicker _imagePicker = ImagePicker();

  // Check if camera is supported
  bool get _isCameraSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  void initState() {
    super.initState();
    if (_isCameraSupported) {
      _initializeScanner();
    } else {
      _hasError = true;
      _errorMessage = 'Camera scanning is only available on mobile devices (Android/iOS).';
    }
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _switchCamera() async {
    if (_scannerController != null) {
      await _scannerController!.switchCamera();
    }
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_scanPaused || _isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String qrCode = barcodes.first.rawValue!;
      _processQRCode(qrCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.accent,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _hasError ? _buildErrorView() : _buildScannerView(),
            ),
            _buildBottomControls(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Back Button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const Spacer(),

          // Title
          const Text(
            'Scan QR Code',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),

          // Torch Button (only show if camera is supported)
          if (_isCameraSupported)
            InkWell(
              onTap: () {
                setState(() {
                  _isTorchOn = !_isTorchOn;
                });
                // Toggle torch would go here
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: _isTorchOn ? AppColors.primary : Colors.white,
                  size: 24,
                ),
              ),
            )
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Camera Not Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 30),
            // Demo scan button
            ElevatedButton(
              onPressed: () {
                _showDemoScanResult();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Demo: Simulate Scan',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    if (_scannerController == null) {
      return _buildErrorView();
    }

    return Stack(
      children: [
        // Camera preview
        MobileScanner(
          controller: _scannerController!,
          onDetect: _handleBarcode,
          errorBuilder: (context, error, child) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error,
                    color: AppColors.error,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Camera error: ${error.errorCode}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
        // Overlay with scanner frame
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 3,
                  ),
                ),
                child: Stack(
                  children: [
                    // Corner decorations
                    Positioned(
                      top: 0,
                      left: 0,
                      child: _buildCorner(true, true),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _buildCorner(true, false),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: _buildCorner(false, true),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: _buildCorner(false, false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isProcessing ? 'Processing...' : 'Position QR code within the frame',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Processing indicator
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        // Upload QR button positioned at bottom
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: _pickImageAndScan,
              icon: const Icon(Icons.photo_library),
              label: const Text('Upload QR Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: AppColors.primary, width: 4)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: AppColors.primary, width: 4)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: AppColors.primary, width: 4)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: AppColors.primary, width: 4)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Column(
      children: [
        // Manual entry button (for fallback)
        ElevatedButton.icon(
          onPressed: () => _showManualEntryDialog(),
          icon: const Icon(Icons.keyboard),
          label: const Text('Enter Code Manually'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Switch Camera Button
        if (_isCameraSupported && _scannerController != null)
          InkWell(
            onTap: _switchCamera,
            borderRadius: BorderRadius.circular(25),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cameraswitch,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Switch Camera',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showManualEntryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter QR Code'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter employee QR code',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (controller.text.isNotEmpty) {
                _processQRCode(controller.text);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showDemoScanResult() {
    // Simulate QR code scan with demo data
    _processQRCode('demo-qr-code-employee-001');
  }

  Future<void> _processQRCode(String qrCode) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      _scanPaused = true;
    });
    
    // Pause the scanner
    _scannerController?.stop();
    
    final provider = context.read<AttendanceProvider>();
    final result = await provider.scanAttendance(qrCode);
    
    if (!mounted) return;
    
    setState(() => _isProcessing = false);
    
    if (result != null && result['success'] == true) {
      _handleSuccess(result);
    } else {
      _handleError(result ?? {'message': 'Scan failed'});
    }
  }

  void _handleSuccess(Map<String, dynamic> result) {
    final action = result['data']?['action'];
    final timeStr = result['message'];
    final status = result['data']?['status'];
    final lateMinutes = result['data']?['late_minutes'] ?? 0;
    final hoursWorked = result['data']?['hours_worked'];
    final employeeName = result['data']?['employee_name'] ?? 'Employee';

    if (action == 'TIME_IN') {
      String displayTime = timeStr;
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          displayTime = '${parts[1].trim()}:${parts.length > 2 ? parts[2].trim() : ''}';
        }
      }

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
      String displayTime = timeStr;
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          displayTime = '${parts[1].trim()}:${parts.length > 2 ? parts[2].trim() : ''}';
        }
      }

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
    final provider = context.read<AttendanceProvider>();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Scan Failed',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            result['message'] ?? provider.errorMessage ?? 'Failed to record attendance. Please try again.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _resumeScanning();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    required String additionalInfo,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Colored header with icon
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Attendance Recorded',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Employee name
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'has been recorded successfully',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Time display with status badge
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: color,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  message,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                additionalInfo,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _resumeScanning();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Scan Another',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _pickImageAndScan() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Scanning QR Code...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we process the image',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      setState(() => _isProcessing = true);

      // Stop camera while processing
      _scannerController?.stop();

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      if (!mounted) return;

      final provider = context.read<AttendanceProvider>();
      final result = await provider.scanAttendanceFromImage(base64Image);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (!mounted) return;

      setState(() => _isProcessing = false);

      if (result != null && result['success'] == true) {
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('QR Code detected successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        _handleSuccess(result);
      } else {
        // Show error feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result?['message'] ?? 'No QR code found in image',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
        _handleError(result ?? {'message': 'Failed to scan QR from image'});
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && _isProcessing) Navigator.pop(context);
      
      setState(() => _isProcessing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to process image: $e',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
        _handleError({'message': 'Failed to process image: $e'});
      }
    }
  }

  void _resumeScanning() {
    setState(() {
      _scanPaused = false;
    });
    _scannerController?.start();
  }
}
