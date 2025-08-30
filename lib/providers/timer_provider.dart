import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timer_state.dart';
import '../services/timer_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../models/farm.dart';
import 'farm_provider.dart';
import 'statistics_provider.dart';
import 'settings_provider.dart';

/// 타이머 상태 관리 클래스
class TimerNotifier extends StateNotifier<TimerState> with WidgetsBindingObserver {
  TimerNotifier(this.ref) : super(TimerState.initial()) {
    _initializeService();
    _setupAppLifecycleListener();
  }

  final Ref ref;
  TimerService? _timerService;
  StreamSubscription<TimerState>? _stateSubscription;
  bool _isAppInBackground = false; // 앱 백그라운드 상태 플래그
  DateTime? _lastCompletedTime; // 마지막 완료 처리 시간

  /// 서비스 초기화
  void _initializeService() {
    // 기본 설정으로 먼저 초기화
    _timerService = TimerService(
      focusMinutes: AppConstants.defaultFocusMinutes,
      shortBreakMinutes: AppConstants.defaultShortBreakMinutes,
      longBreakMinutes: AppConstants.defaultLongBreakMinutes,
      roundsUntilLongBreak: AppConstants.defaultRoundsUntilLongBreak,
    );

    // 현재 서비스 상태로 초기화
    state = _timerService!.currentState;

    // 알림 콜백 설정 (초기화 후)
    _setupNotificationCallbacks();

    // 서비스 상태 변화 구독
    _stateSubscription = _timerService!.stateStream.listen(
      (newState) {
        state = newState;

        // 집중 모드 완료 시 토마토 수확 처리
        _handleFocusCompletion(newState);
      },
      onError: (error) {},
      onDone: () {},
    );

    // 설정 로드 및 백그라운드 상태 복원
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        final settings = ref.read(timerSettingsProvider);
        updateSettings(settings);
      } catch (e) {
        // 설정 로드 실패 시 기본 설정 유지
      }

