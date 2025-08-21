import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timer_state.dart';
import 'farm_provider.dart';

/// 타이머 상태 관리 클래스
class TimerNotifier extends StateNotifier<TimerState> {
  TimerNotifier(this.ref) : super(TimerState.initial());
  
  final Ref ref;
  Timer? _timer;

  /// 타이머 시작
  void start() {
    if (state.status == TimerStatus.running) return;

    state = state.copyWith(
      status: TimerStatus.running,
      startTime: DateTime.now(),
    );

    _startTicking();
  }

  /// 타이머 일시정지
  void pause() {
    _timer?.cancel();
    state = state.copyWith(status: TimerStatus.paused);
  }

  /// 타이머 재시작
  void resume() {
    if (state.status != TimerStatus.paused) return;
    
    state = state.copyWith(status: TimerStatus.running);
    _startTicking();
  }

  /// 타이머 정지
  void stop() {
    _timer?.cancel();
    state = TimerState.initial().copyWith(
      selectedFarmId: state.selectedFarmId,
    );
  }

  /// 타이머 리셋 (현재 모드 유지)
  void reset() {
    _timer?.cancel();
    
    final seconds = _getSecondsForMode(state.mode);
    state = state.copyWith(
      status: TimerStatus.initial,
      remainingSeconds: seconds,
      totalSeconds: seconds,
      startTime: null,
      endTime: null,
    );
  }

  /// 농장 선택
  void selectFarm(String? farmId) {
    state = state.copyWith(selectedFarmId: farmId);
  }

  /// 다음 모드로 전환
  void nextMode() {
    _timer?.cancel();
    
    TimerMode nextMode;
    int nextRound = state.currentRound;
    
    if (state.mode == TimerMode.focus) {
      // 집중 완료 후
      if (state.currentRound >= state.totalRounds) {
        // 긴 휴식 후 라운드 리셋
        nextMode = TimerMode.longBreak;
        nextRound = 1;
      } else {
        // 짧은 휴식
        nextMode = TimerMode.shortBreak;
      }
      
      // 토마토 수확!
      _harvestTomato();
    } else {
      // 휴식 완료 후 집중 모드
      nextMode = TimerMode.focus;
      if (state.mode == TimerMode.shortBreak) {
        nextRound = state.currentRound + 1;
      }
    }
    
    final seconds = _getSecondsForMode(nextMode);
    state = state.copyWith(
      mode: nextMode,
      status: TimerStatus.initial,
      remainingSeconds: seconds,
      totalSeconds: seconds,
      currentRound: nextRound,
      startTime: null,
      endTime: null,
    );
  }

  /// 매초 실행되는 타이머 로직
  void _startTicking() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(
          remainingSeconds: state.remainingSeconds - 1,
        );
      } else {
        // 타이머 완료
        timer.cancel();
        state = state.copyWith(
          status: TimerStatus.completed,
          endTime: DateTime.now(),
        );
        
        // 자동으로 다음 모드로 전환 (나중에 설정으로 제어)
        Future.delayed(const Duration(seconds: 1), () {
          nextMode();
        });
      }
    });
  }

  /// 토마토 수확 처리
  void _harvestTomato() {
    final farmId = state.selectedFarmId;
    if (farmId != null) {
      ref.read(farmListProvider.notifier).harvestTomato(farmId);
    }
  }

  /// 모드별 시간 반환 (초)
  int _getSecondsForMode(TimerMode mode) {
    switch (mode) {
      case TimerMode.focus:
        return 25 * 60; // 25분
      case TimerMode.shortBreak:
        return 5 * 60;  // 5분
      case TimerMode.longBreak:
        return 15 * 60; // 15분
      case TimerMode.stopped:
        return 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.roundsUntilLongBreak = 4,
    this.autoStartNext = true,
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