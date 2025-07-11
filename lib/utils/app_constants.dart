import 'package:flutter/material.dart';
import '../services/logger_service.dart';

class AppColors {
  static const Color primary = Color.fromARGB(255, 29, 157, 131); 
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

  static const TextStyle subtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textTitle,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textLight,
  );
}

class AppPaddings {
  static const double pageHorizontal = 20.0;
  static const double pageVertical = 24.0;
  static const double card = 16.0;
  static const double item = 12.0;
  static const double section = 24.0;
} 

class AppConstants {
  static const String appName = 'iSport';
  static const String appVersion = '1.0.0';
  
  // Environment ayarları
  static const bool isDebugMode = true; // Production'da false yapın
  static const bool enableAnalytics = false; // Production'da true yapın
  static const bool enableCrashlytics = false; // Production'da true yapın
  
  // Logger environment'ı app durumuna göre belirle
  static AppEnvironment get loggerEnvironment {
    if (isDebugMode) {
      return AppEnvironment.development;
    } else {
      return AppEnvironment.production;
    }
  }
  
  // API Base URL'leri
  static const String baseUrlDev = 'https://dev-api.isport.com';
  static const String baseUrlStaging = 'https://staging-api.isport.com';
  static const String baseUrlProd = 'https://api.isport.com';
  
  static String get baseUrl {
    switch (loggerEnvironment) {
      case AppEnvironment.development:
        return baseUrlDev;
      case AppEnvironment.staging:
        return baseUrlStaging;
      case AppEnvironment.production:
        return baseUrlProd;
    }
  }
  
  // Timeout ayarları
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Cache ayarları
  static const int maxCacheAge = 24; // hours
  static const int maxCacheSize = 100; // MB
  
  // Logger ayarları
  static const bool enableFileLogging = true;
  static const int logRetentionDays = 7;
} 