      // 앱 시작시 백그라운드 상태 자동 확인
      _syncWithBackgroundState();
    });
  }

  /// 알림 콜백 설정
  void _setupNotificationCallbacks() {
    _timerService?.setNotificationCallbacks(getFarmName: () => _getSelectedFarmName(), isNotificationEnabled: () => _isNotificationEnabled());
  }

  /// 타이머 시작
  void start() {
    _lastCompletedTime = null; // 새 세션 시작
    _timerService?.start();
  }

  /// 타이머 일시정지
  void pause() {
    _timerService?.pause();
  }

  /// 타이머 재시작
  void resume() {
    _timerService?.resume();
  }

  /// 타이머 정지
  void stop() {
    _timerService?.stop();
  }

  /// 타이머 리셋 (초기 상태로 완전 리셋)
  void reset() {
    _timerService?.stop(); // 완전히 초기 상태로 리셋
  }

  /// 농장 선택
  void selectFarm(String? farmId) {
    _timerService?.selectFarm(farmId);
  }

  /// 다음 모드로 전환
  void nextMode() {
    _timerService?.nextMode();
    _lastCompletedTime = null; // 모드 전환 시 리셋
  }

  /// 집중 모드 완료 처리 (토마토 수확)
  void _handleFocusCompletion(TimerState newState) {
    if (newState.mode != TimerMode.focus || newState.status != TimerStatus.completed) {
      return;
    }

    // 시간 기반 중복 방지
    final now = DateTime.now();
    if (_lastCompletedTime != null && 
        now.difference(_lastCompletedTime!).inMilliseconds < 2000) {
      if (kDebugMode) {
        print('Duplicate completion detected - skipping harvest');
      }
      return;
    }

    _lastCompletedTime = now;

    // 플랫폼별 처리
    if (Platform.isAndroid) {
      _harvestTomatoOnly(); // 알림은 Foreground Service에서
    } else {
      _harvestTomato(); // 알림 포함
    }

    if (kDebugMode) {
      print('Focus completion processed - tomato harvested');
    }
  }

  /// 토마토 수확 처리
  void _harvestTomato() async {
    final farmId = state.selectedFarmId;
    final currentSettings = ref.read(timerSettingsProvider);

    if (farmId != null) {
      // 선택된 농장에 토마토 수확
      ref.read(farmListProvider.notifier).harvestTomato(farmId);
      // 통계에 토마토 수확 기록 (농장 선택됨)
      ref
          .read(statisticsProvider.notifier)
          .recordTomatoHarvest(
            farmId: farmId,
            date: DateTime.now(),
            focusMinutes: currentSettings.focusMinutes == 0 ? 1 : currentSettings.focusMinutes, // 개발자 모드 5초는 1분으로 기록
          );
    } else {
      // 농장 선택 없이도 수확 가능 (통계용)

      // 통계에 토마토 수확 기록 (농장 없음으로 기록)
      ref
          .read(statisticsProvider.notifier)
          .recordTomatoHarvest(
            farmId: 'no-farm', // 농장 없음을 나타내는 특별한 ID
            date: DateTime.now(),
            focusMinutes: currentSettings.focusMinutes == 0 ? 1 : currentSettings.focusMinutes,
          );
    }

    // 토마토 수확 완료 후 알림 전송
    await _sendFocusCompleteNotification();
  }

  /// 토마토 수확만 처리 (Android 전용 - 알림 없음)
  void _harvestTomatoOnly() async {
    final farmId = state.selectedFarmId;
    final currentSettings = ref.read(timerSettingsProvider);

    if (farmId != null) {
      // 선택된 농장에 토마토 수확
      ref.read(farmListProvider.notifier).harvestTomato(farmId);
      // 통계에 토마토 수확 기록 (농장 선택됨)
      ref
          .read(statisticsProvider.notifier)
          .recordTomatoHarvest(
            farmId: farmId,
            date: DateTime.now(),
            focusMinutes: currentSettings.focusMinutes == 0 ? 1 : currentSettings.focusMinutes, // 개발자 모드 5초는 1분으로 기록
          );
    } else {
      // 농장 선택 없이도 수확 가능 (통계용)

      // 통계에 토마토 수확 기록 (농장 없음으로 기록)
      ref
          .read(statisticsProvider.notifier)
          .recordTomatoHarvest(
            farmId: 'no-farm', // 농장 없음을 나타내는 특별한 ID
            date: DateTime.now(),
            focusMinutes: currentSettings.focusMinutes == 0 ? 1 : currentSettings.focusMinutes,
          );
    }

    if (kDebugMode) {
      print('Android: Tomato harvested without notification');
    }
  }

  /// 집중 완료 알림 전송
  Future<void> _sendFocusCompleteNotification() async {
    try {
      // Android에서는 Foreground Service가 알림 처리하므로 완전 차단
      if (Platform.isAndroid) {
        if (kDebugMode) {
          print('Android: UI notification blocked - handled by Foreground Service');
        }
        return;
      }

      // 알림 설정 확인
      if (!_isNotificationEnabled()) return;

      // 농장 이름 가져오기
      final farmName = _getSelectedFarmName();

      // 오늘 수확한 총 토마토 개수 가져오기 (방금 수확한 것 포함)
      final todayTotalCount = ref.read(statisticsProvider.notifier).getTodayTotalTomatoCount();

      // 알림 전송 (iOS/기타 플랫폼만)
      final notificationService = NotificationService();
      await notificationService.showFocusCompleteNotification(
        farmName: farmName.isEmpty ? '농장' : farmName,
        tomatoCount: todayTotalCount - 1, // -1을 해서 방금 수확한 것 제외하고 이전까지의 개수를 전달
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to send focus complete notification: $e');
      }
    }
  }

  /// 설정 업데이트
  void updateSettings(TimerSettings newSettings) {
    // 타이머가 실행 중이거나 일시정지 상태일 때는 설정 변경 금지
    if (state.status == TimerStatus.running || state.status == TimerStatus.paused) {
      return;
    }

    // 기존 구독 취소
    _stateSubscription?.cancel();

    // 새 서비스로 업데이트
    _timerService = _timerService?.updateSettings(
      focusMinutes: newSettings.focusMinutes,
      shortBreakMinutes: newSettings.shortBreakMinutes,
      longBreakMinutes: newSettings.longBreakMinutes,
      roundsUntilLongBreak: newSettings.roundsUntilLongBreak,
    );

    if (_timerService != null) {
      // 새 서비스의 현재 상태로 업데이트
      state = _timerService!.currentState;

      // 새 서비스의 스트림 구독
      _stateSubscription = _timerService!.stateStream.listen(
        (newState) {
          state = newState.copyWith(
            // UI가 다음 모드 버튼을 표시해야 하는 경우
            showNextModeButton: (newState.status == TimerStatus.completed && newState.mode != TimerMode.stopped) ? true : false,
          );

          // 집중 모드 완료 시 토마토 수확 처리
          _handleFocusCompletion(newState);
        },
        onError: (error) {},
        onDone: () {},
      );
    }
  }

  /// 알림 콜백: 선택된 농장 이름 반환
  String _getSelectedFarmName() {
    try {
      final selectedFarm = ref.read(selectedFarmProvider);
      return selectedFarm?.name ?? '';
    } catch (e) {
      return '';
    }
  }

  /// 알림 콜백: 알림 활성화 여부 반환
  bool _isNotificationEnabled() {
    try {
      final notificationSettings = ref.read(notificationSettingsProvider);
      return notificationSettings.notificationEnabled;
    } catch (e) {
      return false; // 기본값은 비활성화
    }
  }

  /// 앱 라이프사이클 리스너 설정
  void _setupAppLifecycleListener() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// 앱 라이프사이클 상태 변화 감지
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        // 앱이 백그라운드로 전환됨
        _isAppInBackground = true;
        break;
      case AppLifecycleState.resumed:
        // 앱이 포그라운드로 복귀함
        if (_isAppInBackground) {
          _isAppInBackground = false;
          _syncWithBackgroundState();
        }
        break;
      default:
        break;
    }
  }

  /// 백그라운드 상태와 동기화 (단순화됨)
  Future<void> _syncWithBackgroundState() async {
    try {
      // 단순화된 상태 복원
      await _timerService?.restoreState();

      // 농장 선택 상태 동기화
      await _syncFarmSelectionState();

      // 백그라운드 완료는 restoreState에서 자동 처리됨

      if (kDebugMode) {
        print('Background state sync completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to sync with background state: $e');
      }
    }
  }

  /// 농장 선택 상태 동기화
  Future<void> _syncFarmSelectionState() async {
    try {
      final currentTimerState = state;
      final selectedFarmId = currentTimerState.selectedFarmId;

      if (selectedFarmId != null) {
        // 현재 선택된 농장과 복원된 농장이 다르면 동기화
        final currentSelectedFarm = ref.read(selectedFarmProvider);

        if (currentSelectedFarm?.id != selectedFarmId) {
          // 농장 목록에서 해당 농장 찾기
          final farmList = ref.read(farmListProvider);
          Farm? targetFarm;

          try {
            targetFarm = farmList.firstWhere((farm) => farm.id == selectedFarmId);
          } catch (e) {
            // 해당 농장을 찾을 수 없으면 첫 번째 농장으로 대체
            targetFarm = farmList.isNotEmpty ? farmList.first : null;
          }

          if (targetFarm != null) {
            // 농장 선택 상태 동기화
            ref.read(selectedFarmProvider.notifier).state = targetFarm;

            if (kDebugMode) {
              print('Farm selection synced: ${targetFarm.name}');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to sync farm selection state: $e');
      }
    }
  }


  @override
  void dispose() {
    _stateSubscription?.cancel();
    _timerService?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// 타이머 상태 Provider
final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  final notifier = TimerNotifier(ref);

  // 설정 변화 감지하여 타이머 서비스 업데이트
  ref.listen<TimerSettings>(timerSettingsProvider, (previous, next) {
    if (previous != null && previous != next) {
      notifier.updateSettings(next);
    }
  });

  // 농장 선택 변화 감지하여 타이머 서비스에 동기화
  ref.listen<Farm?>(selectedFarmProvider, (previous, next) {
    notifier.selectFarm(next?.id);
  });

  return notifier;
});

/// 타이머 설정 상태
class TimerSettings {
  final int focusMinutes; // 집중 시간 (분)
  final int shortBreakMinutes; // 짧은 휴식 시간 (분)
  final int longBreakMinutes; // 긴 휴식 시간 (분)
  final int roundsUntilLongBreak; // 긴 휴식까지 라운드 수

  const TimerSettings({
    this.focusMinutes = AppConstants.defaultFocusMinutes,
    this.shortBreakMinutes = AppConstants.defaultShortBreakMinutes,
    this.longBreakMinutes = AppConstants.defaultLongBreakMinutes,
    this.roundsUntilLongBreak = AppConstants.defaultRoundsUntilLongBreak,
  });

  TimerSettings copyWith({int? focusMinutes, int? shortBreakMinutes, int? longBreakMinutes, int? roundsUntilLongBreak}) {
    return TimerSettings(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      roundsUntilLongBreak: roundsUntilLongBreak ?? this.roundsUntilLongBreak,
    );
  }
}

/// 타이머 설정 관리 클래스
class TimerSettingsNotifier extends StateNotifier<TimerSettings> {
  TimerSettingsNotifier(this.ref) : super(const TimerSettings()) {
    _loadSettings();
  }

  final Ref ref;

  /// 설정 로드
  void _loadSettings() async {
    try {
      final savedSettings = await StorageService.loadTimerSettings();
      if (savedSettings != null) {
        state = TimerSettings(
          focusMinutes: savedSettings['focusMinutes'] ?? AppConstants.defaultFocusMinutes,
          shortBreakMinutes: savedSettings['shortBreakMinutes'] ?? AppConstants.defaultShortBreakMinutes,
          longBreakMinutes: savedSettings['longBreakMinutes'] ?? AppConstants.defaultLongBreakMinutes,
          roundsUntilLongBreak: savedSettings['roundsUntilLongBreak'] ?? AppConstants.defaultRoundsUntilLongBreak,
        );
      }
    } catch (e) {
      // 에러 발생 시 기본값 유지
    }
  }

  /// 설정 업데이트 가능 여부 확인
  bool canUpdateSettings() {
    try {
      final timerState = ref.read(timerProvider);
      return timerState.status == TimerStatus.initial || timerState.status == TimerStatus.completed;
    } catch (e) {
      return true; // 에러 시 기본적으로 허용
    }
  }

  /// 설정 업데이트 및 저장
  void updateSettings(TimerSettings newSettings) async {
    if (!canUpdateSettings()) {
      return;
    }

    state = newSettings;
    await StorageService.saveTimerSettings(
      focusMinutes: newSettings.focusMinutes,
      shortBreakMinutes: newSettings.shortBreakMinutes,
      longBreakMinutes: newSettings.longBreakMinutes,
      roundsUntilLongBreak: newSettings.roundsUntilLongBreak,
    );
  }
}

/// 타이머 설정 Provider
final timerSettingsProvider = StateNotifierProvider<TimerSettingsNotifier, TimerSettings>((ref) {
  return TimerSettingsNotifier(ref);
});

/// 현재 진행도 Provider (0.0 ~ 1.0)
final timerProgressProvider = Provider<double>((ref) {
  final timerState = ref.watch(timerProvider);
  return timerState.progress;
});

/// 타이머 실행 중 여부 Provider
final isTimerRunningProvider = Provider<bool>((ref) {
  final timerState = ref.watch(timerProvider);
  return timerState.isRunning;
});
