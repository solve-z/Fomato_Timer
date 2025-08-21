/// 일일 통계 데이터
class DailyStats {
  final DateTime date;          // 날짜
  final int tomatoCount;        // 수확한 토마토 개수
  final int focusMinutes;       // 집중한 시간 (분)
  final int completedSessions; // 완료한 세션 수
  final String? farmId;         // 농장 ID (null이면 전체)

  const DailyStats({
    required this.date,
    required this.tomatoCount,
    required this.focusMinutes,
    required this.completedSessions,
    this.farmId,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: DateTime.parse(json['date'] as String),
      tomatoCount: json['tomatoCount'] as int,
      focusMinutes: json['focusMinutes'] as int,
      completedSessions: json['completedSessions'] as int,
      farmId: json['farmId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().substring(0, 10), // YYYY-MM-DD 형식
      'tomatoCount': tomatoCount,
      'focusMinutes': focusMinutes,
      'completedSessions': completedSessions,
      'farmId': farmId,
    };
  }

  DailyStats copyWith({
    DateTime? date,
    int? tomatoCount,
    int? focusMinutes,
    int? completedSessions,
    String? farmId,
  }) {
    return DailyStats(
      date: date ?? this.date,
      tomatoCount: tomatoCount ?? this.tomatoCount,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      completedSessions: completedSessions ?? this.completedSessions,
      farmId: farmId ?? this.farmId,
    );
  }

  @override
  String toString() {
    return 'DailyStats(date: $date, tomatoes: $tomatoCount, focus: ${focusMinutes}min)';
  }
}

/// 월간 통계 요약
class MonthlyStats {
  final int year;                    // 년도
  final int month;                   // 월
  final int totalTomatoes;           // 총 토마토 수확 개수
  final int totalFocusMinutes;       // 총 집중 시간 (분)
  final int totalSessions;           // 총 완료 세션 수
  final int activeDays;              // 활동한 날 수
  final List<DailyStats> dailyStats; // 일별 통계 목록

  const MonthlyStats({
    required this.year,
    required this.month,
    required this.totalTomatoes,
    required this.totalFocusMinutes,
    required this.totalSessions,
    required this.activeDays,
    required this.dailyStats,
  });

  /// 평균 집중 시간 (분)
  double get averageFocusMinutes {
    if (activeDays == 0) return 0.0;
    return totalFocusMinutes / activeDays;
  }

  /// 일평균 토마토 개수
  double get averageTomatoes {
    if (activeDays == 0) return 0.0;
    return totalTomatoes / activeDays;
  }

  /// 총 집중 시간을 시:분 형식으로 변환
  String get formattedTotalTime {
    final hours = totalFocusMinutes ~/ 60;
    final minutes = totalFocusMinutes % 60;
    return '$hours시간 $minutes분';
  }

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    return MonthlyStats(
      year: json['year'] as int,
      month: json['month'] as int,
      totalTomatoes: json['totalTomatoes'] as int,
      totalFocusMinutes: json['totalFocusMinutes'] as int,
      totalSessions: json['totalSessions'] as int,
      activeDays: json['activeDays'] as int,
      dailyStats: (json['dailyStats'] as List<dynamic>)
          .map((e) => DailyStats.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'totalTomatoes': totalTomatoes,
      'totalFocusMinutes': totalFocusMinutes,
      'totalSessions': totalSessions,
      'activeDays': activeDays,
      'dailyStats': dailyStats.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'MonthlyStats($year-$month: $totalTomatoes tomatoes, $formattedTotalTime, $activeDays days)';
  }
}

/// 전체 통계 상태
class StatisticsState {
  final List<DailyStats> allStats;     // 모든 일별 통계
  final String? selectedFarmId;        // 선택된 농장 ID (null이면 전체)
  final DateTime selectedMonth;        // 선택된 월

  const StatisticsState({
    required this.allStats,
    this.selectedFarmId,
    required this.selectedMonth,
  });

  factory StatisticsState.initial() {
    return StatisticsState(
      allStats: const [],
      selectedMonth: DateTime.now(),
    );
  }

  /// 선택된 농장과 월에 따른 필터링된 통계
  List<DailyStats> get filteredStats {
    return allStats.where((stat) {
      // 농장 필터링
      if (selectedFarmId != null && stat.farmId != selectedFarmId) {
        return false;
      }
      
      // 월 필터링
      return stat.date.year == selectedMonth.year && 
             stat.date.month == selectedMonth.month;
    }).toList();
  }

  /// 현재 선택된 월의 월간 통계 계산
  MonthlyStats get currentMonthStats {
    final filtered = filteredStats;
    
    return MonthlyStats(
      year: selectedMonth.year,
      month: selectedMonth.month,
      totalTomatoes: filtered.fold(0, (sum, stat) => sum + stat.tomatoCount),
      totalFocusMinutes: filtered.fold(0, (sum, stat) => sum + stat.focusMinutes),
      totalSessions: filtered.fold(0, (sum, stat) => sum + stat.completedSessions),
      activeDays: filtered.where((stat) => stat.tomatoCount > 0).length,
      dailyStats: filtered,
    );
  }

  StatisticsState copyWith({
    List<DailyStats>? allStats,
    String? selectedFarmId,
    DateTime? selectedMonth,
  }) {
    return StatisticsState(
      allStats: allStats ?? this.allStats,
      selectedFarmId: selectedFarmId ?? this.selectedFarmId,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }

  @override
  String toString() {
    return 'StatisticsState(stats: ${allStats.length}, farm: $selectedFarmId, month: $selectedMonth)';
  }
}