// lib/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/logo_widget.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _apiService = ApiService();

  // Controllers
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Form keys
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // State
  int _currentStep = 0; // 0: email, 1: OTP, 2: new password
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _email;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_emailFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await _apiService.forgotPassword(
          _emailController.text.trim(),
        );

        if (mounted) {
          setState(() => _isLoading = false);

          if (response['success'] == true) {
            _email = _emailController.text.trim();
            setState(() => _currentStep = 1);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP sent to your email'),
                backgroundColor: AppColors.success,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['message'] ?? 'Failed to send OTP'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Network error. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await _apiService.verifyPasswordOtp(
          _email!,
          _otpController.text.trim(),
        );

        if (mounted) {
          setState(() => _isLoading = false);

          if (response['success'] == true) {
            setState(() => _currentStep = 2);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP verified. Please set your new password.'),
                backgroundColor: AppColors.success,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['message'] ?? 'Invalid OTP'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Network error. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_passwordFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await _apiService.resetPassword(
          _email!,
          _newPasswordController.text,
        );

        if (mounted) {
          setState(() => _isLoading = false);

          if (response['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Password reset successful! Please login with your new password.',
                ),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  response['message'] ?? 'Failed to reset password',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Network error. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Header section
            Column(
              children: [
                // Yellow Header with back button
                Container(
                  height: 115,
                  width: double.infinity,
                  color: AppColors.primary,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12.0, left: 8),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.accent,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                // Navy bar below yellow
                Container(
                  height: 14,
                  width: double.infinity,
                  color: AppColors.accent,
                ),
                // Space to allow logo overlap
                const SizedBox(height: 70),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          // Title
                          const Text(
                            'FORGOT PASSWORD',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _getStepDescription(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Step content
                          _buildCurrentStep(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Positioned LOGO
            Positioned(
              top: 55,
              left: 0,
              right: 0,
              child: Center(child: LogoWidget(size: 120)),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case 0:
        return 'Enter your email address and we\'ll send you a verification code.';
      case 1:
        return 'Enter the 6-digit code sent to $_email';
      case 2:
        return 'Create a new password for your account.';
      default:
        return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildOtpStep();
      case 2:
        return _buildPasswordStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        children: [
          CustomTextField(
            label: 'Email Address',
            controller: _emailController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          CustomButton(
            text: 'Send Code',
            onPressed: _sendOtp,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Back to Login',
              style: TextStyle(
                color: AppColors.textPrimary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return Form(
      key: _otpFormKey,
      child: Column(
        children: [
          CustomTextField(
            label: 'Verification Code',
            controller: _otpController,
            prefixIcon: Icons.lock_clock_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the verification code';
              }
              if (value.length != 6) {
                return 'Code must be 6 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          CustomButton(
            text: 'Verify Code',
            onPressed: _verifyOtp,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Didn\'t receive the code? ',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              TextButton(
                onPressed: _isLoading ? null : _sendOtp,
                child: const Text(
                  'Resend',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () => setState(() => _currentStep = 0),
            child: const Text(
              'Change email',
              style: TextStyle(
                color: AppColors.textPrimary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        children: [
          CustomTextField(
            label: 'New Password',
            controller: _newPasswordController,
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
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a new password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Confirm Password',
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
                setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                );
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          CustomButton(
            text: 'Reset Password',
            onPressed: _resetPassword,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
