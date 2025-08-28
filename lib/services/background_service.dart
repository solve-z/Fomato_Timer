import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer_state.dart';
import '../utils/constants.dart';
import 'notification_service.dart';

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
  Timer? _backgroundTimer; // 백그라운드 독립 타이머
  final NotificationService _notificationService = NotificationService();
  
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
    int pausedDuration = 0, // pausedDuration 매개변수 추가
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
      
      // 핵심 데이터만 저장 (pausedDuration 포함)
      await saveTimerState(timerState, pausedDuration: pausedDuration);
      
      // 백그라운드 독립 타이머 시작
      await _startBackgroundCompletionTimer(timerState, farmName, pausedDuration);
      
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
      // 백그라운드 독립 타이머 중지
      _backgroundTimer?.cancel();
      _backgroundTimer = null;
      
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
  Future<void> saveTimerState(TimerState timerState, {int pausedDuration = 0}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'startTime': timerState.startTime?.toIso8601String(),
        'totalSeconds': timerState.totalSeconds,
        'mode': timerState.mode.toString(),
        'currentRound': timerState.currentRound,
        'totalRounds': timerState.totalRounds,
        'selectedFarmId': timerState.selectedFarmId,
        'pausedDuration': pausedDuration, // 실제 pausedDuration 값 저장
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

  /// 저장된 타이머 데이터 원본 반환 (pausedDuration 포함)
  Future<Map<String, dynamic>?> getStoredTimerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_timerDataKey);
      if (dataStr == null) return null;
      
      return jsonDecode(dataStr) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get stored timer data: $e');
      }
      return null;
    }
  }

  /// 백그라운드에서 완료 감지하는 독립 타이머 시작
  Future<void> _startBackgroundCompletionTimer(TimerState timerState, String? farmName, int pausedDuration) async {
    try {
      // 기존 타이머가 있다면 중지
      _backgroundTimer?.cancel();
      
      if (timerState.startTime == null) return;
      
      // 완료 예상 시간 계산
      final completionTime = timerState.startTime!.add(Duration(seconds: timerState.totalSeconds + pausedDuration));
      final now = DateTime.now();
      
      // 이미 완료되었다면 즉시 알림
      if (now.isAfter(completionTime)) {
        await _sendBackgroundCompletionNotification(timerState.mode, farmName);
        return;
      }
      
      // 완료까지 남은 시간 계산
      final remainingDuration = completionTime.difference(now);
      
      if (kDebugMode) {
        print('Background completion timer set for ${remainingDuration.inSeconds} seconds');
      }
      
      // 완료 시점에 알림 전송하는 타이머 설정
      _backgroundTimer = Timer(remainingDuration, () async {
        await _sendBackgroundCompletionNotification(timerState.mode, farmName);
        
        // 상태를 completed로 업데이트
        await _markAsCompleted(timerState);
        
        if (kDebugMode) {
          print('Background timer completed and notification sent');
        }
      });
      
    } catch (e) {
      if (kDebugMode) {
        print('Failed to start background completion timer: $e');
      }
    }
  }
  
  /// 백그라운드에서 완료 알림 전송
  Future<void> _sendBackgroundCompletionNotification(TimerMode mode, String? farmName) async {
    try {
      await _notificationService.initialize();
      
      if (mode == TimerMode.focus) {
        // 집중 완료 - 토마토 수확 알림
        await _notificationService.showFocusCompleteNotification(
          farmName: farmName?.isNotEmpty == true ? farmName! : '농장',
          tomatoCount: 0, // 백그라운드에서는 기본값 사용
        );
        
        if (kDebugMode) {
          print('Background focus completion notification sent');
        }
      } else {
        // 휴식 완료 알림
        final isLongBreak = mode == TimerMode.longBreak;
        await _notificationService.showBreakCompleteNotification(
          isLongBreak: isLongBreak, 
          nextMode: '집중', // 간단하게 다음은 집중으로 설정
        );
        
        if (kDebugMode) {
          print('Background break completion notification sent');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to send background completion notification: $e');
      }
    }
  }
  
  /// 타이머 상태를 완료로 표시
  Future<void> _markAsCompleted(TimerState timerState) async {
    try {
      final completedState = TimerState(
        mode: timerState.mode,
        status: TimerStatus.completed,
        remainingSeconds: 0,
        totalSeconds: timerState.totalSeconds,
        currentRound: timerState.currentRound,
        totalRounds: timerState.totalRounds,
        selectedFarmId: timerState.selectedFarmId,
        startTime: timerState.startTime,
        endTime: DateTime.now(),
      );
      
      await saveTimerState(completedState, pausedDuration: 0);
      
      if (kDebugMode) {
        print('Timer state marked as completed in background');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to mark timer as completed: $e');
      }
    }
  }

  /// 서비스 정리
  void dispose() {
    _backgroundTimer?.cancel();
    _notificationService.dispose();
  }
}
