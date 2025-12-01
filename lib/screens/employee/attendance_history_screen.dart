// lib/screens/employee/attendance_history_screen.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Attendance List
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // This Week Section
                    const Text(
                      'This Week',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // This week attendance records
                    _buildAttendanceCard(
                      date: 'September 29, 2025',
                      timeIn: null,
                      timeOut: null,
                      status: AttendanceStatus.onLeave,
                    ),
                    const SizedBox(height: 12),
                    _buildAttendanceCard(
                      date: 'September 28, 2025',
                      timeIn: '8:30 AM',
                      timeOut: '5:01 PM',
                      status: AttendanceStatus.late,
                    ),
                    const SizedBox(height: 12),
                    _buildAttendanceCard(
                      date: 'September 27, 2025',
                      timeIn: '8:00 AM',
                      timeOut: '5:05 PM',
                      status: AttendanceStatus.onTime,
                    ),
                    const SizedBox(height: 12),
                    _buildAttendanceCard(
                      date: 'September 26, 2025',
                      timeIn: '8:00 AM',
                      timeOut: '5:05 PM',
                      status: AttendanceStatus.onTime,
                    ),

                    const SizedBox(height: 25),

                    // Previous Weeks Section
                    const Text(
                      'Previous Weeks',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildAttendanceCard(
                      date: 'September 15, 2025',
                      timeIn: null,
                      timeOut: null,
                      status: AttendanceStatus.onLeave,
                    ),
                    const SizedBox(height: 12),
                    _buildAttendanceCard(
                      date: 'September 10, 2025',
                      timeIn: '8:00 AM',
                      timeOut: '5:00 PM',
                      status: AttendanceStatus.onTime,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
          // Back Button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.accent,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Title
          const Text(
            'Attendance History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
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

  Widget _buildAttendanceCard({
    required String date,
    String? timeIn,
    String? timeOut,
    required AttendanceStatus status,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date and Time Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Time In
                    _buildTimeColumn(
                      label: 'Time in',
                      value: timeIn ?? '--',
                    ),
                    const SizedBox(width: 24),
                    // Time Out
                    _buildTimeColumn(
                      label: 'Time out',
                      value: timeOut ?? '--',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status Badge
          _buildStatusBadge(status),
        ],
      ),
    );
  }

  Widget _buildTimeColumn({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(AttendanceStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case AttendanceStatus.onTime:
        backgroundColor = const Color(0xFF4CAF50);
        textColor = AppColors.white;
        text = 'On Time';
        break;
      case AttendanceStatus.late:
        backgroundColor = const Color(0xFFF44336);
        textColor = AppColors.white;
        text = 'Late';
        break;
      case AttendanceStatus.onLeave:
        backgroundColor = AppColors.textSecondary;
        textColor = AppColors.white;
        text = 'On Leave';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

enum AttendanceStatus {
  onTime,
  late,
  onLeave,
}
