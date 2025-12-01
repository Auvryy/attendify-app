import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/employee/employee_main_layout.dart';
import 'screens/admin/admin_main_layout.dart';

class AttendifyApp extends StatefulWidget {
  const AttendifyApp({super.key});

  @override
  State<AttendifyApp> createState() => _AttendifyAppState();
}

class _AttendifyAppState extends State<AttendifyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize auth provider on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.secondary,
          primary: AppColors.secondary,
          secondary: AppColors.accent,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // Show loading while checking auth status
          if (auth.status == AuthStatus.initial || auth.status == AuthStatus.loading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // Navigate based on auth status
          if (auth.isAuthenticated) {
            if (auth.isAdmin) {
              return const AdminMainLayout();
            }
            return const EmployeeMainLayout();
          }
          
          return const LoginScreen();
        },
      ),
    );
  }
}
