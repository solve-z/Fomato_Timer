import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timer_state.dart';
import '../services/timer_service.dart';
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
    final settings = ref.read(timerSettingsProvider);
    _timerService = TimerService(
      focusMinutes: settings.focusMinutes,
      shortBreakMinutes: settings.shortBreakMinutes,
      longBreakMinutes: settings.longBreakMinutes,
      roundsUntilLongBreak: settings.roundsUntilLongBreak,
    );

    // 서비스 상태 변화 구독
    _stateSubscription = _timerService!.stateStream.listen((newState) {
      state = newState;
      
      // 타이머 완료 시 자동 전환 처리
      if (newState.status == TimerStatus.completed) {
        if (ref.read(timerSettingsProvider).autoStartNext) {
          Future.delayed(const Duration(seconds: 1), () {
            _timerService!.nextMode();
            // 집중 모드 완료 시 토마토 수확
            if (state.mode == TimerMode.focus) {
              _harvestTomato();
            }
          });
        }
      }
    });
  }

  /// 타이머 시작
  void start() {
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

  /// 타이머 리셋
  void reset() {
    _timerService?.reset();
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
    _timerService = _timerService?.updateSettings(
      focusMinutes: newSettings.focusMinutes,
      shortBreakMinutes: newSettings.shortBreakMinutes,
      longBreakMinutes: newSettings.longBreakMinutes,
      roundsUntilLongBreak: newSettings.roundsUntilLongBreak,
    );
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
  return TimerNotifier(ref);
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

/// 타이머 설정 Provider
final timerSettingsProvider = StateProvider<TimerSettings>((ref) {
  return const TimerSettings();
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