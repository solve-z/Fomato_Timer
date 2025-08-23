import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timer_state.dart';
import '../services/timer_service.dart';
import '../services/storage_service.dart';
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
  bool _hasHarvestedForCurrentSession = false; // 현재 세션에서 이미 수확했는지 플래그
  bool _hasAutoTransitioned = false; // 현재 완료 상태에서 이미 자동 전환했는지 플래그
  bool _isAppInBackground = false; // 앱 백그라운드 상태 플래그

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

        // 타이머 완료 시 자동 전환 처리
        if (newState.status == TimerStatus.completed && !_hasAutoTransitioned) {
          _hasAutoTransitioned = true; // 자동 전환 시작 플래그 설정

          // 집중 모드 완료 시 토마토 수확 (한 번만 실행)
          if (newState.mode == TimerMode.focus &&
              !_hasHarvestedForCurrentSession) {
            _hasHarvestedForCurrentSession = true;
            _harvestTomato();
          }

          try {
            final settings = ref.read(timerSettingsProvider);
            if (settings.autoStartNext) {
              // 모드에 따라 다른 전환 시간 적용
              final delaySeconds =
                  newState.mode == TimerMode.focus
                      ? 2
                      : 1; // 집중 완료 시 조금 더 오래 표시

              Future.delayed(Duration(seconds: delaySeconds), () {
                _timerService?.nextMode(); // 다음 모드로 전환
                _hasHarvestedForCurrentSession = false; // 다음 세션을 위해 플래그 리셋
                _hasAutoTransitioned = false; // 자동 전환 완료 플래그 리셋

                Future.delayed(const Duration(milliseconds: 500), () {
                  _timerService?.start(); // 새 모드 시작
                });
              });
            } else {
              // 자동 시작이 꺼져있으면 다음 모드로만 전환
              Future.delayed(const Duration(seconds: 1), () {
                _timerService?.nextMode();
                _hasHarvestedForCurrentSession = false;
                _hasAutoTransitioned = false; // 자동 전환 완료 플래그 리셋
              });
            }
          } catch (e) {
            _hasAutoTransitioned = false; // 에러 시 플래그 리셋
          }
        }
      },
      onError: (error) {},
      onDone: () {},
    );

    // 설정이 로드되면 타이머 서비스 업데이트 (좀 더 여유있게 대기)
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        final settings = ref.read(timerSettingsProvider);
        updateSettings(settings);
      } catch (e) {
        // 설정 로드 실패 시 기본 설정 유지
      }
    });
  }

  /// 알림 콜백 설정
  void _setupNotificationCallbacks() {
    _timerService?.setNotificationCallbacks(
      getFarmName: () => _getSelectedFarmName(),
      getTomatoCount: () => _getSelectedFarmTomatoCount(),
      isNotificationEnabled: () => _isNotificationEnabled(),
    );
  }

  /// 타이머 시작
  void start() {
    _hasHarvestedForCurrentSession = false; // 새 세션 시작 시 플래그 리셋
    _hasAutoTransitioned = false; // 새 세션 시작 시 자동 전환 플래그 리셋
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
    final previousMode = state.mode;
    _timerService?.nextMode();

    // 집중 모드 완료 시 토마토 수확 (수동 전환)
    if (previousMode == TimerMode.focus) {
      _harvestTomato();
    }

    // 플래그 리셋 (다음 세션을 위해)
    _hasHarvestedForCurrentSession = false;
    _hasAutoTransitioned = false;
  }

  /// 토마토 수확 처리
  void _harvestTomato() {
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
            focusMinutes:
                currentSettings.focusMinutes == 0
                    ? 1
                    : currentSettings.focusMinutes, // 개발자 모드 5초는 1분으로 기록
          );
    } else {
      // 농장 선택 없이도 수확 가능 (통계용)

      // 통계에 토마토 수확 기록 (농장 없음으로 기록)
      ref
          .read(statisticsProvider.notifier)
          .recordTomatoHarvest(
            farmId: 'no-farm', // 농장 없음을 나타내는 특별한 ID
            date: DateTime.now(),
            focusMinutes:
                currentSettings.focusMinutes == 0
                    ? 1
                    : currentSettings.focusMinutes,
          );
    }
  }

  /// 설정 업데이트
  void updateSettings(TimerSettings newSettings) {
    // 타이머가 실행 중이거나 일시정지 상태일 때는 설정 변경 금지
    if (state.status == TimerStatus.running ||
        state.status == TimerStatus.paused) {
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
          state = newState;

          // 타이머 완료 시 자동 전환 처리
          if (newState.status == TimerStatus.completed &&
              !_hasAutoTransitioned) {
            _hasAutoTransitioned = true; // 자동 전환 시작 플래그 설정

            // 집중 모드 완료 시 토마토 수확 (한 번만 실행)
            if (newState.mode == TimerMode.focus &&
                !_hasHarvestedForCurrentSession) {
              _hasHarvestedForCurrentSession = true;
              _harvestTomato();
            }

            try {
              final settings = ref.read(timerSettingsProvider);
              if (settings.autoStartNext) {
                // 모드에 따라 다른 전환 시간 적용
                final delaySeconds =
                    newState.mode == TimerMode.focus
                        ? 2
                        : 1; // 집중 완료 시 조금 더 오래 표시

                Future.delayed(Duration(seconds: delaySeconds), () {
                  _timerService?.nextMode(); // 다음 모드로 전환
                  _hasHarvestedForCurrentSession = false; // 다음 세션을 위해 플래그 리셋
                  _hasAutoTransitioned = false; // 자동 전환 완료 플래그 리셋

                  Future.delayed(const Duration(milliseconds: 500), () {
                    _timerService?.start(); // 새 모드 시작
                  });
                });
              } else {
                // 자동 시작이 꺼져있으면 다음 모드로만 전환
                Future.delayed(const Duration(seconds: 1), () {
                  _timerService?.nextMode();
                  _hasHarvestedForCurrentSession = false;
                  _hasAutoTransitioned = false; // 자동 전환 완료 플래그 리셋
                });
              }
            } catch (e) {
              _hasAutoTransitioned = false; // 에러 시 플래그 리셋
            }
          }
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

  /// 알림 콜백: 선택된 농장의 토마토 개수 반환
  int _getSelectedFarmTomatoCount() {
    try {
      final selectedFarm = ref.read(selectedFarmProvider);
      return selectedFarm?.tomatoCount ?? 0;
    } catch (e) {
      return 0;
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

  /// 백그라운드 상태와 동기화
  Future<void> _syncWithBackgroundState() async {
    try {
      // 타이머가 실행 중이었다면 백그라운드 상태와 동기화
      if (state.status == TimerStatus.running || state.status == TimerStatus.paused) {
        await _timerService?.syncWithBackgroundState();
      }
    } catch (e) {
      // 동기화 실패 시 무시 (앱 기능에 큰 영향 없음)
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
  final bool autoStartNext; // 다음 모드 자동 시작

  const TimerSettings({
    this.focusMinutes = AppConstants.defaultFocusMinutes,
    this.shortBreakMinutes = AppConstants.defaultShortBreakMinutes,
    this.longBreakMinutes = AppConstants.defaultLongBreakMinutes,
    this.roundsUntilLongBreak = AppConstants.defaultRoundsUntilLongBreak,
    this.autoStartNext = AppConstants.defaultAutoStartNext,
  });

  TimerSettings copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? roundsUntilLongBreak,
    bool? autoStartNext,
  }) {
    return TimerSettings(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      roundsUntilLongBreak: roundsUntilLongBreak ?? this.roundsUntilLongBreak,
      autoStartNext: autoStartNext ?? this.autoStartNext,
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
          focusMinutes:
              savedSettings['focusMinutes'] ?? AppConstants.defaultFocusMinutes,
          shortBreakMinutes:
              savedSettings['shortBreakMinutes'] ??
              AppConstants.defaultShortBreakMinutes,
          longBreakMinutes:
              savedSettings['longBreakMinutes'] ??
              AppConstants.defaultLongBreakMinutes,
          roundsUntilLongBreak:
              savedSettings['roundsUntilLongBreak'] ??
              AppConstants.defaultRoundsUntilLongBreak,
          autoStartNext:
              savedSettings['autoStartNext'] ??
              AppConstants.defaultAutoStartNext,
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
      return timerState.status == TimerStatus.initial ||
          timerState.status == TimerStatus.completed;
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
      autoStartNext: newSettings.autoStartNext,
    );
  }
}

/// 타이머 설정 Provider
final timerSettingsProvider =
    StateNotifierProvider<TimerSettingsNotifier, TimerSettings>((ref) {
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
