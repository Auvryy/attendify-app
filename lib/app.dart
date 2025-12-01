import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'screens/login_screen.dart';
import 'screens/employee/attendance_history_screen.dart';
import 'screens/employee/file_leave_screen.dart';
import 'screens/employee/request_submitted_screen.dart';

class AttendifyApp extends StatelessWidget {
  const AttendifyApp({super.key});

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
      home: const LoginScreen(),
      routes: {
        '/employee/attendance-history': (context) => const AttendanceHistoryScreen(),
        '/employee/file-leave': (context) => const FileLeaveScreen(),
        '/employee/request-submitted': (context) => const RequestSubmittedScreen(),
      },
    );
  }
}
