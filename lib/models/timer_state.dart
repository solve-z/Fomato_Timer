import '../utils/constants.dart';

/// 타이머 상태 열거형
enum TimerMode {
  focus, // 집중 모드 (25분)
  shortBreak, // 짧은 휴식 (5분)
  longBreak, // 긴 휴식 (15분)
  stopped, // 정지 상태
}

/// 타이머 실행 상태
enum TimerStatus {
  initial, // 초기 상태
  running, // 실행 중
  paused, // 일시정지
  completed, // 완료
}

/// 타이머 상태 모델
///
/// 뽀모도로 타이머의 모든 상태 정보를 담고 있습니다.
class TimerState {
  final TimerMode mode; // 현재 모드 (집중/휴식)
  final TimerStatus status; // 실행 상태
  final int remainingSeconds; // 남은 시간 (초)
  final int totalSeconds; // 전체 시간 (초)
  final int currentRound; // 현재 라운드 (1-4)
  final int totalRounds; // 총 라운드 수
  final String? selectedFarmId; // 선택된 농장 ID
  final DateTime? startTime; // 시작 시간
  final DateTime? endTime; // 종료 시간

  const TimerState({
    required this.mode,
    required this.status,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.currentRound,
    required this.totalRounds,
    this.selectedFarmId,
    this.startTime,
    this.endTime,
  });

  /// 초기 타이머 상태
  factory TimerState.initial() {
    return TimerState(
      mode: TimerMode.focus,
      status: TimerStatus.initial,
      remainingSeconds: AppConstants.defaultFocusMinutes * 60,
      totalSeconds: AppConstants.defaultFocusMinutes * 60,
      currentRound: 1,
      totalRounds: AppConstants.defaultRoundsUntilLongBreak,
    );
  }

  /// JSON에서 TimerState 객체 생성
  factory TimerState.fromJson(Map<String, dynamic> json) {
    return TimerState(
      mode: TimerMode.values[json['mode'] as int],
      status: TimerStatus.values[json['status'] as int],
      remainingSeconds: json['remainingSeconds'] as int,
      totalSeconds: json['totalSeconds'] as int,
      currentRound: json['currentRound'] as int,
      totalRounds: json['totalRounds'] as int,
      selectedFarmId: json['selectedFarmId'] as String?,
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime'] as String) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
    );
  }

  /// TimerState 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'mode': mode.index,
      'status': status.index,
      'remainingSeconds': remainingSeconds,
      'totalSeconds': totalSeconds,
      'currentRound': currentRound,
      'totalRounds': totalRounds,
      'selectedFarmId': selectedFarmId,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  /// 상태 업데이트한 새로운 TimerState 객체 생성
  TimerState copyWith({
    TimerMode? mode,
    TimerStatus? status,
    int? remainingSeconds,
    int? totalSeconds,
    int? currentRound,
    int? totalRounds,
    String? selectedFarmId,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return TimerState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      selectedFarmId: selectedFarmId ?? this.selectedFarmId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  /// 진행률 계산 (0.0 ~ 1.0)
  double get progress {
    if (totalSeconds == 0) return 0.0;
    return (totalSeconds - remainingSeconds) / totalSeconds;
  }

  /// 남은 시간을 MM:SS 형식으로 변환
  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 현재 모드가 집중 모드인지 확인
  bool get isFocusMode => mode == TimerMode.focus;

  /// 현재 모드가 휴식 모드인지 확인
  bool get isBreakMode => mode == TimerMode.shortBreak || mode == TimerMode.longBreak;

  /// 타이머가 실행 중인지 확인
  bool get isRunning => status == TimerStatus.running;

  /// 타이머가 완료되었는지 확인
  bool get isCompleted => status == TimerStatus.completed;

  @override
  String toString() {
    return 'TimerState(mode: $mode, status: $status, time: $formattedTime, round: $currentRound/$totalRounds)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimerState &&
        other.mode == mode &&
        other.status == status &&
        other.remainingSeconds == remainingSeconds &&
        other.currentRound == currentRound;
  }

  @override
  int get hashCode {
    return Object.hash(mode, status, remainingSeconds, currentRound);
  }
}
