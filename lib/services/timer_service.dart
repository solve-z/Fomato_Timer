import 'dart:async';
import '../models/timer_state.dart';
import '../utils/constants.dart';

/// 타이머 백그라운드 서비스
///
/// 뽀모도로 타이머의 핵심 비즈니스 로직을 담당합니다.
/// - 25분 집중 / 5분 휴식 / 15분 긴휴식
/// - 4번 집중 후 긴휴식 자동 전환
/// - 타이머 상태 변화 스트림 제공
class TimerService {
  TimerService({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? roundsUntilLongBreak,
  }) : _focusMinutes = focusMinutes ?? AppConstants.defaultFocusMinutes,
       _shortBreakMinutes =
           shortBreakMinutes ?? AppConstants.defaultShortBreakMinutes,
       _longBreakMinutes =
           longBreakMinutes ?? AppConstants.defaultLongBreakMinutes,
       _roundsUntilLongBreak =
           roundsUntilLongBreak ?? AppConstants.defaultRoundsUntilLongBreak;

  final int _focusMinutes;
  final int _shortBreakMinutes;
  final int _longBreakMinutes;
  final int _roundsUntilLongBreak;

  Timer? _timer;
  final StreamController<TimerState> _stateController =
      StreamController<TimerState>.broadcast();
  TimerState _currentState = TimerState.initial();

  /// 타이머 상태 스트림
  Stream<TimerState> get stateStream {
    // 스트림 구독 시 현재 상태 즉시 전송
    return _stateController.stream.asBroadcastStream();
  }

  /// 현재 상태
  TimerState get currentState => _currentState;

  /// 타이머 시작
  void start() {
    if (_currentState.status == TimerStatus.running) return;

    _updateState(
      _currentState.copyWith(
        status: TimerStatus.running,
        startTime: DateTime.now(),
      ),
    );

    _startTicking();
  }

  /// 타이머 일시정지
  void pause() {
    _timer?.cancel();
    _updateState(_currentState.copyWith(status: TimerStatus.paused));
  }

  /// 타이머 재시작
  void resume() {
    if (_currentState.status != TimerStatus.paused) return;

    _updateState(_currentState.copyWith(status: TimerStatus.running));
    _startTicking();
  }

  /// 타이머 정지 (초기 상태로 리셋)
  void stop() {
    _timer?.cancel();
    _updateState(
      TimerState.initial().copyWith(
        selectedFarmId: _currentState.selectedFarmId,
        totalRounds: _roundsUntilLongBreak,
      ),
    );
  }

  /// 타이머 리셋 (현재 모드 유지)
  void reset() {
    _timer?.cancel();

    final seconds = _getSecondsForMode(_currentState.mode);
    _updateState(
      _currentState.copyWith(
        status: TimerStatus.initial,
        remainingSeconds: seconds,
        totalSeconds: seconds,
        startTime: null,
        endTime: null,
      ),
    );
  }

  /// 농장 선택
  void selectFarm(String? farmId) {
    _updateState(_currentState.copyWith(selectedFarmId: farmId));
  }

  /// 다음 모드로 전환
  TimerState nextMode() {
    _timer?.cancel();

    TimerMode nextMode;
    int nextRound = _currentState.currentRound;

    if (_currentState.mode == TimerMode.focus) {
      // 집중 완료 후

      // 현재 라운드가 설정된 총 라운드와 같으면 긴 휴식
      if (_currentState.currentRound >= _roundsUntilLongBreak) {
        nextMode = TimerMode.longBreak;
      } else {
        nextMode = TimerMode.shortBreak;
      }
    } else {
      // 휴식 완료 후 집중 모드
      nextMode = TimerMode.focus;

      if (_currentState.mode == TimerMode.shortBreak) {
        // 짧은 휴식 후 라운드 증가
        nextRound = _currentState.currentRound + 1;
      } else if (_currentState.mode == TimerMode.longBreak) {
        // 긴 휴식 후 라운드 리셋
        nextRound = 1;
      }
    }

    final seconds = _getSecondsForMode(nextMode);
    final nextState = _currentState.copyWith(
      mode: nextMode,
      status: TimerStatus.initial,
      remainingSeconds: seconds,
      totalSeconds: seconds,
      currentRound: nextRound,
      startTime: null,
      endTime: null,
    );

    _updateState(nextState);

    // 토마토 수확 정보 반환 (Provider에서 처리)
    return nextState.copyWith(
      // 임시로 selectedFarmId를 사용해 수확 플래그 전달
      // 실제로는 별도 콜백이나 이벤트 시스템 사용
    );
  }

