// lib/screens/admin/admin_main_layout.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notification_provider.dart';
import 'admin_home_screen.dart';
import 'admin_employees_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_qr_scanner_screen.dart';

class AdminMainLayout extends StatefulWidget {
  const AdminMainLayout({super.key});

  @override
  State<AdminMainLayout> createState() => _AdminMainLayoutState();
}

class _AdminMainLayoutState extends State<AdminMainLayout> {
  int _currentIndex = 0;
  final ImagePicker _picker = ImagePicker();

  final List<Widget> _screens = [
    const AdminHomeScreen(),
    const AdminEmployeesScreen(),
    const AdminNotificationsScreen(),
    const AdminProfileScreen(),
  ];

  // Check if camera is supported on this platform
  bool get _isCameraSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  void initState() {
    super.initState();
    // Fetch notifications to get unread count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCenterQRButton() {
    return GestureDetector(
      onTap: _showCameraOptions,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          border: Border.all(
            color: AppColors.secondary,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.qr_code_scanner,
          color: AppColors.accent,
          size: 26,
        ),
      ),
    );
  }

  void _showCameraOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Scan QR Code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Open Camera Button
              _buildOptionButton(
                icon: Icons.camera_alt_outlined,
                title: 'Open Camera',
                subtitle: _isCameraSupported 
                    ? 'Scan QR code using camera'
                    : 'Camera not available on this device',
                onTap: () {
                  Navigator.pop(context);
                  _openCamera();
                },
                enabled: _isCameraSupported,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.divider,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppColors.accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCamera() {
    if (!_isCameraSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera is not supported on this device. Please use a mobile device.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminQRScannerScreen(),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null && mounted) {
        // Process the selected image for QR code
        _showImageSelectedDialog(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageSelectedDialog(XFile image) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Image Selected'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.background,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(image.path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.image,
                          size: 50,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                image.name,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Process QR from image
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Processing QR code from image...'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.accent,
              ),
              child: const Text('Scan QR'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Navigation items row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Home',
                    index: 0,
                  ),
                  _buildNavItem(
                    icon: Icons.groups_outlined,
                    activeIcon: Icons.groups,
                    label: 'Employees',
                    index: 1,
                  ),
                  // Space for center button
                  const SizedBox(width: 56),
                  Consumer<NotificationProvider>(
                    builder: (context, notifProvider, _) {
                      return _buildNavItemWithBadge(
                        icon: Icons.notifications_outlined,
                        activeIcon: Icons.notifications,
                        label: 'Notifications',
                        index: 2,
                        showBadge: notifProvider.hasUnread,
                        badgeCount: notifProvider.unreadCount,
                      );
                    },
                  ),
                  _buildNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Account',
                    index: 3,
                  ),
                ],
              ),
              // Center QR button - positioned on top of the nav bar
              Positioned(
                left: 0,
                right: 0,
                top: -20,
                child: Center(child: _buildCenterQRButton()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.secondary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? AppColors.secondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    final isActive = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? AppColors.secondary : AppColors.textSecondary,
                  size: 24,
                ),
                if (showBadge && badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? AppColors.secondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
