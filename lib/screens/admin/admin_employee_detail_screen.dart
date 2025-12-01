// lib/screens/admin/admin_employee_detail_screen.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AdminEmployeeDetailScreen extends StatelessWidget {
  final String employeeName;

  const AdminEmployeeDetailScreen({
    super.key,
    required this.employeeName,
  });

  @override
  Widget build(BuildContext context) {
    // Parse name parts
    final nameParts = employeeName.split(', ');
    final surname = nameParts.isNotEmpty ? nameParts[0] : '';
    final firstMiddle = nameParts.length > 1 ? nameParts[1].split(' ') : ['', ''];
    final firstName = firstMiddle.isNotEmpty ? firstMiddle[0] : '';
    final middleName = firstMiddle.length > 1 ? firstMiddle.sublist(1).join(' ') : '';

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
                    // Employee Profile Card
                    _buildEmployeeProfileCard(surname, firstName, middleName),

                    const SizedBox(height: 30),

                    // Attendance History Section
                    const Text(
                      'Attendance History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Today Section
                    const Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildAttendanceCard(
                      date: 'September 29, 2025',
                      timeIn: '8:00 AM',
                      timeOut: '5:02 PM',
                      status: 'On Time',
                    ),

                    const SizedBox(height: 20),

                    // Previous History Section
                    const Text(
                      'Previous History',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildAttendanceCard(
                      date: 'September 29, 2025',
                      timeIn: '8:00 AM',
                      timeOut: '5:02 PM',
                      status: 'On Time',
                    ),
                    const SizedBox(height: 10),
                    _buildAttendanceCard(
                      date: 'September 29, 2025',
                      timeIn: '8:00 AM',
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
            'Employees',
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

  Widget _buildEmployeeProfileCard(String surname, String firstName, String middleName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile row with avatar and delete button
          Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.divider,
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.white,
                  size: 35,
                ),
              ),
              const SizedBox(width: 16),
              // Name and Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employeeName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Role',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                onPressed: () {
                  // Handle delete employee
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Info Fields
          _buildInfoRow(
            label: 'Surname',
            value: surname,
            secondLabel: 'Middle Name',
            secondValue: middleName,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            label: 'First Name',
            value: firstName,
            secondLabel: 'Role',
            secondValue: 'Employee',
          ),
          const SizedBox(height: 12),
          _buildSingleInfoRow(
            label: 'Mobile Number',
            value: '09876543219',
          ),
          const SizedBox(height: 12),
          _buildSingleInfoRow(
            label: 'Email Address',
            value: 'amadorroberto75@gmail.com',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required String secondLabel,
    required String secondValue,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoField(label: label, value: value),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoField(label: secondLabel, value: secondValue),
        ),
      ],
    );
  }

  Widget _buildSingleInfoRow({
    required String label,
    required String value,
  }) {
    return _buildInfoField(label: label, value: value);
  }

  Widget _buildInfoField({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.edit_outlined,
            color: AppColors.textSecondary,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard({
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
                  date,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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
