import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import 'login_screen.dart'; // import login
import 'employee/employee_main_layout.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _roleController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedBarangay;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final _barangays = const ['Barangay Masico', 'Barangay Pansol', 'Barangay San Miguel'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _roleController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

void _handleSignUp() {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  // TODO: implement sign up logic with API call

  // For debugging: Navigate to Employee Main Layout after 2 seconds
  Future.delayed(const Duration(seconds: 2), () {
    if (mounted) {
      setState(() => _isLoading = false);
      
      // Navigate to Employee Main Layout (with bottom navigation)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const EmployeeMainLayout(),
        ),
      );
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // white body
      body: SafeArea(
        child: Column(
          children: [
            // Yellow header with logo + title + avatar-like placeholder + navy bar
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Logo (left)
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accent,
                            width: 1.5,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/pila-logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'ATTENDIFY',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      // Right-side placeholder avatar (you can replace later)
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.textPrimary,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Container(
              height: 8,
              color: AppColors.accent,
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sign up',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      CustomTextField(
                        label: 'Surname, First Name Middle Name',
                        controller: _fullNameController,
                        prefixIcon: Icons.person_outline,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Please enter your full name'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        label: 'Mobile Number',
                        controller: _mobileController,
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Please enter your mobile number'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Barangay dropdown
                      const Text(
                        'Barangay',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedBarangay,
                        items: _barangays
                            .map(
                              (b) => DropdownMenuItem<String>(
                                value: b,
                                child: Text(b),
                              ),
                            )
                            .toList(),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.divider,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.secondary,
                              width: 2,
                            ),
                          ),
                        ),
                        hint: const Text(
                          'Select Barangay',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedBarangay = value;
                          });
                        },
                        validator: (value) => value == null
                            ? 'Please select your barangay'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        label: 'Role',
                        controller: _roleController,
                        prefixIcon: Icons.badge_outlined,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Please enter your role'
                            : null,
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Security',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      CustomTextField(
                        label: 'Create a strong password',
                        controller: _passwordController,
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(
                                () => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please create a password';
                          }
                          if (v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        label: 'Retype password',
                        controller: _confirmPasswordController,
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirmPassword =
                                !_obscureConfirmPassword);
                          },
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please retype your password';
                          }
                          if (v != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        label: 'Email Address',
                        controller: _emailController,
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Please enter your email'
                            : null,
                      ),

                      const SizedBox(height: 32),

                      // Full-width button like login
                      CustomButton(
                        text: 'Create account',
                        onPressed: _handleSignUp,
                        isLoading: _isLoading,
                        backgroundColor: AppColors.buttonPrimary,
                        textColor: AppColors.black,
                      ),
                      const SizedBox(height: 16),

                      // Bottom "Already have an account? Log in"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Log in',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
