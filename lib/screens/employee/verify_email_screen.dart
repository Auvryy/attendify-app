// lib/screens/employee/verify_email_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import 'email_changed_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String newEmail;
  
  const VerifyEmailScreen({super.key, required this.newEmail});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    String code = _otpController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit verification code'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userProvider = context.read<UserProvider>();
    final success = await userProvider.changeEmailVerify(widget.newEmail, code);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.user != null) {
          authProvider.updateUser(authProvider.user!.copyWith(email: widget.newEmail));
        }

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EmailChangedScreen(),
          ),
        );

        if (result == true && mounted) {
          Navigator.pop(context, true);
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userProvider.errorMessage ?? 'Invalid verification code'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleResendOtp() async {
    setState(() {
      _isResending = true;
    });

    final userProvider = context.read<UserProvider>();
    final success = await userProvider.changeEmailSendOtp(widget.newEmail);

    setState(() {
      _isResending = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Verification code resent' : (userProvider.errorMessage ?? 'Failed to resend code')),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
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
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // Title
                      const Text(
                        'Email Verification',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Subtitle
                      const Text(
                        "Please check your email inbox for the\nverification code.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // OTP Input Fields
                      _buildOTPField(),

                      const SizedBox(height: 40),

                      // Verify Button
                      SizedBox(
                        width: 140,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleVerify,
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.white),
                                  ),
                                )
                              : const Text(
                                  'Verify',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Resend OTP Button
                      TextButton(
                        onPressed: _isResending ? null : _handleResendOtp,
                        child: _isResending
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary),
                                ),
                              )
                            : const Text(
                                'Resend Code',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
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
        ],
      ),
    );
  }

  Widget _buildOTPField() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextFormField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 20,
        ),
        decoration: InputDecoration(
          counterText: "",
          hintText: "------",
          hintStyle: const TextStyle(
            fontSize: 24,
            letterSpacing: 20,
            color: AppColors.textSecondary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.secondary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
      ),
    );
  }
}
