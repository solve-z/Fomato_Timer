import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer_state.dart';
import '../utils/constants.dart';

/// 단순화된 백그라운드 서비스 (단일 시간 기반 시스템)
///
/// 핵심 기능만 담당:
/// 1. 타이머 상태 저장/복원 (시작시간, 총시간 등 핵심 데이터만)
/// 2. flutter_background를 통한 앱 백그라운드 실행 관리
class BackgroundService {
  static const String _timerDataKey = 'unified_timer_data';
  
  static BackgroundService? _instance;
  static BackgroundService get instance => _instance ??= BackgroundService._();
  
  BackgroundService._();
  
  bool _isInitialized = false;
  bool _isBackgroundEnabled = false;
  // 알림은 TimerService에서 직접 관리하므로 여기서는 제거
  
  /// 백그라운드 서비스 초기화
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // 백그라운드 실행 권한 요청
      final backgroundConfig = FlutterBackgroundAndroidConfig(
        notificationTitle: "토마토 타이머 실행 중",
        notificationText: "뽀모도로 타이머가 백그라운드에서 실행되고 있습니다.",
        notificationImportance: AndroidNotificationImportance.normal,
        notificationIcon: AndroidResource(
          name: 'ic_notification',
          defType: 'mipmap',
        ),
      );
      
      // 백그라운드 실행 권한 확인 및 활성화
      final hasPermission = await FlutterBackground.hasPermissions;
      if (!hasPermission) {
        final initialized = await FlutterBackground.initialize(androidConfig: backgroundConfig);
        if (!initialized) {
          if (kDebugMode) {
            print('Failed to initialize flutter_background');
          }
          return false;
        }
      }
      
      // 초기화 완료 (flutter_background만 사용)
      if (kDebugMode) {
        print('BackgroundService initialized successfully');
      }
      
      _isInitialized = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Background service initialization failed: $e');
      }
      return false;
    }
  }
  
  /// 백그라운드 실행 시작 (단순화됨)
  Future<bool> startBackgroundTimer({
    required TimerState timerState,
    required String? farmName,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }
    
    try {
      // 백그라운드 실행 활성화
      if (!_isBackgroundEnabled) {
        _isBackgroundEnabled = await FlutterBackground.enableBackgroundExecution();
        if (!_isBackgroundEnabled) {
          if (kDebugMode) {
            print('Failed to enable background execution');
          }
          return false;
        }
        if (kDebugMode) {
          print('Background execution enabled successfully');
        }
      }
      
      // 핵심 데이터만 저장
      await saveTimerState(timerState);
      
      if (kDebugMode) {
        print('Background timer started successfully');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to start background timer: $e');
      }
      return false;
    }
  }
  
  /// 백그라운드 실행 중지 (단순화됨)
  Future<void> stopBackgroundTimer() async {
    try {
      // 백그라운드 실행 비활성화
      if (_isBackgroundEnabled) {
        await FlutterBackground.disableBackgroundExecution();
        _isBackgroundEnabled = false;
      }
      
      // 저장된 상태 제거
      await clearTimerState();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to stop background timer: $e');
      }
    }
  }
  
  /// 단일 시간 기반 타이머 상태 복원
  Future<TimerState?> restoreTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_timerDataKey);
      if (dataStr == null) return null;
      
      final data = jsonDecode(dataStr) as Map<String, dynamic>;
      final startTimeStr = data['startTime'] as String?;
      if (startTimeStr == null) return null;
      
      final startTime = DateTime.parse(startTimeStr);
      final totalSeconds = data['totalSeconds'] as int;
      final pausedDuration = data['pausedDuration'] as int? ?? 0;
      
      // 시간 기반 정확한 계산
      final now = DateTime.now();
      final elapsedSeconds = now.difference(startTime).inSeconds - pausedDuration;
      final remainingSeconds = math.max(0, totalSeconds - elapsedSeconds);
      
      return TimerState(
        mode: TimerMode.values.firstWhere(
          (m) => m.toString() == data['mode'],
          orElse: () => TimerMode.focus,
        ),
        status: remainingSeconds > 0 ? TimerStatus.running : TimerStatus.completed,
        remainingSeconds: remainingSeconds,
        totalSeconds: totalSeconds,
        currentRound: data['currentRound'] ?? 1,
        totalRounds: data['totalRounds'] ?? AppConstants.defaultRoundsUntilLongBreak,
        selectedFarmId: data['selectedFarmId'],
        startTime: startTime,
        endTime: remainingSeconds <= 0 ? now : null,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to restore timer state: $e');
      }
      return null;
    }
  }
  
  /// 백그라운드 실행 상태 확인
  bool get isBackgroundEnabled => _isBackgroundEnabled;
  
  /// 핵심 타이머 데이터만 저장 (단순화됨)
  Future<void> saveTimerState(TimerState timerState) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'startTime': timerState.startTime?.toIso8601String(),
        'totalSeconds': timerState.totalSeconds,
        'mode': timerState.mode.toString(),
        'currentRound': timerState.currentRound,
        'totalRounds': timerState.totalRounds,
        'selectedFarmId': timerState.selectedFarmId,
        'pausedDuration': 0, // TimerService에서 관리하는 pausedDuration은 별도 처리 필요
        'savedAt': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(_timerDataKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save timer state: $e');
      }
    }
  }
  
  /// 저장된 타이머 상태 제거
  Future<void> clearTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_timerDataKey);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to clear timer state: $e');
      }
    }
  }

  /// 서비스 정리
  void dispose() {
    // 더 이상 필요한 정리 작업 없음 (단순화됨)
  }
}
