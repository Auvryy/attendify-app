// lib/screens/admin/admin_employee_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../models/user_model.dart';
import '../../models/attendance_model.dart';

class AdminEmployeeDetailScreen extends StatefulWidget {
  final String employeeId;

  const AdminEmployeeDetailScreen({super.key, required this.employeeId});

  @override
  State<AdminEmployeeDetailScreen> createState() =>
      _AdminEmployeeDetailScreenState();
}

class _AdminEmployeeDetailScreenState extends State<AdminEmployeeDetailScreen> {
  UserModel? _employee;
  List<AttendanceModel> _attendanceHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Defer loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEmployeeData();
    });
  }

  Future<void> _loadEmployeeData() async {
    final adminProvider = context.read<AdminProvider>();

    // Fetch employee details
    final employee = await adminProvider.getEmployeeDetail(widget.employeeId);

    // Fetch attendance for this employee (we'll filter from overall attendance)
    await adminProvider.fetchAttendance();

    if (mounted) {
      setState(() {
        _employee = employee;
        // Filter attendance records for this employee
        _attendanceHistory = adminProvider.attendanceRecords
            .where((record) => record.userId == widget.employeeId)
            .toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDeleteEmployee() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text(
          'Are you sure you want to deactivate ${_employee?.fullName ?? 'this employee'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true && _employee != null) {
      setState(() => _isLoading = true);

      final adminProvider = context.read<AdminProvider>();
      final success = await adminProvider.updateEmployeeStatus(
        _employee!.id,
        false,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Employee has been deactivated'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                adminProvider.errorMessage ?? 'Failed to deactivate employee',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showEditDialog(UserModel employee) {
    final positionController = TextEditingController(
      text: employee.position ?? '',
    );
    final addressController = TextEditingController(
      text: employee.fullAddress ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Employee'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employee.fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: positionController,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  hintText: 'e.g. Barangay Secretary',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Full Address',
                  hintText: 'Enter full address',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              setState(() => _isLoading = true);

              final adminProvider = context.read<AdminProvider>();
              final success = await adminProvider.updateEmployee(
                id: employee.id,
                position: positionController.text.trim().isNotEmpty
                    ? positionController.text.trim()
                    : null,
                fullAddress: addressController.text.trim().isNotEmpty
                    ? addressController.text.trim()
                    : null,
              );

              if (mounted) {
                if (success) {
                  // Refresh employee data
                  await _loadEmployeeData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Employee updated successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        adminProvider.errorMessage ??
                            'Failed to update employee',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      );
    }

    if (_employee == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const Expanded(
                child: Center(
                  child: Text(
                    'Employee not found',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Separate today's attendance from previous
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final todayAttendance = _attendanceHistory
        .where((a) => DateFormat('yyyy-MM-dd').format(a.date) == today)
        .toList();
    final previousAttendance = _attendanceHistory
        .where((a) => DateFormat('yyyy-MM-dd').format(a.date) != today)
        .toList();

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
                    _buildEmployeeProfileCard(_employee!),

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
                    if (todayAttendance.isNotEmpty) ...[
                      const Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...todayAttendance.map(
                        (record) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildAttendanceCard(record),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Previous History Section
                    if (previousAttendance.isNotEmpty) ...[
                      const Text(
                        'Previous History',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...previousAttendance
                          .take(10)
                          .map(
                            (record) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildAttendanceCard(record),
                            ),
                          ),
                    ],

                    if (todayAttendance.isEmpty && previousAttendance.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: const Center(
                          child: Text(
                            'No attendance records found',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
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
        ],
      ),
    );
  }

  Widget _buildEmployeeProfileCard(UserModel employee) {
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
                child: ClipOval(
                  child:
                      employee.profileImageUrl != null &&
                          employee.profileImageUrl!.isNotEmpty
                      ? Image.network(
                          employee.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              color: AppColors.white,
                              size: 35,
                            );
                          },
                        )
                      : const Icon(
                          Icons.person,
                          color: AppColors.white,
                          size: 35,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Name and Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee.role.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Edit button
              IconButton(
                onPressed: () => _showEditDialog(_employee!),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.secondary,
                ),
              ),
              // Delete button
              IconButton(
                onPressed: _handleDeleteEmployee,
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
            value: employee.lastName,
            secondLabel: 'Middle Name',
            secondValue: employee.middleName,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            label: 'First Name',
            value: employee.firstName,
            secondLabel: 'Role',
            secondValue: employee.role,
          ),
          const SizedBox(height: 12),
          _buildSingleInfoRow(
            label: 'Mobile Number',
            value: employee.phone.isNotEmpty ? employee.phone : 'Not set',
          ),
          const SizedBox(height: 12),
          _buildSingleInfoRow(label: 'Email Address', value: employee.email),
          const SizedBox(height: 12),
          _buildSingleInfoRow(
            label: 'Employee ID',
            value: employee.employeeId ?? 'Not set',
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

  Widget _buildSingleInfoRow({required String label, required String value}) {
    return _buildInfoField(label: label, value: value);
  }

  Widget _buildInfoField({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider, width: 1),
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

  Widget _buildAttendanceCard(AttendanceModel record) {
    final dateStr = DateFormat('MMMM d, yyyy').format(record.date);
    final timeInStr = record.timeIn != null
        ? DateFormat('h:mm a').format(record.timeIn!)
        : 'N/A';
    final timeOutStr = record.timeOut != null
        ? DateFormat('h:mm a').format(record.timeOut!)
        : 'N/A';

    // Determine status display
    String statusText;
    Color statusColor;
    switch (record.status.toLowerCase()) {
      case 'on_time':
        statusText = 'On Time';
        statusColor = AppColors.success;
        break;
      case 'late':
        statusText = 'Late';
        statusColor = AppColors.error;
        break;
      case 'absent':
        statusText = 'Absent';
        statusColor = AppColors.error;
        break;
      case 'on_leave':
        statusText = 'On Leave';
        statusColor = AppColors.warning;
        break;
      default:
        statusText = record.status;
        statusColor = AppColors.textSecondary;
    }

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
                  dateStr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildTimeColumn('Time in', timeInStr),
                    const SizedBox(width: 20),
                    _buildTimeColumn('Time out', timeOutStr),
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
              statusText,
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
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
