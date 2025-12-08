// lib/screens/admin/admin_employees_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../models/user_model.dart';
import 'admin_employee_detail_screen.dart';

class AdminEmployeesScreen extends StatefulWidget {
  const AdminEmployeesScreen({super.key});

  @override
  State<AdminEmployeesScreen> createState() => _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends State<AdminEmployeesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _filteredEmployees = [];
  String _searchQuery = '';
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch all employees including inactive ones
      context.read<AdminProvider>().fetchEmployees(activeOnly: false);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterEmployees(String query) {
    final provider = context.read<AdminProvider>();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredEmployees = [];
      } else {
        // Apply search on status-filtered list
        final baseList = _showInactive
            ? provider.employees
            : provider.employees.where((e) => e.isActive).toList();
        _filteredEmployees = baseList
            .where((emp) =>
                emp.fullName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

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
              child: Consumer<AdminProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.employees.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  // Filter by active/inactive status first
                  List<UserModel> statusFilteredEmployees = _showInactive
                      ? provider.employees
                      : provider.employees.where((e) => e.isActive).toList();
                  
                  // Then apply search filter
                  final employees = _searchQuery.isEmpty 
                      ? statusFilteredEmployees
                      : _filteredEmployees;
                  
                  if (employees.isEmpty && _searchQuery.isEmpty && !provider.isLoading) {
                    return Center(
                      child: Text(
                        _showInactive ? 'No inactive employees found' : 'No employees found',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with filter and search
                        Row(
                          children: [
                            const Text(
                              'Employees',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            // Show inactive toggle
                            TextButton.icon(
                              onPressed: () async {
                                setState(() {
                                  _showInactive = !_showInactive;
                                });
                                // Refetch employees with new filter
                                await context.read<AdminProvider>().fetchEmployees(activeOnly: !_showInactive);
                              },
                              icon: Icon(
                                _showInactive ? Icons.visibility_off : Icons.visibility,
                                size: 18,
                                color: _showInactive ? AppColors.error : AppColors.textSecondary,
                              ),
                              label: Text(
                                _showInactive ? 'Hide Inactive' : 'Show Inactive',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _showInactive ? AppColors.error : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                _showSearchDialog();
                              },
                              icon: const Icon(
                                Icons.search,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Employee List
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () => provider.fetchEmployees(),
                            child: ListView.separated(
                              itemCount: employees.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final employee = employees[index];
                                return _buildEmployeeItem(
                                  name: employee.fullName,
                                  isActive: employee.isActive,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AdminEmployeeDetailScreen(
                                          employeeId: employee.id,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
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
        ],
      ),
    );
  }

  Widget _buildEmployeeItem({
    required String name,
    required VoidCallback onTap,
    bool isActive = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.cardBackground : AppColors.cardBackground.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
          border: isActive ? null : Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                        decoration: isActive ? null : TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                  if (!isActive)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.error, width: 1),
                      ),
                      child: const Text(
                        'INACTIVE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Employee'),
          content: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Enter employee name',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _filterEmployees,
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _filteredEmployees = [];
                });
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
