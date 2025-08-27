import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer_state.dart';
import '../utils/constants.dart';
import 'notification_service.dart';

/// 백그라운드 타이머 실행 서비스
///
/// 앱이 백그라운드에 있을 때도 타이머를 계속 실행하기 위한 서비스입니다.
/// flutter_background를 사용하여 앱 종료 방지 + 시간 기반 계산으로 정확한 타이머 구현
class BackgroundService {
  static const String _timerStateKey = 'background_timer_state';
  
  static BackgroundService? _instance;
  static BackgroundService get instance => _instance ??= BackgroundService._();
  
  BackgroundService._();
  
  bool _isInitialized = false;
  bool _isBackgroundEnabled = false;
  Timer? _notificationUpdateTimer;
  
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
  
  /// 백그라운드 타이머 시작
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
      
      // 타이머 상태를 SharedPreferences에 저장
      await _saveTimerState(timerState, farmName);
      
      // 15초마다 알림 업데이트 (앱이 살아있을 때만)
      _notificationUpdateTimer?.cancel(); // 기존 타이머 정리
      _notificationUpdateTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
        _updateNotificationInBackground();
      });
      
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
  
  /// 백그라운드 타이머 중지
  Future<void> stopBackgroundTimer() async {
    try {
      // 알림 업데이트 타이머 중지
      _notificationUpdateTimer?.cancel();
      _notificationUpdateTimer = null;
      
      // 백그라운드 실행 비활성화
      if (_isBackgroundEnabled) {
        await FlutterBackground.disableBackgroundExecution();
        _isBackgroundEnabled = false;
      }
      
      // 저장된 상태 제거
      await _clearTimerState();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to stop background timer: $e');
      }
    }
  }
  
  /// 시간 기반 계산으로 타이머 상태 복원
  Future<TimerState?> restoreTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_timerStateKey);
      if (stateJson == null) return null;
      
      final stateData = jsonDecode(stateJson) as Map<String, dynamic>;
      final startTimeStr = stateData['startTime'] as String?;
      if (startTimeStr == null) return null;
      
      // 시간 기반 정확한 계산
      final startTime = DateTime.parse(startTimeStr);
      final totalSeconds = stateData['totalSeconds'] as int;
      final elapsedSeconds = DateTime.now().difference(startTime).inSeconds;
      final remainingSeconds = math.max(0, totalSeconds - elapsedSeconds);
      
      return TimerState(
        mode: TimerMode.values.firstWhere(
          (m) => m.toString() == stateData['mode'],
          orElse: () => TimerMode.focus,
        ),
        status: remainingSeconds > 0
            ? TimerStatus.running
            : TimerStatus.completed,
        remainingSeconds: remainingSeconds,
        totalSeconds: totalSeconds,
        currentRound: stateData['currentRound'] ?? 1,
        totalRounds: stateData['totalRounds'] ?? AppConstants.defaultRoundsUntilLongBreak,
        selectedFarmId: stateData['selectedFarmId'],
        startTime: startTime,
        endTime: remainingSeconds <= 0 ? DateTime.now() : null,
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
  
  /// 타이머 상태 저장
  Future<void> _saveTimerState(TimerState timerState, String? farmName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateData = {
        'mode': timerState.mode.toString(),
        'status': timerState.status.toString(),
        'remainingSeconds': timerState.remainingSeconds,
        'totalSeconds': timerState.totalSeconds,
        'currentRound': timerState.currentRound,
        'totalRounds': timerState.totalRounds,
        'selectedFarmId': timerState.selectedFarmId,
        'startTime': timerState.startTime?.toIso8601String(),
        'endTime': timerState.endTime?.toIso8601String(),
        'savedAt': DateTime.now().toIso8601String(),
        'farmName': farmName,
      };
      
      await prefs.setString(_timerStateKey, jsonEncode(stateData));
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save timer state: $e');
      }
    }
  }
  
  /// 저장된 타이머 상태 제거
  Future<void> _clearTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_timerStateKey);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to clear timer state: $e');
      }
    }
  }
  
  /// 백그라운드에서 알림 업데이트 (시간 기반 계산)
  Future<void> _updateNotificationInBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_timerStateKey);
      
      if (stateJson == null) return;
      
      final stateData = jsonDecode(stateJson) as Map<String, dynamic>;
      final startTimeStr = stateData['startTime'] as String?;
      if (startTimeStr == null) return;
      
      final startTime = DateTime.parse(startTimeStr);
      final totalSeconds = stateData['totalSeconds'] as int;
      final elapsedSeconds = DateTime.now().difference(startTime).inSeconds;
      final remainingSeconds = math.max(0, totalSeconds - elapsedSeconds);
      
      final notificationService = NotificationService();
      await notificationService.initialize();
      
      final mode = stateData['mode'] as String;
      final farmName = stateData['farmName'] as String? ?? '';
      
      if (remainingSeconds <= 0) {
        // 타이머 완료 - 완료 알림만 전송 (상태는 앱에서 처리)
        if (mode.contains('focus')) {
          await notificationService.showFocusCompleteNotification(
            farmName: farmName.isEmpty ? '농장' : farmName,
            tomatoCount: 1,
          );
        } else {
          await notificationService.showBreakCompleteNotification(
            isLongBreak: mode.contains('longBreak'),
            nextMode: '집중',
          );
        }
        
        // 타이머 완료 상태 저장
        stateData['status'] = TimerStatus.completed.toString();
        stateData['remainingSeconds'] = 0;
        stateData['endTime'] = DateTime.now().toIso8601String();
        await prefs.setString(_timerStateKey, jsonEncode(stateData));
        
        // 완료 후 알림 업데이트 중지
        _notificationUpdateTimer?.cancel();
        _notificationUpdateTimer = null;
      } else {
        // 진행 중 - 실시간 알림 업데이트
        if (mode.contains('focus')) {
          // 집중시간 - 농장명 포함
          await notificationService.showTimerRunningNotification(
            mode: '집중 시간',
            timeLeft: _formatTime(remainingSeconds),
            farmName: farmName,
          );
        } else {
          // 휴식시간 - 농장명 제외, 전용 알림
          final modeText = mode.contains('longBreak') ? '긴 휴식' : '짧은 휴식';
          await notificationService.showBreakRunningNotification(
            mode: modeText,
            timeLeft: _formatTime(remainingSeconds),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Notification update failed: $e');
      }
    }
  }

  /// 서비스 정리
  void dispose() {
    _notificationUpdateTimer?.cancel();
  }
}


/// 시간 포맷팅 헬퍼 함수
String _formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
}