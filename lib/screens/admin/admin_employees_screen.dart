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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchEmployees();
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
        _filteredEmployees = provider.employees;
      } else {
        _filteredEmployees = provider.employees
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
                  
                  final employees = _searchQuery.isEmpty 
                      ? provider.employees 
                      : _filteredEmployees;
                  
                  if (employees.isEmpty && _searchQuery.isEmpty && !provider.isLoading) {
                    return const Center(
                      child: Text(
                        'No employees found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with search
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
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
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
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
                _searchController.clear();
                _filterEmployees('');
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
