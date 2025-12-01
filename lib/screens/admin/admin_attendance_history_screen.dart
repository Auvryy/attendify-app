// lib/screens/admin/admin_attendance_history_screen.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AdminAttendanceHistoryScreen extends StatelessWidget {
  const AdminAttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today Section
                    const Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildEmployeeAttendanceCard(
                      name: 'Amador, Roberto E.',
                      date: 'September 29, 2025',
                      timeIn: '8:35 AM',
                      timeOut: '5:02 PM',
                      status: 'Late',
                    ),
                    const SizedBox(height: 10),
                    _buildEmployeeAttendanceCard(
                      name: 'Lorenzo, Juliane Z.',
                      date: 'September 29, 2025',
                      timeIn: '8:00 AM',
                      timeOut: '5:02 PM',
                      status: 'On Time',
                    ),
                    const SizedBox(height: 10),
                    _buildEmployeeAttendanceCard(
                      name: 'Ramilo, Allianah D.',
                      date: 'September 29, 2025',
                      timeIn: '7:55 AM',
                      timeOut: '5:02 PM',
                      status: 'On Time',
                    ),
                    const SizedBox(height: 10),
                    _buildEmployeeAttendanceCard(
                      name: 'Viterbo, Ecer S.',
                      date: 'September 29, 2025',
                      timeIn: '7:55 AM',
                      timeOut: '5:02 PM',
                      status: 'On Time',
                    ),

                    const SizedBox(height: 24),

                    // Previous History Section
                    const Text(
                      'Previous History',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildEmployeeAttendanceCard(
                      name: 'Ramilo, Allianah D.',
                      date: 'September 28, 2025',
                      timeIn: '7:55 AM',
                      timeOut: '5:02 PM',
                      status: 'On Time',
                    ),
                    const SizedBox(height: 10),
                    _buildEmployeeAttendanceCard(
                      name: 'Viterbo, Ecer S.',
                      date: 'September 28, 2025',
                      timeIn: '7:55 AM',
                      timeOut: '5:02 PM',
                      status: 'On Time',
                    ),
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

  Widget _buildEmployeeAttendanceCard({
    required String name,
    required String date,
    required String timeIn,
    required String timeOut,
    required String status,
  }) {
    Color statusColor = status == 'On Time' ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildTimeColumn('Time in', timeIn),
                    const SizedBox(width: 20),
                    _buildTimeColumn('Time out', timeOut),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
