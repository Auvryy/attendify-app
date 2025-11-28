import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class LogoWidget extends StatelessWidget {
  final double size;

  const LogoWidget({
    super.key,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accent,
          width: 3,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/pila-logo.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if image doesn't load
            return const Icon(
              Icons.image,
              size: 60,
              color: AppColors.textSecondary,
            );
          },
        ),
      ),
    );
  }
}
