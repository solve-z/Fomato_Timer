import 'package:flutter/material.dart';

/// 앱 전역 상수 정의
class AppConstants {
  static const String appName = 'Fomato';
  static const String appDescription = '토마토 농장형 뽀모도로 앱';
  static const String appVersion = '1.0.0';
  
  // 타이머 기본값
  static const int defaultFocusMinutes = 25;
  static const int defaultShortBreakMinutes = 5;
  static const int defaultLongBreakMinutes = 15;
  static const int defaultRoundsUntilLongBreak = 4;
  static const bool defaultAutoStartNext = true;
  
  // 비즈니스 규칙
  static const int tomatoPerFocusSession = 1;  // 25분 집중 = 토마토 1개
  static const int minutesPerTomato = 25;      // 토마토 1개 = 25분
  
  // 저장소 키
  static const String farmsKey = 'farms';
  static const String statisticsKey = 'statistics';
  static const String selectedFarmIdKey = 'selected_farm_id';
  static const String timerSettingsKey = 'timer_settings';
  static const String soundEnabledKey = 'sound_enabled';
  static const String vibrationEnabledKey = 'vibration_enabled';
  static const String notificationEnabledKey = 'notification_enabled';
  
  // 농장 기본 색상 팔레트
  static const List<String> farmColors = [
    '#4CAF50', // 녹색
    '#2196F3', // 파란색
    '#FF9800', // 주황색
    '#9C27B0', // 보라색
    '#F44336', // 빨간색
    '#009688', // 청록색
    '#FF5722', // 깊은 주황색
    '#607D8B', // 청회색
  ];
  
  // 타이머 설정 범위
  static const int minFocusMinutes = 15;
  static const int maxFocusMinutes = 60;
  static const int minBreakMinutes = 3;
  static const int maxShortBreakMinutes = 15;
  static const int minLongBreakMinutes = 10;
  static const int maxLongBreakMinutes = 30;
  static const int minRounds = 2;
  static const int maxRounds = 8;
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