import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Fomato';
  static const String appDescription = '토마토 농장형 뽀모도로 앱';
  
  static const Duration defaultFocusTime = Duration(minutes: 25);
  static const Duration defaultShortBreakTime = Duration(minutes: 5);
  static const Duration defaultLongBreakTime = Duration(minutes: 15);
  static const int defaultFocusRounds = 4;
  
  static const int tomatoPerFocusSession = 1;
  
  static const String farmStorageKey = 'farms';
  static const String settingsStorageKey = 'settings';
  static const String statisticsStorageKey = 'statistics';
  static const String selectedFarmStorageKey = 'selected_farm';
}

class AppColors {
  static const Color primary = Color(0xFF4CAF50);
  static const Color secondary = Color(0xFFFFC107);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F7F7);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color border = Color(0xFFE0E0E0);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color disabled = Color(0xFFBDBDBD);
}

class AppSizes {
  static const double buttonBorderRadius = 12.0;
  static const double cardBorderRadius = 16.0;
  static const double inputBorderRadius = 10.0;
  
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  static const double iconSize = 24.0;
  static const double iconSizeLarge = 32.0;
  
  static const double elevationLow = 2.0;
  static const double elevationNone = 0.0;
}

class AppTextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

class AppDurations {
  static const Duration animationDefault = Duration(milliseconds: 300);
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationSlow = Duration(milliseconds: 500);
}

enum TimerMode {
  focus,
  shortBreak,
  longBreak,
  stopwatch,
}

enum TimerStatus {
  idle,
  running,
  paused,
  completed,
}