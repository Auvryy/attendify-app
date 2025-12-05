import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/logo_widget.dart';
import '../../providers/auth_provider.dart';
import '../screens/signup_screen.dart';
import '../screens/forgot_password_screen.dart';
import 'admin/admin_main_layout.dart';
import 'employee/employee_main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _hasLoginError = false;
  String? _loginErrorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Clear previous error state
    setState(() {
      _hasLoginError = false;
      _loginErrorMessage = null;
    });

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final auth = context.read<AuthProvider>();
      final success = await auth.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          // Navigate based on role
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => auth.isAdmin
                  ? const AdminMainLayout()
                  : const EmployeeMainLayout(),
            ),
          );
        } else {
          // Show error with red border
          setState(() {
            _hasLoginError = true;
            _loginErrorMessage = auth.errorMessage ?? 'Invalid email or password';
          });
          print(
            '[LOGIN SCREEN] Login failed. Error message: ${auth.errorMessage}',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // White background for body
      body: SafeArea(
        child: Stack(
          children: [
            // Header section (yellow + navy bar)
            Column(
              children: [
                // Yellow Header
                Container(
                  height: 115,
                  width: double.infinity,
                  color: AppColors.primary, // Yellow
                  child: Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Padding(
                        padding: EdgeInsets.only(top: 12.0, right: 16),
                        child: Text(
                          'About us',
                          style: TextStyle(color: Colors.black87, fontSize: 14),
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
                // Rest of body
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            // Title
                            const Text(
                              'ATTENDIFY',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: 1.5,
                                fontFamily: 'serif',
                              ),
                            ),
                            const SizedBox(height: 35),
                            // Error message display
                            if (_hasLoginError && _loginErrorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.error),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _loginErrorMessage!,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            CustomTextField(
                              label: 'Email/ Username',
                              controller: _emailController,
                              prefixIcon: Icons.person_outline,
                              keyboardType: TextInputType.emailAddress,
                              errorBorder: _hasLoginError,
                              onChanged: (_) {
                                if (_hasLoginError) {
                                  setState(() {
                                    _hasLoginError = false;
                                    _loginErrorMessage = null;
                                  });
                                }
                              },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Please enter your email or username'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            CustomTextField(
                              label: 'Password',
                              controller: _passwordController,
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              errorBorder: _hasLoginError,
                              onChanged: (_) {
                                if (_hasLoginError) {
                                  setState(() {
                                    _hasLoginError = false;
                                    _loginErrorMessage = null;
                                  });
                                }
                              },
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Please enter your password'
                                  : value.length < 6
                                  ? 'Password must be at least 6 characters'
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 100, 100, 0),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            CustomButton(
                              text: 'Log in',
                              onPressed: _handleLogin,
                              isLoading: _isLoading,
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignUpScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Sign up',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Positioned LOGO floating on the bar
            Positioned(
              top: 55, // Controls vertical logo placement: fine-tune as needed
              left: 0,
              right: 0,
              child: Center(
                child: LogoWidget(size: 120), // adjust size as needed
              ),
            ),
          ],
        ),
      ),
    );
  }
}
