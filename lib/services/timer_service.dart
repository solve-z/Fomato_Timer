import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background/flutter_background.dart';
import '../models/timer_state.dart';
import '../utils/constants.dart';
import 'notification_service.dart';

/// 타이머 백그라운드 서비스
///
/// 뽀모도로 타이머의 핵심 비즈니스 로직을 담당합니다.
/// - 25분 집중 / 5분 휴식 / 15분 긴휴식
/// - 4번 집중 후 긴휴식 자동 전환
/// - 타이머 상태 변화 스트림 제공
class TimerService {
  TimerService({int? focusMinutes, int? shortBreakMinutes, int? longBreakMinutes, int? roundsUntilLongBreak})
    : _focusMinutes = focusMinutes ?? AppConstants.defaultFocusMinutes,
      _shortBreakMinutes = shortBreakMinutes ?? AppConstants.defaultShortBreakMinutes,
      _longBreakMinutes = longBreakMinutes ?? AppConstants.defaultLongBreakMinutes,
      _roundsUntilLongBreak = roundsUntilLongBreak ?? AppConstants.defaultRoundsUntilLongBreak {
    // 생성자에서 초기 설정
    _totalSeconds = _getSecondsForMode(_currentMode);
  }

  final int _focusMinutes;
  final int _shortBreakMinutes;
  final int _longBreakMinutes;
  final int _roundsUntilLongBreak;

  // 단순화된 타이머 필드들
  DateTime? _startTime; // 타이머 시작 시간
  int _totalSeconds = 0; // 현재 모드의 총 시간
  int _remainingSeconds = 0; // 현재 남은 시간 (일시정지 시 고정)
  bool _isPaused = false; // 일시정지 상태

  TimerMode _currentMode = TimerMode.focus;
  int _currentRound = 1;
  String? _selectedFarmId;

  Timer? _mainTimer; // 메인 타이머 하나만 사용
  Timer? _scheduledNotification; // 완료 알림용 타이머
  final StreamController<TimerState> _stateController = StreamController<TimerState>.broadcast();
  final NotificationService _notificationService = NotificationService();

  // Android Foreground Service를 위한 MethodChannel
  static const MethodChannel _androidTimerChannel = MethodChannel('com.example.fomato_timer/timer');

  // 알림 관련 콜백 함수들
  String Function()? _getFarmName;
  bool Function()? _isNotificationEnabled;

  /// 타이머 상태 스트림
  Stream<TimerState> get stateStream {
    // 스트림 구독 시 현재 상태 즉시 전송
    return _stateController.stream.asBroadcastStream();
  }

  /// 단순화된 현재 상태 계산
  TimerState get currentState {
    // 타이머가 시작되지 않았으면 초기 상태
    if (_startTime == null) {
      final modeSeconds = _totalSeconds > 0 ? _totalSeconds : _getSecondsForMode(_currentMode);
      return TimerState(
        mode: _currentMode,
        status: TimerStatus.initial,
        remainingSeconds: modeSeconds,
        totalSeconds: modeSeconds,
        currentRound: _currentRound,
        totalRounds: _roundsUntilLongBreak,
        selectedFarmId: _selectedFarmId,
        startTime: null,
        endTime: null,
      );
    }

    final now = DateTime.now();
    int remainingSeconds;

    // 일시정지 중이면 저장된 값 사용
    if (_isPaused) {
      remainingSeconds = _remainingSeconds;
    } else {
      // 실행 중이면 시작시간 기반으로 계산
      final elapsedSeconds = now.difference(_startTime!).inSeconds;
      remainingSeconds = (_totalSeconds - elapsedSeconds).clamp(0, _totalSeconds);
    }

    // 상태 결정
    TimerStatus status;
    if (_isPaused) {
      status = TimerStatus.paused;
    } else if (remainingSeconds > 0) {
      status = TimerStatus.running;
    } else {
      status = TimerStatus.completed;
    }

    // 디버그 로그
    if (kDebugMode) {
      print('Timer: remaining=$remainingSeconds, paused=$_isPaused, status=$status');
    }

    return TimerState(
      mode: _currentMode,
      status: status,
      remainingSeconds: remainingSeconds,
      totalSeconds: _totalSeconds,
      currentRound: _currentRound,
      totalRounds: _roundsUntilLongBreak,
      selectedFarmId: _selectedFarmId,
      startTime: _startTime,
      endTime: status == TimerStatus.completed ? now : null,
    );
  }

