// lib/screens/employee/change_role_screen.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ChangeRoleScreen extends StatefulWidget {
  const ChangeRoleScreen({super.key});

  @override
  State<ChangeRoleScreen> createState() => _ChangeRoleScreenState();
}

class _ChangeRoleScreenState extends State<ChangeRoleScreen> {
  String? _selectedRole;
  bool _isLoading = false;

  final List<String> _roles = [
    'Employee',
    'Manager',
    'Supervisor',
    'Team Lead',
    'Department Head',
  ];

  void _handleChange() {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Role updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context);
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
            _buildHeader(context),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Title
                    const Text(
                      'Role',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Role Dropdown
                    _buildRoleDropdown(),

                    const SizedBox(height: 80),

                    // Submit Button
                    _buildSubmitButton(),
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
            'Account & Security',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedRole,
        hint: const Text(
          'Select role',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: AppColors.textSecondary,
        ),
        dropdownColor: AppColors.cardBackground,
        items: _roles.map((String role) {
          return DropdownMenuItem<String>(
            value: role,
            child: Text(
              role,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() {
            _selectedRole = value;
          });
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: SizedBox(
        width: 140,
        height: 45,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleChange,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.buttonDisabled,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
              : const Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
