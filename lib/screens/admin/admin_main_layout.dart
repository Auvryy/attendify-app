// lib/screens/admin/admin_main_layout.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'admin_home_screen.dart';
import 'admin_employees_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_profile_screen.dart';

class AdminMainLayout extends StatefulWidget {
  const AdminMainLayout({super.key});

  @override
  State<AdminMainLayout> createState() => _AdminMainLayoutState();
}

class _AdminMainLayoutState extends State<AdminMainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminHomeScreen(),
    const AdminEmployeesScreen(),
    const AdminNotificationsScreen(),
    const AdminProfileScreen(),
  ];

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
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.textSecondary,
        currentIndex: _currentIndex,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _buildEmployeesIcon(false),
            activeIcon: _buildEmployeesIcon(true),
            label: 'Employees',
          ),
          BottomNavigationBarItem(
            icon: _buildNotificationIcon(false),
            activeIcon: _buildNotificationIcon(true),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildEmployeesIcon(bool isActive) {
    return Icon(
      Icons.groups_outlined,
      color: isActive ? AppColors.secondary : AppColors.textSecondary,
    );
  }

  Widget _buildNotificationIcon(bool isActive) {
    return Stack(
      children: [
        Icon(
          isActive ? Icons.notifications : Icons.notifications_outlined,
          color: isActive ? AppColors.secondary : AppColors.textSecondary,
        ),
        // Notification badge
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