  /// 알림 콜백 설정
  void setNotificationCallbacks({String Function()? getFarmName, bool Function()? isNotificationEnabled}) {
    _getFarmName = getFarmName;
    _isNotificationEnabled = isNotificationEnabled;
  }

  // currentState getter는 위에서 구현되었으므로 제거

  /// 타이머 시작
  void start() {
    if (currentState.status == TimerStatus.running) return;

    _startTime = DateTime.now();
    _totalSeconds = _getSecondsForMode(_currentMode);
    _remainingSeconds = _totalSeconds;
    _isPaused = false;

    // 상태 저장
    _saveState();

    // Android에서는 Foreground Service 사용, 다른 플랫폼은 기존 방식
    if (Platform.isAndroid) {
      _startAndroidForegroundService();
      // Android에서는 flutter_background 사용하지 않음 (중복 알림 방지)
    } else {
      // UI 업데이트 타이머 시작
      _startMainTimer();

      // 백그라운드 실행 시작 (iOS/기타)
      _enableBackground();

      // 완료 알림 예약
      _scheduleCompletionNotification();
    }

    // 즉시 상태 알림
    _notifyStateChange();

    if (kDebugMode) {
      print('Timer started: ${_totalSeconds}s');
    }
  }

  /// 타이머 일시정지
  void pause() {
    if (_startTime == null || _isPaused) return;

    // 정확한 경과 시간 계산하여 남은 시간 즉시 고정
    final elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
    _remainingSeconds = (_totalSeconds - elapsedSeconds).clamp(0, _totalSeconds);
    _isPaused = true;

    // Android에서는 Foreground Service 일시정지, 다른 플랫폼은 기존 방식
    if (Platform.isAndroid) {
      _pauseAndroidForegroundService();
    } else {
      // 메인 타이머 중지
      _mainTimer?.cancel();

      // 완료 알림 취소
      _scheduledNotification?.cancel();
    }

    // 상태 저장 및 알림
    _saveState();
    _notifyStateChange();

    if (kDebugMode) {
      print('Timer paused at ${_remainingSeconds}s');
    }
  }

  /// 타이머 재시작
  void resume() {
    if (_startTime == null || !_isPaused) return;

    // 새로운 시작 시간으로 남은 시간을 기준으로 설정
    _startTime = DateTime.now();
    _totalSeconds = _remainingSeconds;
    _isPaused = false;

    // Android에서는 Foreground Service 재시작, 다른 플랫폼은 기존 방식
    if (Platform.isAndroid) {
      _resumeAndroidForegroundService();
    } else {
      // 메인 타이머 재시작
      _startMainTimer();

      // 완료 알림 다시 예약
      _scheduleCompletionNotification();
    }

    // 상태 저장 및 알림
    _saveState();
    _notifyStateChange();

    if (kDebugMode) {
      print('Timer resumed with ${_remainingSeconds}s remaining');
    }
  }

  /// 타이머 정지 (초기 상태로 리셋)
  void stop() {
    // Android에서는 Foreground Service 정지, 다른 플랫폼은 기존 방식
    if (Platform.isAndroid) {
      _stopAndroidForegroundService();
    } else {
      // 모든 타이머 중지
      _mainTimer?.cancel();
      _scheduledNotification?.cancel();

      // 백그라운드 비활성화
      _disableBackground();
    }

    // 상태 초기화
    _startTime = null;
    _remainingSeconds = 0;
    _isPaused = false;
    _currentMode = TimerMode.focus;
    _currentRound = 1;
    _totalSeconds = _getSecondsForMode(TimerMode.focus);

    // 상태 저장 및 알림
    _saveState();
    _notifyStateChange();
  }

