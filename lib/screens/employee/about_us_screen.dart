// lib/screens/employee/about_us_screen.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

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
                  children: [
                    const SizedBox(height: 40),

                    // LSPU Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondary,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/pila-logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.primary,
                              child: const Icon(
                                Icons.school,
                                color: AppColors.accent,
                                size: 60,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ATTENDIFY Title
                    const Text(
                      'ATTENDIFY',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Description
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'This is an initial proposal subject to approval of our project title and concept. If approved, we will keep your office updated on all developments. Rest assured that all information shared will remain confidential and used strictly for academic purposes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
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
            'About us',
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
}
