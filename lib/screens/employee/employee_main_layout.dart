// lib/screens/employee/employee_main_layout.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notification_provider.dart';
import 'employee_home_screen.dart';
import 'employee_notifications_screen.dart';
import 'employee_profile_screen.dart';

class EmployeeMainLayout extends StatefulWidget {
  const EmployeeMainLayout({super.key});

  @override
  State<EmployeeMainLayout> createState() => _EmployeeMainLayoutState();
}

class _EmployeeMainLayoutState extends State<EmployeeMainLayout> {
  int _currentIndex = 0;

  // List of screens for each tab
  final List<Widget> _screens = [
    const EmployeeHomeScreen(),
    const EmployeeNotificationsScreen(),
    const EmployeeProfileScreen(),
  ];

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
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
        currentIndex: _currentIndex,
        elevation: 0,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Consumer<NotificationProvider>(
              builder: (context, notifProvider, _) {
                return Badge(
                  isLabelVisible: notifProvider.hasUnread,
                  label: Text(
                    notifProvider.unreadCount > 99 ? '99+' : '${notifProvider.unreadCount}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  child: const Icon(Icons.notifications),
                );
              },
            ),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
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
}