  /// 타이머 리셋 (현재 모드 유지)
  void reset() {
    // 타이머 중지
    _mainTimer?.cancel();
    _scheduledNotification?.cancel();

    // 상태 초기화 (모드는 유지)
    _startTime = null;
    _remainingSeconds = 0;
    _isPaused = false;
    _totalSeconds = _getSecondsForMode(_currentMode);

    // 상태 저장 및 알림
    _saveState();
    _notifyStateChange();
  }

  /// 농장 선택
  void selectFarm(String? farmId) {
    _selectedFarmId = farmId;
    _notifyStateChange();
  }

  /// 다음 모드로 전환
  TimerState nextMode() {
    // 타이머 중지
    _mainTimer?.cancel();
    _scheduledNotification?.cancel();

    _autoTransitionToNextMode();

    // 상태 저장 및 알림
    _saveState();
    _notifyStateChange();

    return currentState;
  }

  /// 다음 모드로 자동 전환 (내부 로직)
  void _autoTransitionToNextMode() {
    TimerMode nextMode;
    int nextRound = _currentRound;

    if (_currentMode == TimerMode.focus) {
      // 집중 완료 후
      if (_currentRound >= _roundsUntilLongBreak) {
        nextMode = TimerMode.longBreak;
      } else {
        nextMode = TimerMode.shortBreak;
      }
    } else {
      // 휴식 완료 후 집중 모드
      nextMode = TimerMode.focus;

      if (_currentMode == TimerMode.shortBreak) {
        // 짧은 휴식 후 라운드 증가
        nextRound = _currentRound + 1;
      } else if (_currentMode == TimerMode.longBreak) {
        // 긴 휴식 후 라운드 리셋
        nextRound = 1;
      }
    }

    // 상태 초기화
    _startTime = null;
    _remainingSeconds = 0;
    _isPaused = false;
    _currentMode = nextMode;
    _currentRound = nextRound;
    _totalSeconds = _getSecondsForMode(nextMode);
  }

  /// 메인 타이머 시작 (단순화됨)
  void _startMainTimer() {
    _mainTimer?.cancel();
    _mainTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) {
        timer.cancel();
        return;
      }

      final state = currentState;

      // UI 업데이트
      _notifyStateChange();

      // 진행 중 알림 업데이트
      _updateRunningNotification();

