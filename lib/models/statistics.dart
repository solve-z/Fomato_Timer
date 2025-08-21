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

/// 일별 활동 요약 데이터
/// 특정 날짜의 모든 농장 활동을 통합한 요약 정보
class DailySummary {
  final DateTime date;              // 날짜
  final int totalTomatoes;          // 총 토마토 수확 개수
  final int totalFocusMinutes;      // 총 집중 시간 (분)
  final int totalSessions;          // 총 완료 세션 수
  final int farmCount;              // 활동한 농장 수 (농장 없음 포함)
  final List<DailyStats> activities; // 개별 농장 활동 목록

  const DailySummary({
    required this.date,
    required this.totalTomatoes,
    required this.totalFocusMinutes,
    required this.totalSessions,
    required this.farmCount,
    required this.activities,
  });

  /// 해당 날짜에 활동이 있었는지 확인
  bool get hasActivity => totalTomatoes > 0;

  /// 총 집중 시간을 시:분 형식으로 변환
  String get formattedTotalTime {
    final hours = totalFocusMinutes ~/ 60;
    final minutes = totalFocusMinutes % 60;
    if (hours > 0) {
      return '$hours시간 $minutes분';
    } else {
      return '$minutes분';
    }
  }

  /// 농장별 활동 정보를 Map으로 반환
  Map<String, DailyStats> get farmActivitiesMap {
    final Map<String, DailyStats> farmActivities = {};
    for (final activity in activities) {
      final farmKey = activity.farmId ?? '농장 없음';
      farmActivities[farmKey] = activity;
    }
    return farmActivities;
  }

  /// 가장 많은 토마토를 수확한 농장 정보
  DailyStats? get topFarmActivity {
    if (activities.isEmpty) return null;
    return activities.reduce((a, b) => a.tomatoCount > b.tomatoCount ? a : b);
  }

  @override
  String toString() {
    return 'DailySummary($date: $totalTomatoes tomatoes, $farmCount farms, $formattedTotalTime)';
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
    // 먼저 선택된 월의 데이터만 필터링
    final monthFiltered = allStats.where((stat) {
      return stat.date.year == selectedMonth.year && 
             stat.date.month == selectedMonth.month;
    }).toList();
    
    // 농장 필터링 적용
    if (selectedFarmId == null) {
      // 전체 통계: 농장 선택 안 한 활동(farmId==null)도 포함하여 모든 데이터 표시
      return monthFiltered;
    } else {
      // 특정 농장 통계: 해당 농장의 데이터만 표시
      return monthFiltered.where((stat) => stat.farmId == selectedFarmId).toList();
    }
  }

  /// 현재 선택된 월의 월간 통계 계산
  MonthlyStats get currentMonthStats {
    final filtered = filteredStats;
    
    // 중복 제거를 위해 고유한 날짜들만 추출
    final uniqueDates = <DateTime>{};
    for (final stat in filtered) {
      if (stat.tomatoCount > 0) {
        // 날짜만 비교하기 위해 시간 정보 제거
        uniqueDates.add(DateTime(stat.date.year, stat.date.month, stat.date.day));
      }
    }
    
    return MonthlyStats(
      year: selectedMonth.year,
      month: selectedMonth.month,
      totalTomatoes: filtered.fold(0, (sum, stat) => sum + stat.tomatoCount),
      totalFocusMinutes: filtered.fold(0, (sum, stat) => sum + stat.focusMinutes),
      totalSessions: filtered.fold(0, (sum, stat) => sum + stat.completedSessions),
      activeDays: uniqueDates.length, // 고유한 날짜의 개수로 계산
      dailyStats: filtered,
    );
  }

  /// 특정 날짜의 모든 농장 활동 조회
  List<DailyStats> getActivitiesByDate(DateTime targetDate) {
    return allStats.where((stat) => 
      stat.date.year == targetDate.year &&
      stat.date.month == targetDate.month &&
      stat.date.day == targetDate.day
    ).toList();
  }

  /// 특정 날짜의 농장별 활동 요약
  Map<String, DailyStats> getFarmActivitiesByDate(DateTime targetDate) {
    final activities = getActivitiesByDate(targetDate);
    final Map<String, DailyStats> farmActivities = {};
    
    for (final activity in activities) {
      final farmKey = activity.farmId ?? '농장 없음';
      farmActivities[farmKey] = activity;
    }
    
    return farmActivities;
  }

  /// 특정 날짜의 총 활동 요약
  DailySummary getDailySummary(DateTime targetDate) {
    final activities = getActivitiesByDate(targetDate);
    
    return DailySummary(
      date: targetDate,
      totalTomatoes: activities.fold(0, (sum, stat) => sum + stat.tomatoCount),
      totalFocusMinutes: activities.fold(0, (sum, stat) => sum + stat.focusMinutes),
      totalSessions: activities.fold(0, (sum, stat) => sum + stat.completedSessions),
      farmCount: activities.length,
      activities: activities,
    );
  }

  /// 선택된 월의 모든 날짜별 요약 조회
  List<DailySummary> get dailySummaries {
    final Map<String, List<DailyStats>> groupedByDate = {};
    
    // 선택된 월의 데이터를 날짜별로 그룹화
    for (final stat in allStats) {
      if (stat.date.year == selectedMonth.year && 
          stat.date.month == selectedMonth.month) {
        final dateKey = '${stat.date.year}-${stat.date.month.toString().padLeft(2, '0')}-${stat.date.day.toString().padLeft(2, '0')}';
        groupedByDate.putIfAbsent(dateKey, () => []).add(stat);
      }
    }
    
    // 각 날짜별로 요약 생성
    final summaries = <DailySummary>[];
    for (final entry in groupedByDate.entries) {
      final dateStr = entry.key;
      final activities = entry.value;
      final date = DateTime.parse(dateStr);
      
      summaries.add(DailySummary(
        date: date,
        totalTomatoes: activities.fold(0, (sum, stat) => sum + stat.tomatoCount),
        totalFocusMinutes: activities.fold(0, (sum, stat) => sum + stat.focusMinutes),
        totalSessions: activities.fold(0, (sum, stat) => sum + stat.completedSessions),
        farmCount: activities.length,
        activities: activities,
      ));
    }
    
    // 날짜순으로 정렬
    summaries.sort((a, b) => a.date.compareTo(b.date));
    return summaries;
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