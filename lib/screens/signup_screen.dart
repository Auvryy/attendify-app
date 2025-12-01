import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/barangay_model.dart';
import 'login_screen.dart';
import 'employee/employee_main_layout.dart';
import 'admin/admin_main_layout.dart';

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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  String? _selectedBarangayId;  // Changed to String for UUID
  String? _selectedBarangayName;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  
  // Registration flow state
  int _currentStep = 0; // 0: enter email, 1: verify OTP, 2: complete registration
  String? _devOtp; // For development mode

  List<BarangayModel> _barangays = [];
  bool _barangaysLoaded = false;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid calling provider during build
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final auth = context.read<AuthProvider>();
    final success = await auth.sendRegistrationOtp(_emailController.text.trim());
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success) {
        setState(() => _currentStep = 1);
        // Check for dev OTP
        if (auth.errorMessage != null && auth.errorMessage!.contains('OTP:')) {
          _devOtp = auth.errorMessage!.split('OTP: ').last;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dev mode - OTP: $_devOtp'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 10),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent to your email'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Failed to send OTP'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the OTP'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyRegistrationOtp(_otpController.text.trim());
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success) {
        setState(() => _currentStep = 2);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified! Complete your registration.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Invalid OTP'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBarangayId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your barangay'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.completeRegistration(
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _mobileController.text.trim(),
      barangayId: _selectedBarangayId!,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => auth.isAdmin 
              ? const AdminMainLayout() 
              : const EmployeeMainLayout(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Registration failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
                        label: 'First Name',
                        controller: _firstNameController,
                        prefixIcon: Icons.person_outline,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Please enter your first name'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        label: 'Last Name',
                        controller: _lastNameController,
                        prefixIcon: Icons.person_outline,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Please enter your last name'
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
                        value: _selectedBarangayId,
                        items: _barangays
                            .map(
                              (b) => DropdownMenuItem<String>(
                                value: b.id,
                                child: Text(b.name),
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
                            _selectedBarangayId = value;
                          });
                        },
                        validator: (value) => value == null
                            ? 'Please select your barangay'
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
                      
                      // OTP Section - shown after step 0
                      if (_currentStep >= 1) ...[
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Enter OTP',
                          controller: _otpController,
                          prefixIcon: Icons.lock_clock_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) => _currentStep >= 1 && (v == null || v.isEmpty)
                              ? 'Please enter the OTP'
                              : null,
                        ),
                        if (_devOtp != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Dev OTP: $_devOtp',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],

                      const SizedBox(height: 32),

                      // Step-based buttons
                      if (_currentStep == 0)
                        CustomButton(
                          text: 'Send OTP',
                          onPressed: _sendOtp,
                          isLoading: _isLoading,
                          backgroundColor: AppColors.buttonPrimary,
                          textColor: AppColors.black,
                        )
                      else if (_currentStep == 1)
                        CustomButton(
                          text: 'Verify OTP',
                          onPressed: _verifyOtp,
                          isLoading: _isLoading,
                          backgroundColor: AppColors.buttonPrimary,
                          textColor: AppColors.black,
                        )
                      else
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
