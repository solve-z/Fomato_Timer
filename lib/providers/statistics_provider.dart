import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/statistics.dart';
import '../services/storage_service.dart';

/// 통계 상태 관리 클래스
class StatisticsNotifier extends StateNotifier<StatisticsState> {
  StatisticsNotifier() : super(StatisticsState.initial()) {
    _loadInitialStats();
  }

  /// 초기 통계 데이터 로드 (SharedPreferences에서 로드)
  void _loadInitialStats() async {
    try {
      final savedStats = await StorageService.loadStatistics();
      if (savedStats.isNotEmpty) {
        state = state.copyWith(allStats: savedStats);
      } else {
        // 저장된 통계가 없으면 빈 상태로 시작
        state = state.copyWith(allStats: <DailyStats>[]);
      }
    } catch (e) {
      // 에러 발생 시 빈 상태로 시작
      state = state.copyWith(allStats: <DailyStats>[]);
    }
  }

  /// 통계 데이터를 저장소에 저장
  Future<void> _saveStats() async {
    await StorageService.saveStatistics(state.allStats);
  }

  /// 일일 통계 추가/업데이트
  void addOrUpdateDailyStats(DailyStats newStats) async {
    final existingIndex = state.allStats.indexWhere(
      (stats) => 
          stats.date.year == newStats.date.year &&
          stats.date.month == newStats.date.month &&
          stats.date.day == newStats.date.day &&
          stats.farmId == newStats.farmId,
    );

    List<DailyStats> updatedStats;
    if (existingIndex >= 0) {
      // 기존 데이터 업데이트
      updatedStats = [...state.allStats];
      updatedStats[existingIndex] = newStats;
    } else {
      // 새 데이터 추가
      updatedStats = [...state.allStats, newStats];
    }

    state = state.copyWith(allStats: updatedStats);
    await _saveStats();
  }

  /// 토마토 수확 기록 (타이머 완료 시 호출)
  void recordTomatoHarvest({
    required String farmId,
    required DateTime date,
    int focusMinutes = 25,
  }) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    // 오늘 해당 농장의 기존 통계 찾기
    final existingStats = state.allStats.where(
      (stats) => 
          stats.date.year == dateOnly.year &&
          stats.date.month == dateOnly.month &&
          stats.date.day == dateOnly.day &&
          stats.farmId == farmId,
    ).firstOrNull;

    DailyStats newStats;
    if (existingStats != null) {
      // 기존 통계에 추가
      newStats = existingStats.copyWith(
        tomatoCount: existingStats.tomatoCount + 1,
        focusMinutes: existingStats.focusMinutes + focusMinutes,
        completedSessions: existingStats.completedSessions + 1,
      );
    } else {
      // 새 통계 생성
      newStats = DailyStats(
        date: dateOnly,
        tomatoCount: 1,
        focusMinutes: focusMinutes,
        completedSessions: 1,
        farmId: farmId,
      );
    }

    addOrUpdateDailyStats(newStats);
  }

  /// 선택된 농장 변경
  void selectFarm(String? farmId) {
    state = state.copyWith(selectedFarmId: farmId);
  }

  /// 오늘 수확한 총 토마토 개수 반환
  int getTodayTotalTomatoCount() {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    
    // 오늘 날짜의 모든 농장 통계 합계
    final todayStats = state.allStats.where(
      (stats) => 
          stats.date.year == todayOnly.year &&
          stats.date.month == todayOnly.month &&
          stats.date.day == todayOnly.day,
    );
    
    return todayStats.fold(0, (sum, stats) => sum + stats.tomatoCount);
  }

  /// 선택된 월 변경
  void selectMonth(DateTime month) {
    state = state.copyWith(selectedMonth: month);
  }

  /// 이전 달로 이동
  void previousMonth() {
    final previousMonth = DateTime(
      state.selectedMonth.year,
      state.selectedMonth.month - 1,
    );
    selectMonth(previousMonth);
  }

  /// 다음 달로 이동
  void nextMonth() {
    final nextMonth = DateTime(
      state.selectedMonth.year,
      state.selectedMonth.month + 1,
    );
    selectMonth(nextMonth);
  }

  /// 특정 날짜의 통계 가져오기
  List<DailyStats> getStatsForDate(DateTime date) {
    return state.allStats.where(
      (stats) =>
          stats.date.year == date.year &&
          stats.date.month == date.month &&
          stats.date.day == date.day,
    ).toList();
  }

  /// 특정 농장의 월간 통계 계산
  MonthlyStats getMonthlyStatsForFarm(String? farmId, DateTime month) {
    final filteredStats = state.allStats.where((stat) {
      // 농장 필터링
      if (farmId != null && stat.farmId != farmId) return false;
      
      // 월 필터링
      return stat.date.year == month.year && 
             stat.date.month == month.month;
    }).toList();

    return MonthlyStats(
      year: month.year,
      month: month.month,
      totalTomatoes: filteredStats.fold(0, (sum, stat) => sum + stat.tomatoCount),
      totalFocusMinutes: filteredStats.fold(0, (sum, stat) => sum + stat.focusMinutes),
      totalSessions: filteredStats.fold(0, (sum, stat) => sum + stat.completedSessions),
      activeDays: filteredStats.where((stat) => stat.tomatoCount > 0).length,
      dailyStats: filteredStats,
    );
  }
}

/// 통계 상태 Provider
final statisticsProvider = StateNotifierProvider<StatisticsNotifier, StatisticsState>((ref) {
  return StatisticsNotifier();
});

/// 현재 월간 통계 Provider
final currentMonthStatsProvider = Provider<MonthlyStats>((ref) {
  final statisticsState = ref.watch(statisticsProvider);
  return statisticsState.currentMonthStats;
});

/// 특정 날짜의 통계 Provider
final dailyStatsProvider = Provider.family<List<DailyStats>, DateTime>((ref, date) {
  final statisticsNotifier = ref.watch(statisticsProvider.notifier);
  return statisticsNotifier.getStatsForDate(date);
});

/// 선택된 농장의 월간 통계 Provider
final selectedFarmMonthlyStatsProvider = Provider<MonthlyStats>((ref) {
  final statisticsState = ref.watch(statisticsProvider);
  final statisticsNotifier = ref.watch(statisticsProvider.notifier);
  
  return statisticsNotifier.getMonthlyStatsForFarm(
    statisticsState.selectedFarmId,
    statisticsState.selectedMonth,
  );
});