// lib/screens/admin/admin_attendance_history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/attendance_model.dart';

class AdminAttendanceHistoryScreen extends StatefulWidget {
  const AdminAttendanceHistoryScreen({super.key});

  @override
  State<AdminAttendanceHistoryScreen> createState() => _AdminAttendanceHistoryScreenState();
}

class _AdminAttendanceHistoryScreenState extends State<AdminAttendanceHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final adminUser = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, adminUser?.profileImageUrl),

            // Content
            Expanded(
              child: Consumer<AdminProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            provider.errorMessage!,
                            style: const TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => provider.fetchAttendance(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final records = provider.attendanceRecords;
                  if (records.isEmpty) {
                    return const Center(
                      child: Text(
                        'No attendance records found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  // Separate today's records from previous
                  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                  final todayRecords = records.where((r) => 
                    DateFormat('yyyy-MM-dd').format(r.date) == today
                  ).toList();
                  final previousRecords = records.where((r) => 
                    DateFormat('yyyy-MM-dd').format(r.date) != today
                  ).toList();

                  return RefreshIndicator(
                    onRefresh: () => provider.fetchAttendance(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Today Section
                          if (todayRecords.isNotEmpty) ...[
                            const Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...todayRecords.map((record) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildEmployeeAttendanceCard(record),
                            )),
                            const SizedBox(height: 24),
                          ],

                          // Previous History Section
                          if (previousRecords.isNotEmpty) ...[
                            const Text(
                              'Previous History',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...previousRecords.take(50).map((record) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildEmployeeAttendanceCard(record),
                            )),
                          ],

                          if (todayRecords.isEmpty && previousRecords.isEmpty)
                            const Center(
                              child: Text(
                                'No attendance records found',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String? profileImageUrl) {
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
              child: profileImageUrl != null && profileImageUrl.isNotEmpty
                  ? Image.network(
                      profileImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar();
                      },
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppColors.accent,
      child: const Icon(
        Icons.person,
        color: AppColors.white,
        size: 24,
      ),
    );
  }

  Widget _buildEmployeeAttendanceCard(AttendanceModel record) {
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
                  record.userName ?? 'Unknown Employee',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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
