import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/barangay_model.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  String? _selectedBarangayId;
  bool _isLoading = false;
  
  // Registration flow state
  // 0: enter email + send OTP
  // 1: verify OTP
  // 2: complete registration (fill personal info)
  int _currentStep = 0;

  List<BarangayModel> _barangays = [];
  bool _barangaysLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBarangays();
    });
  }

  Future<void> _fetchBarangays() async {
    if (_barangaysLoaded) return;
    final userProvider = context.read<UserProvider>();
    await userProvider.fetchBarangays();
    if (mounted) {
      setState(() {
        _barangays = userProvider.barangays;
        _barangaysLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email');
      return;
    }
    if (!email.contains('@')) {
      _showError('Please enter a valid email');
      return;
    }

    setState(() => _isLoading = true);
    
    final auth = context.read<AuthProvider>();
    final success = await auth.sendRegistrationOtp(email);
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success) {
        setState(() => _currentStep = 1);
        _showSuccess('OTP sent to your email. Please check your inbox.');
      } else {
        _showError(auth.errorMessage ?? 'Failed to send OTP');
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showError('Please enter the OTP');
      return;
    }
    if (otp.length != 6) {
      _showError('OTP must be 6 digits');
      return;
    }

    setState(() => _isLoading = true);
    
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyRegistrationOtp(otp);
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success) {
        setState(() => _currentStep = 2);
        _showSuccess('Email verified! Now complete your profile.');
      } else {
        _showError(auth.errorMessage ?? 'Invalid OTP');
      }
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBarangayId == null) {
      _showError('Please select your barangay');
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.completeRegistration(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _mobileController.text.trim(),
      barangayId: _selectedBarangayId!,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success) {
        // Show pending approval dialog
        _showPendingApprovalDialog();
      } else {
        _showError(auth.errorMessage ?? 'Registration failed');
      }
    }
  }
  
  void _showPendingApprovalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top, color: AppColors.warning, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Registration Pending',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your registration has been submitted successfully!',
              style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your barangay admin will review your registration. You\'ll receive an email once approved.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Clear auth state
                context.read<AuthProvider>().clearError();
                // Navigate to login
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                foregroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Go to Login', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
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
            Container(height: 8, color: AppColors.accent),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                      const SizedBox(height: 8),
                      
                      // Step indicator
                      _buildStepIndicator(),
                      const SizedBox(height: 24),

                      // Step content
                      if (_currentStep == 0) _buildStep0(),
                      if (_currentStep == 1) _buildStep1(),
                      if (_currentStep == 2) _buildStep2(),

                      const SizedBox(height: 16),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
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

  Widget _buildHeader() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 1.5),
            ),
            child: ClipOval(
              child: Image.asset('assets/images/pila-logo.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'ATTENDIFY',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepCircle(0, 'Email'),
        _buildStepLine(0),
        _buildStepCircle(1, 'Verify'),
        _buildStepLine(1),
        _buildStepCircle(2, 'Profile'),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.accent : AppColors.divider,
              border: isCurrent ? Border.all(color: AppColors.primary, width: 3) : null,
            ),
            child: Center(
              child: isActive && !isCurrent
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isActive = _currentStep > afterStep;
    return Container(
      height: 2,
      width: 30,
      color: isActive ? AppColors.accent : AppColors.divider,
      margin: const EdgeInsets.only(bottom: 20),
    );
  }

  // Step 0: Enter email
  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter your email',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text(
          'We\'ll send a verification code to this email.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Email Address',
          controller: _emailController,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Send OTP',
          onPressed: _sendOtp,
          isLoading: _isLoading,
          backgroundColor: AppColors.buttonPrimary,
          textColor: AppColors.black,
        ),
      ],
    );
  }

  // Step 1: Verify OTP
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verify your email',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code sent to ${_emailController.text}',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Enter OTP',
          controller: _otpController,
          prefixIcon: Icons.lock_clock_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : _sendOtp,
          child: const Text('Resend OTP', style: TextStyle(color: AppColors.accent)),
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Verify OTP',
          onPressed: _verifyOtp,
          isLoading: _isLoading,
          backgroundColor: AppColors.buttonPrimary,
          textColor: AppColors.black,
        ),
      ],
    );
  }

  // Step 2: Complete profile
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Complete your profile',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),

        // Personal info
        const Text('Personal Information', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),

        CustomTextField(
          label: 'First Name',
          controller: _firstNameController,
          prefixIcon: Icons.person_outline,
          validator: (v) => v == null || v.isEmpty ? 'Please enter your first name' : null,
        ),
        const SizedBox(height: 12),

        CustomTextField(
          label: 'Last Name',
          controller: _lastNameController,
          prefixIcon: Icons.person_outline,
          validator: (v) => v == null || v.isEmpty ? 'Please enter your last name' : null,
        ),
        const SizedBox(height: 12),

        CustomTextField(
          label: 'Mobile Number',
          controller: _mobileController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (v) => v == null || v.isEmpty ? 'Please enter your mobile number' : null,
        ),
        const SizedBox(height: 12),

        // Barangay dropdown
        const Text('Barangay', style: TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedBarangayId,
          items: _barangays.map((b) => DropdownMenuItem<String>(value: b.id, child: Text(b.name))).toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider, width: 1)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.secondary, width: 2)),
          ),
          hint: const Text('Select Barangay', style: TextStyle(color: AppColors.textSecondary)),
          onChanged: (value) => setState(() => _selectedBarangayId = value),
          validator: (value) => value == null ? 'Please select your barangay' : null,
        ),

        const SizedBox(height: 24),

        // Info box about password
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A temporary password will be sent to your email once your registration is approved by the admin.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        CustomButton(
          text: 'Create Account',
          onPressed: _handleSignUp,
          isLoading: _isLoading,
          backgroundColor: AppColors.buttonPrimary,
          textColor: AppColors.black,
        ),
      ],
    );
  }
}
