import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timer_state.dart';
import '../services/timer_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'farm_provider.dart';

/// 타이머 상태 관리 클래스
class TimerNotifier extends StateNotifier<TimerState> {
  TimerNotifier(this.ref) : super(TimerState.initial()) {
    _initializeService();
  }
  
  final Ref ref;
  TimerService? _timerService;
  StreamSubscription<TimerState>? _stateSubscription;

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
    print('초기 타이머 상태 동기화: ${state.status}, ${state.remainingSeconds}초');

    // 서비스 상태 변화 구독
    _stateSubscription = _timerService!.stateStream.listen(
      (newState) {
        print('TimerNotifier stateStream 수신: ${newState.status}, ${newState.remainingSeconds}초');
        state = newState;
        
        // 타이머 완료 시 자동 전환 처리
        if (newState.status == TimerStatus.completed) {
          try {
            final settings = ref.read(timerSettingsProvider);
            if (settings.autoStartNext) {
              Future.delayed(const Duration(seconds: 1), () {
                _timerService?.nextMode();
                // 집중 모드 완료 시 토마토 수확
                if (state.mode == TimerMode.focus) {
                  _harvestTomato();
                }
              });
            }
          } catch (e) {
            // 설정 로드 실패 시 기본 동작
          }
        }
      },
      onError: (error) {
        print('TimerNotifier stateStream 에러: $error');
      },
      onDone: () {
        print('TimerNotifier stateStream 완료');
      },
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

  /// 타이머 시작
  void start() {
    print('Timer start() 호출됨. _timerService: ${_timerService != null}');
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
    
    // 집중 모드 완료 시 토마토 수확
    if (previousMode == TimerMode.focus) {
      _harvestTomato();
    }
  }

  /// 토마토 수확 처리
  void _harvestTomato() {
    final farmId = state.selectedFarmId;
    if (farmId != null) {
      ref.read(farmListProvider.notifier).harvestTomato(farmId);
    }
  }

  /// 설정 업데이트
  void updateSettings(TimerSettings newSettings) {
    // 타이머가 실행 중이거나 일시정지 상태일 때는 설정 변경 금지
    if (state.status == TimerStatus.running || state.status == TimerStatus.paused) {
      print('타이머 실행 중이므로 설정 변경 불가: ${state.status}');
      return;
    }
    
    print('설정 업데이트: 집중시간 ${newSettings.focusMinutes}분');
    
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
          print('TimerNotifier stateStream 수신: ${newState.status}, ${newState.remainingSeconds}초');
          state = newState;
          
          // 타이머 완료 시 자동 전환 처리
          if (newState.status == TimerStatus.completed) {
            try {
              final settings = ref.read(timerSettingsProvider);
              if (settings.autoStartNext) {
                Future.delayed(const Duration(seconds: 1), () {
                  _timerService?.nextMode();
                  // 집중 모드 완료 시 토마토 수확
                  if (state.mode == TimerMode.focus) {
                    _harvestTomato();
                  }
                });
              }
            } catch (e) {
              // 설정 로드 실패 시 기본 동작
            }
          }
        },
        onError: (error) {
          print('TimerNotifier stateStream 에러: $error');
        },
        onDone: () {
          print('TimerNotifier stateStream 완료');
        },
      );
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _timerService?.dispose();
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
  
  return notifier;
});

/// 타이머 설정 상태
class TimerSettings {
  final int focusMinutes;      // 집중 시간 (분)
  final int shortBreakMinutes; // 짧은 휴식 시간 (분)
  final int longBreakMinutes;  // 긴 휴식 시간 (분)
  final int roundsUntilLongBreak; // 긴 휴식까지 라운드 수
  final bool autoStartNext;    // 다음 모드 자동 시작

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
          focusMinutes: savedSettings['focusMinutes'] ?? AppConstants.defaultFocusMinutes,
          shortBreakMinutes: savedSettings['shortBreakMinutes'] ?? AppConstants.defaultShortBreakMinutes,
          longBreakMinutes: savedSettings['longBreakMinutes'] ?? AppConstants.defaultLongBreakMinutes,
          roundsUntilLongBreak: savedSettings['roundsUntilLongBreak'] ?? AppConstants.defaultRoundsUntilLongBreak,
          autoStartNext: savedSettings['autoStartNext'] ?? AppConstants.defaultAutoStartNext,
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
      print('타이머 실행 중이므로 설정 변경 불가');
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