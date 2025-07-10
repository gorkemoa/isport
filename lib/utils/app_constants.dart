import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFCD401); 
  static const Color primaryDark = Color(0xFFFCD401);
  static const Color accent = Color(0xFF00C4B4); // A teal/green accent
  static const Color textTitle = Color(0xFF212121);
  static const Color textBody = Color(0xFF424242);
  static const Color textLight = Color(0xFF757575);
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFE8E8E8);
}

class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textTitle,
  );

  static const TextStyle company = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textBody,
  );

  static const TextStyle location = TextStyle(
    fontSize: 13,
    color: AppColors.textLight,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 13,
    color: AppColors.textBody,
  );
}

class AppPaddings {
  static const double pageHorizontal = 20.0;
  static const double pageVertical = 24.0;
  static const double card = 16.0;
  static const double item = 12.0;
} 