  /// 매초 실행되는 타이머 로직
  void _startTicking() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newRemainingSeconds = _currentState.remainingSeconds - 1;

      if (newRemainingSeconds > 0) {
        _updateState(
          _currentState.copyWith(remainingSeconds: newRemainingSeconds),
        );
      } else if (newRemainingSeconds == 0) {
        // 0초 상태로 업데이트
        _updateState(_currentState.copyWith(remainingSeconds: 0));
      } else {
        // -1초 (즉, 완료)
        timer.cancel();
        _updateState(
          _currentState.copyWith(
            status: TimerStatus.completed,
            remainingSeconds: 0,
            endTime: DateTime.now(),
          ),
        );
      }
    });
  }

  /// 상태 업데이트 및 스트림에 전달
  void _updateState(TimerState newState) {
    _currentState = newState;
    _stateController.add(_currentState);
  }

  /// 모드별 시간 반환 (초)
  int _getSecondsForMode(TimerMode mode) {
    switch (mode) {
      case TimerMode.focus:
        return _focusMinutes == 0 ? 5 : _focusMinutes * 60; // 개발자 모드: 0분 = 5초
      case TimerMode.shortBreak:
        return _shortBreakMinutes == 0
            ? 5
            : _shortBreakMinutes * 60; // 개발자 모드: 0분 = 5초
      case TimerMode.longBreak:
        return _longBreakMinutes == 0
            ? 5
            : _longBreakMinutes * 60; // 개발자 모드: 0분 = 5초
      case TimerMode.stopped:
        return 0;
    }
  }

  /// 서비스 종료
  void dispose() {
    _timer?.cancel();
    _stateController.close();
  }

  /// 설정 업데이트 (새 인스턴스 생성 필요)
  TimerService updateSettings({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? roundsUntilLongBreak,
  }) {
    final newService = TimerService(
      focusMinutes: focusMinutes ?? _focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? _shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? _longBreakMinutes,
      roundsUntilLongBreak: roundsUntilLongBreak ?? _roundsUntilLongBreak,
    );

    // 현재 모드에 맞는 새로운 시간 계산
    final newSeconds = newService._getSecondsForMode(_currentState.mode);

    // 현재 상태 복사하되, 초기 상태이거나 완료 상태일 때만 시간 업데이트
    TimerState newState;
    if (_currentState.status == TimerStatus.initial ||
        _currentState.status == TimerStatus.completed) {
      // 초기 상태거나 완료 상태일 때는 새로운 시간으로 업데이트
      newState = _currentState.copyWith(
        remainingSeconds: newSeconds,
        totalSeconds: newSeconds,
        totalRounds: roundsUntilLongBreak ?? _roundsUntilLongBreak,
      );
    } else {
      // 실행 중이거나 일시정지 상태일 때는 시간은 그대로 두고 라운드만 업데이트
      newState = _currentState.copyWith(
        totalRounds: roundsUntilLongBreak ?? _roundsUntilLongBreak,
      );
    }

    newService._updateState(newState);

    return newService;
  }

  /// 진행률 계산 (0.0 ~ 1.0)
  double get progress => _currentState.progress;

  /// 타이머 실행 중 여부
  bool get isRunning => _currentState.isRunning;

  /// 현재 모드가 집중 모드인지
  bool get isFocusMode => _currentState.isFocusMode;

  /// 현재 모드가 휴식 모드인지
  bool get isBreakMode => _currentState.isBreakMode;

  /// 포맷된 시간 문자열 (MM:SS)
  String get formattedTime => _currentState.formattedTime;
}