      // 완료 체크
      if (state.status == TimerStatus.completed) {
        timer.cancel();
        if (kDebugMode) {
          print('Timer completed in main loop - Platform: ${Platform.operatingSystem}');
        }
        _handleCompletion();
      }
    });
  }

  /// 완료 처리
  void _handleCompletion() {
    _mainTimer?.cancel();
    _scheduledNotification?.cancel();

    if (Platform.isAndroid) {
      // Android: Foreground Service가 알림 처리, Flutter는 상태 관리만
      if (kDebugMode) {
        print('Android: Timer completed, Foreground Service handles notification');
      }

      // 완료 상태를 빠르게 정리하여 중복 UI 처리 방지
      _clearAndResetAfterCompletion();
    } else {
      // iOS/기타: 기존 방식
      _disableBackground();
      _sendCompletionNotification();
      _saveState();

      if (kDebugMode) {
        print('Timer completed - Platform: ${Platform.operatingSystem}');
      }
    }
  }

  /// 상태 변경 알림 (스트림에 현재 상태 전송)
  void _notifyStateChange() {
    _stateController.add(currentState);
  }

  /// 백그라운드 실행 활성화
  Future<void> _enableBackground() async {
    try {
      final backgroundConfig = FlutterBackgroundAndroidConfig(
        notificationTitle: "토마토 타이머 실행 중",
        notificationText: "뽀모도로 타이머가 백그라운드에서 실행되고 있습니다.",
        notificationImportance: AndroidNotificationImportance.normal,
      );

      if (!await FlutterBackground.hasPermissions) {
        await FlutterBackground.initialize(androidConfig: backgroundConfig);
      }

      await FlutterBackground.enableBackgroundExecution();
    } catch (e) {
      if (kDebugMode) {
        print('Background enable failed: $e');
      }
    }
  }

  /// 백그라운드 실행 비활성화
  Future<void> _disableBackground() async {
    try {
      await FlutterBackground.disableBackgroundExecution();
    } catch (e) {
      if (kDebugMode) {
        print('Background disable failed: $e');
      }
    }
  }

  /// 완료 알림 예약
  void _scheduleCompletionNotification() {
    _scheduledNotification?.cancel();

    int remainingTime;
    if (_isPaused) {
      remainingTime = _remainingSeconds;
    } else {
      final elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
      remainingTime = (_totalSeconds - elapsedSeconds).clamp(0, _totalSeconds);
    }

    if (remainingTime > 0) {
      _scheduledNotification = Timer(Duration(seconds: remainingTime), () {
        _handleCompletion();
      });

      if (kDebugMode) {
        print('Completion notification scheduled for ${remainingTime}s');
      }
    }
  }

  /// 상태 저장 (SharedPreferences)
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('timer_start_time', _startTime?.toIso8601String() ?? '');
      await prefs.setInt('timer_total_seconds', _totalSeconds);
      await prefs.setInt('timer_remaining_seconds', _remainingSeconds);
      await prefs.setBool('timer_is_paused', _isPaused);
      await prefs.setString('timer_mode', _currentMode.toString());
      await prefs.setInt('timer_round', _currentRound);
      await prefs.setString('timer_farm_id', _selectedFarmId ?? '');
      
      if (kDebugMode) {
        print('SAVE STATE: mode=$_currentMode, round=$_currentRound, remaining=$_remainingSeconds, total=$_totalSeconds, paused=$_isPaused, startTime=${_startTime?.toIso8601String()}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Save state failed: $e');
      }
    }
  }

  /// 앱 복귀 시 상태 복원 (백그라운드 완료 처리 개선)
  Future<void> restoreState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startTimeStr = prefs.getString('timer_start_time');

      // 완료 상태나 저장된 상태가 있는지 확인
      final savedMode = prefs.getString('timer_mode');
      final savedRound = prefs.getInt('timer_round');
      final savedRemaining = prefs.getInt('timer_remaining_seconds');
      
      if ((startTimeStr == null || startTimeStr.isEmpty) && (savedMode == null || savedRound == null)) {
        // 진짜 저장된 타이머 없음 - 초기 상태 유지
        _notifyStateChange();
        return;
      }

      // 저장된 상태 복원 (모드와 라운드부터 먼저 복원)
      if (startTimeStr != null && startTimeStr.isNotEmpty) {
        _startTime = DateTime.parse(startTimeStr);
      } else {
        _startTime = null; // 완료 상태의 경우
      }
      
      final modeStr = prefs.getString('timer_mode');
      if (modeStr != null) {
        _currentMode = TimerMode.values.firstWhere((mode) => mode.toString() == modeStr, orElse: () => TimerMode.focus);
      } else {
        _currentMode = TimerMode.focus;
      }

      _currentRound = prefs.getInt('timer_round') ?? 1;
      _selectedFarmId = prefs.getString('timer_farm_id');
      
      // 모드가 복원된 후 시간 정보 복원
      _totalSeconds = prefs.getInt('timer_total_seconds') ?? _getSecondsForMode(_currentMode);
      _remainingSeconds = prefs.getInt('timer_remaining_seconds') ?? _totalSeconds;
      _isPaused = prefs.getBool('timer_is_paused') ?? false;
      
      if (kDebugMode) {
        print('RESTORE STATE: loaded mode=$modeStr->$_currentMode, round=$_currentRound, remaining=$_remainingSeconds, total=$_totalSeconds, paused=$_isPaused, startTime=$startTimeStr');
      }

      // 백그라운드에서 완료되었는지 확인 (시간 기반 계산)
      bool shouldBeCompleted = false;
      if (_startTime != null && !_isPaused) {
        final now = DateTime.now();
        final elapsedSeconds = now.difference(_startTime!).inSeconds;
        shouldBeCompleted = elapsedSeconds >= _totalSeconds;
      }

      if (shouldBeCompleted) {
        // 백그라운드에서 완료됨 - 완료 상태로 설정 (자동 전환 없음)
        if (kDebugMode) {
          print('Background completion detected - setting as completed');
        }
        
        // 완료 상태로 설정하되 _startTime 유지 (완료 상태 표시를 위해)
        _remainingSeconds = 0;
        _isPaused = false;
        _mainTimer?.cancel();
        _scheduledNotification?.cancel();
        
        // 완료 상태 저장
        await _saveState();
        
        if (kDebugMode) {
          print('Timer completed in background: $_currentMode mode, round $_currentRound');
        }
      } else if (!_isPaused) {
        // 타이머가 여전히 실행 중인 상태
        if (Platform.isAndroid) {
          // Android: Foreground Service 재시작 확인
          final isServiceRunning = await isAndroidForegroundServiceRunning();
          if (!isServiceRunning) {
            // 서비스가 중단된 경우 재시작
            _startAndroidForegroundService();
          } else {
            // 서비스가 실행 중이면 UI 동기화만
            _startMainTimer();
          }
        } else {
          // iOS/기타: 타이머 재시작
          _startMainTimer();
          _enableBackground();
          _scheduleCompletionNotification();
        }
      }

      _notifyStateChange();

      if (kDebugMode) {
        final state = currentState;
        print('Timer state restored: Mode=${state.mode}, Status=${state.status}, Round=${state.currentRound}/${state.totalRounds}, Time=${state.formattedTime}');
        print('Restored values: _currentMode=$_currentMode, _currentRound=$_currentRound, _remainingSeconds=$_remainingSeconds, _totalSeconds=$_totalSeconds');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Restore state failed: $e');
      }
    }
  }

  /// 저장된 상태에서 복원 (사용하지 않음 - restoreState로 대체됨)
  @Deprecated('Use restoreState() instead')
  Future<void> restoreFromState(TimerState restoredState, {int pausedDuration = 0}) async {
    // 이 메서드는 더 이상 사용하지 않음
  }

  // _updateState 메서드는 새로운 시스템에서 사용하지 않음
  // _notifyStateChange()로 대체됨

  /// 모드별 시간 반환 (초)
  int _getSecondsForMode(TimerMode mode) {
    switch (mode) {
      case TimerMode.focus:
        return _focusMinutes == 0 ? 5 : _focusMinutes * 60; // 개발자 모드: 0분 = 5초
      case TimerMode.shortBreak:
        return _shortBreakMinutes == 0 ? 5 : _shortBreakMinutes * 60; // 개발자 모드: 0분 = 5초
      case TimerMode.longBreak:
        return _longBreakMinutes == 0 ? 5 : _longBreakMinutes * 60; // 개발자 모드: 0분 = 5초
      case TimerMode.stopped:
        return 0;
    }
  }

  /// 설정 업데이트 (새 인스턴스 생성 필요)
  TimerService updateSettings({int? focusMinutes, int? shortBreakMinutes, int? longBreakMinutes, int? roundsUntilLongBreak}) {
    final newService = TimerService(
      focusMinutes: focusMinutes ?? _focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? _shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? _longBreakMinutes,
      roundsUntilLongBreak: roundsUntilLongBreak ?? _roundsUntilLongBreak,
    );

    // 현재 모드에 맞는 새로운 시간 계산
    final newSeconds = newService._getSecondsForMode(_currentMode);

    // 현재 상태에 따라 새 서비스 설정
    final currentStateSnapshot = currentState;
    if (currentStateSnapshot.status == TimerStatus.initial || currentStateSnapshot.status == TimerStatus.completed) {
      // 초기 상태거나 완료 상태일 때는 새로운 시간으로 업데이트
      newService._totalSeconds = newSeconds;
    } else {
      // 실행 중이거나 일시정지 상태일 때는 기존 시간 유지
      newService._totalSeconds = _totalSeconds;
    }

    // 기타 상태 복사
    newService._currentMode = _currentMode;
    newService._currentRound = _currentRound;
    newService._selectedFarmId = _selectedFarmId;
    newService._startTime = _startTime;
    newService._remainingSeconds = _remainingSeconds;
    newService._isPaused = _isPaused;

    return newService;
  }

  /// 진행률 계산 (0.0 ~ 1.0)
  double get progress => currentState.progress;

  /// 타이머 실행 중 여부
  bool get isRunning => currentState.isRunning;

  /// 현재 모드가 집중 모드인지
  bool get isFocusMode => currentState.isFocusMode;

  /// 현재 모드가 휴식 모드인지
  bool get isBreakMode => currentState.isBreakMode;

  /// 포맷된 시간 문자열 (MM:SS)
  String get formattedTime => currentState.formattedTime;

  /// 완료 시 알림 전송 (Android에서는 사용 안함)
  Future<void> _sendCompletionNotification() async {
    // Android는 Foreground Service에서 처리하므로 완전 차단
    if (Platform.isAndroid) {
      if (kDebugMode) {
        print('Android: Completion notification blocked - handled by Foreground Service');
      }
      return;
    }

    // 알림이 비활성화되어 있으면 전송하지 않음
    if (_isNotificationEnabled?.call() == false) return;

    try {
      if (currentState.mode == TimerMode.focus) {
        // 집중 완료 알림 - 토마토 수확
        final farmName = _getFarmName?.call() ?? '';
        await _notificationService.showFocusCompleteNotification(
          farmName: farmName.isEmpty ? '농장' : farmName,
          tomatoCount: 0, // 간단히 0으로 설정
        );
      } else {
        // 휴식 완료 알림
        final isLongBreak = currentState.mode == TimerMode.longBreak;
        String nextMode;

        if (isLongBreak) {
          nextMode = '집중';
        } else {
          // 짧은 휴식 후에는 다음 라운드 확인
          if (currentState.currentRound >= _roundsUntilLongBreak) {
            nextMode = '긴 휴식';
          } else {
            nextMode = '집중';
          }
        }

        await _notificationService.showBreakCompleteNotification(isLongBreak: isLongBreak, nextMode: nextMode);
      }
    } catch (e) {
      // 알림 전송 실패 시 무시 (앱 기능에는 영향 없음)
      if (kDebugMode) {
        print('Failed to send completion notification: $e');
      }
    }
  }

  /// 실행 중 알림 업데이트 (Android가 아닌 경우만)
  void _updateRunningNotification() {
    // Android는 Foreground Service에서 처리하므로 중복 방지
    if (Platform.isAndroid) return;

    // 알림이 비활성화되어 있으면 업데이트하지 않음
    if (_isNotificationEnabled?.call() == false) return;

    try {
      final state = currentState;
      final mode = _getModeText(state.mode);
      final timeLeft = _formatTime(state.remainingSeconds);
      final farmName = _getFarmName?.call() ?? '';

      if (state.mode == TimerMode.focus) {
        // 집중시간 - 농장명 포함
        _notificationService.showTimerRunningNotification(mode: mode, timeLeft: timeLeft, farmName: farmName);
      } else {
        // 휴식시간 - 농장명 제외, 전용 알림
        _notificationService.showBreakRunningNotification(mode: mode, timeLeft: timeLeft);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update running notification: $e');
      }
    }
  }

  /// 모드별 텍스트 반환
  String _getModeText(TimerMode mode) {
    switch (mode) {
      case TimerMode.focus:
        return '집중 시간';
      case TimerMode.shortBreak:
        return '짧은 휴식';
      case TimerMode.longBreak:
        return '긴 휴식';
      case TimerMode.stopped:
        return '정지됨';
    }
  }

  /// 시간 포맷팅 (MM:SS)
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// 앱 포그라운드 복귀 시 타이머 상태 동기화 (단순화됨)
  Future<void> syncWithBackgroundState() async {
    try {
      // 단순화된 상태 복원 사용
      await restoreState();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to sync with background state: $e');
      }
    }
  }

  /// Android Foreground Service 시작
  Future<void> _startAndroidForegroundService() async {
    try {
      final farmName = _getFarmName?.call() ?? '';
      final modeString = _currentMode.toString().split('.').last;

      await _androidTimerChannel.invokeMethod('startForegroundTimer', {'duration': _totalSeconds, 'farmName': farmName, 'mode': modeString});

      // Android에서도 UI 업데이트를 위한 메인 타이머 시작
      _startMainTimer();

      if (kDebugMode) {
        print('Android Foreground Service started');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to start Android Foreground Service: $e');
      }
      // 실패 시 기존 방식으로 fallback
      _startMainTimer();
      _enableBackground();
      _scheduleCompletionNotification();
    }
  }

  /// Android Foreground Service 일시정지
  Future<void> _pauseAndroidForegroundService() async {
    try {
      await _androidTimerChannel.invokeMethod('pauseForegroundTimer');

      // UI 업데이트 타이머도 중지
      _mainTimer?.cancel();

      if (kDebugMode) {
        print('Android Foreground Service paused');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to pause Android Foreground Service: $e');
      }
      // 실패 시 기존 방식으로 처리
      _mainTimer?.cancel();
      _scheduledNotification?.cancel();
    }
  }

  /// Android Foreground Service 재시작
  Future<void> _resumeAndroidForegroundService() async {
    try {
      await _androidTimerChannel.invokeMethod('resumeForegroundTimer');

      // UI 업데이트 타이머 재시작
      _startMainTimer();

      if (kDebugMode) {
        print('Android Foreground Service resumed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to resume Android Foreground Service: $e');
      }
      // 실패 시 기존 방식으로 처리
      _startMainTimer();
      _scheduleCompletionNotification();
    }
  }

  /// Android Foreground Service 정지
  Future<void> _stopAndroidForegroundService() async {
    try {
      await _androidTimerChannel.invokeMethod('stopForegroundTimer');

      // UI 업데이트 타이머도 정지
      _mainTimer?.cancel();
      _scheduledNotification?.cancel();

      if (kDebugMode) {
        print('Android Foreground Service stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to stop Android Foreground Service: $e');
      }
      // 실패 시 기존 방식으로 처리
      _mainTimer?.cancel();
      _scheduledNotification?.cancel();
      _disableBackground();
    }
  }

  /// Android Foreground Service 실행 상태 확인
  Future<bool> isAndroidForegroundServiceRunning() async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await _androidTimerChannel.invokeMethod('isForegroundTimerRunning');
      return result as bool? ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to check Android Foreground Service status: $e');
      }
      return false;
    }
  }

  /// Android 완료 후 상태 정리 (중복 UI 처리 방지)
  void _clearAndResetAfterCompletion() {
    // 완료 상태를 즉시 알림 (UI가 완료를 감지할 수 있도록)
    _saveState();
    _notifyStateChange();

    if (kDebugMode) {
      print('Android: Timer completed, ready for nextMode() call');
    }

    // nextMode() 호출을 위해 완료 상태 유지
    // 상태 정리는 nextMode() 호출 후에 이루어짐
  }


  /// 리소스 정리
  void dispose() {
    if (Platform.isAndroid) {
      _stopAndroidForegroundService();
    } else {
      _mainTimer?.cancel();
      _scheduledNotification?.cancel();
      _disableBackground();
    }
    _stateController.close();
    _notificationService.dispose();
  }
}
