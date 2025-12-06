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
    final firstNameController = TextEditingController(text: employee.firstName);
    final lastNameController = TextEditingController(text: employee.lastName);
    final middleNameController = TextEditingController(
      text: employee.middleName,
    );
    final positionController = TextEditingController(
      text: employee.position ?? '',
    );
    final addressController = TextEditingController(
      text: employee.fullAddress ?? '',
    );
    final phoneController = TextEditingController(text: employee.phone);
    // Parse existing shift times or use defaults
    TimeOfDay shiftStartTime = _parseTimeString(employee.shiftStartTime) ?? const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay shiftEndTime = _parseTimeString(employee.shiftEndTime) ?? const TimeOfDay(hour: 17, minute: 0);

    // Capture the parent context before showing dialog
    final parentContext = context;

    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (statefulContext, setDialogState) => AlertDialog(
          title: const Text('Edit Employee'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: middleNameController,
                  decoration: const InputDecoration(
                    labelText: 'Middle Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: positionController,
                  decoration: const InputDecoration(
                    labelText: 'Position',
                    hintText: 'e.g. Barangay Secretary',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Full Address',
                    hintText: 'Enter full address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // Shift Start Time Picker
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: parentContext,
                      initialTime: shiftStartTime,
                      builder: (builderContext, child) {
                        return MediaQuery(
                          data: MediaQuery.of(builderContext).copyWith(alwaysUse24HourFormat: false),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null && mounted) {
                      setDialogState(() {
                        shiftStartTime = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Shift Start Time *',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${shiftStartTime.hourOfPeriod == 0 ? 12 : shiftStartTime.hourOfPeriod}:${shiftStartTime.minute.toString().padLeft(2, '0')} ${shiftStartTime.period == DayPeriod.am ? 'AM' : 'PM'}',
                                style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Shift End Time Picker
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: parentContext,
                      initialTime: shiftEndTime,
                      builder: (builderContext, child) {
                        return MediaQuery(
                          data: MediaQuery.of(builderContext).copyWith(alwaysUse24HourFormat: false),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null && mounted) {
                      setDialogState(() {
                        shiftEndTime = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Shift End Time *',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${shiftEndTime.hourOfPeriod == 0 ? 12 : shiftEndTime.hourOfPeriod}:${shiftEndTime.minute.toString().padLeft(2, '0')} ${shiftEndTime.period == DayPeriod.am ? 'AM' : 'PM'}',
                                style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                // Validate required fields
                if (firstNameController.text.trim().isEmpty ||
                    lastNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('First name and last name are required'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                // Close dialog first
                Navigator.pop(dialogContext);

                // Now safely use the parent context
                if (!mounted) return;

                setState(() => _isLoading = true);

                final adminProvider = parentContext.read<AdminProvider>();
                final success = await adminProvider.updateEmployee(
                  id: employee.id,
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  middleName: middleNameController.text.trim().isNotEmpty
                      ? middleNameController.text.trim()
                      : null,
                  phone: phoneController.text.trim().isNotEmpty
                      ? phoneController.text.trim()
                      : null,
                  position: positionController.text.trim().isNotEmpty
                      ? positionController.text.trim()
                      : null,
                  fullAddress: addressController.text.trim().isNotEmpty
                      ? addressController.text.trim()
                      : null,
                  shiftStartTime: _formatTimeTo24Hour(shiftStartTime),
                  shiftEndTime: _formatTimeTo24Hour(shiftEndTime),
                );

                if (!mounted) return;

                if (success) {
                  // Refresh employee data
                  await _loadEmployeeData();
                  if (mounted) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(
                        content: Text('Employee updated successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } else {
                  setState(() => _isLoading = false);
                  if (mounted) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
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
          const SizedBox(height: 12),
          _buildInfoRow(
            label: 'Shift Start',
            value: _formatTimeDisplay(employee.shiftStartTime),
            secondLabel: 'Shift End',
            secondValue: _formatTimeDisplay(employee.shiftEndTime),
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

  // Helper function to parse time string (HH:MM:SS) to TimeOfDay
  TimeOfDay? _parseTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      // Invalid format, return null
    }
    return null;
  }

  // Helper function to format TimeOfDay to 24-hour string (HH:MM:SS)
  String _formatTimeTo24Hour(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  // Helper function to display time in AM/PM format
  String _formatTimeDisplay(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'Not set';
    final time = _parseTimeString(timeStr);
    if (time == null) return 'Not set';
    
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
