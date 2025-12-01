// lib/screens/admin/admin_upload_qr_screen.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AdminUploadQRScreen extends StatefulWidget {
  const AdminUploadQRScreen({super.key});

  @override
  State<AdminUploadQRScreen> createState() => _AdminUploadQRScreenState();
}

class _AdminUploadQRScreenState extends State<AdminUploadQRScreen> {
  bool _isUploaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Spacer(),

                    // QR Upload Area
                    GestureDetector(
                      onTap: _handleUpload,
                      child: Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _isUploaded
                            ? const Center(
                                child: Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                  size: 80,
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.qr_code_2,
                                  color: AppColors.white,
                                  size: 100,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Upload Button
                    InkWell(
                      onTap: _handleUpload,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.textSecondary,
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.upload_outlined,
                              color: AppColors.textSecondary,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload QR',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // LSPU Logo
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/pila-logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.school,
                    color: AppColors.accent,
                    size: 30,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 15),

          // Title
          const Text(
            'ATTENDIFY',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),

          // Profile Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/profile-avatar.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.accent,
                    child: const Icon(
                      Icons.person,
                      color: AppColors.white,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleUpload() {
    // TODO: Implement actual image picker
    setState(() {
      _isUploaded = !_isUploaded;
    });

    if (_isUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR Code uploaded successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
