import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/statistics_provider.dart';
import '../providers/farm_provider.dart';
import '../widgets/daily_detail_dialog.dart';
import '../models/statistics.dart';

/// 통계 화면
///
/// 토마토 수확 통계를 캘린더와 요약 정보로 표시합니다.
/// - 월간 캘린더 뷰
/// - 농장별 필터링
/// - 월간 통계 요약
/// - 일별 상세 정보
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  DateTime? selectedDate; // 선택된 날짜

  @override
  Widget build(BuildContext context) {
    final statisticsState = ref.watch(statisticsProvider);
    final monthlyStats = ref.watch(currentMonthStatsProvider);
    final farmList = ref.watch(farmListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('통계'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 농장 필터 드롭다운
            _buildFarmFilter(
              context,
              ref,
              farmList,
              statisticsState.selectedFarmId,
            ),
            const SizedBox(height: 20),

            // 월 선택 헤더
            _buildMonthSelector(context, ref, statisticsState.selectedMonth),
            const SizedBox(height: 20),

            // 월간 요약 카드들
            _buildMonthlySummary(context, monthlyStats),
            const SizedBox(height: 20),

            // 캘린더
            _buildCalendarPlaceholder(context, ref, statisticsState),

            // 선택된 날짜 정보
            if (selectedDate != null) ...[
              const SizedBox(height: 20),
              _buildSelectedDateInfo(context, ref, statisticsState),
            ],
          ],
        ),
      ),
    );
  }

  /// 농장 필터 드롭다운
  Widget _buildFarmFilter(
    BuildContext context,
    WidgetRef ref,
    List farmList,
    String? selectedFarmId,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.filter_list),
            const SizedBox(width: 12),
            const Text('농장 필터:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<String?>(
                value: selectedFarmId,
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('전체 농장'),
                  ),
                  ...farmList.map(
                    (farm) => DropdownMenuItem<String?>(
                      value: farm.id,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(farm.color.substring(1), radix: 16) +
                                    0xFF000000,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(farm.name),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: (farmId) {
                  ref.read(statisticsProvider.notifier).selectFarm(farmId);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 월 선택 헤더
  Widget _buildMonthSelector(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedMonth,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            ref.read(statisticsProvider.notifier).previousMonth();
          },
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          '${selectedMonth.year}년 ${selectedMonth.month}월',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: () {
            ref.read(statisticsProvider.notifier).nextMonth();
          },
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  /// 월간 통계 요약 카드들
  Widget _buildMonthlySummary(BuildContext context, monthlyStats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                '총 토마토',
                '${monthlyStats.totalTomatoes}개',
                Icons.eco,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                context,
                '활동 일수',
                '${monthlyStats.activeDays}일',
                Icons.calendar_today,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                '총 집중 시간',
                monthlyStats.formattedTotalTime,
                Icons.timer,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                context,
                '완료 세션',
                '${monthlyStats.totalSessions}회',
                Icons.check_circle,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                '일평균 토마토',
                '${monthlyStats.averageTomatoes.toStringAsFixed(1)}개',
                Icons.trending_up,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                context,
                '일평균 집중',
                '${monthlyStats.averageFocusMinutes.toStringAsFixed(0)}분',
                Icons.access_time,
                Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 개별 요약 카드
  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 월간 캘린더 그리드
  Widget _buildCalendarPlaceholder(
    BuildContext context,
    WidgetRef ref,
    statisticsState,
  ) {
    final dailySummaries = statisticsState.dailySummaries;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '월간 캘린더',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 월간 캘린더 그리드
            _buildCalendarGrid(context, ref, statisticsState, dailySummaries),
            const SizedBox(height: 12),

            // 범례
            _buildCalendarLegend(),
          ],
        ),
      ),
    );
  }

  /// 캘린더 그리드 생성
  Widget _buildCalendarGrid(
    BuildContext context,
    WidgetRef ref,
    statisticsState,
    List<DailySummary> dailySummaries,
  ) {
    final selectedMonth = statisticsState.selectedMonth;
    final firstDayOfMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    );
    final firstWeekday = firstDayOfMonth.weekday; // 1=월요일, 7=일요일

    // 월요일을 0으로 만들기 위해 조정 (0=월요일, 6=일요일)
    final startOffset = (firstWeekday - 1) % 7;
    final totalCells = 42; // 6주 x 7일

    // 날짜별 통계 맵 생성
    final dailyStatsMap = <int, DailySummary>{};
    for (final summary in dailySummaries) {
      dailyStatsMap[summary.date.day] = summary;
    }

    return Column(
      children: [
        // 요일 헤더
        _buildWeekdayHeader(),
        const SizedBox(height: 8),

        // 날짜 그리드
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final dayNumber = index - startOffset + 1;
            final isValidDay =
                dayNumber >= 1 && dayNumber <= lastDayOfMonth.day;

            if (!isValidDay) {
              // 빈 셀
              return Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.transparent),
                ),
              );
            }

            final currentDate = DateTime(
              selectedMonth.year,
              selectedMonth.month,
              dayNumber,
            );
            final dailySummary = dailyStatsMap[dayNumber];
            final tomatoCount = dailySummary?.totalTomatoes ?? 0;
            final isToday = _isToday(currentDate);

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedDate = currentDate;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _getDayBackgroundColor(
                    tomatoCount,
                    isToday,
                    _isSelectedDate(currentDate),
                  ),
                  border: Border.all(
                    color:
                        _isSelectedDate(currentDate)
                            ? Colors.orange
                            : (isToday ? Colors.blue : Colors.grey.shade200),
                    width: (_isSelectedDate(currentDate) || isToday) ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayNumber.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                          color:
                              _isSelectedDate(currentDate)
                                  ? Colors.orange
                                  : (isToday ? Colors.blue : Colors.black87),
                        ),
                      ),
                      if (tomatoCount > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          tomatoCount > 3 ? '🍅+' : '🍅' * tomatoCount,
                          style: const TextStyle(fontSize: 8),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// 요일 헤더
  Widget _buildWeekdayHeader() {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];

    return Row(
      children:
          weekdays
              .map(
                (weekday) => Expanded(
                  child: Center(
                    child: Text(
                      weekday,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  /// 캘린더 범례
  Widget _buildCalendarLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('활동 없음', Colors.grey.shade50),
        const SizedBox(width: 16),
        _buildLegendItem('1-2개', Colors.green.withValues(alpha: 0.3)),
        const SizedBox(width: 16),
        _buildLegendItem('3개 이상', Colors.green.withValues(alpha: 0.7)),
        const SizedBox(width: 16),
        _buildLegendItem('오늘', Colors.blue.withValues(alpha: 0.2)),
      ],
    );
  }

  /// 캘린더 범례 아이템
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  /// 날짜 배경색 결정
  Color _getDayBackgroundColor(int tomatoCount, bool isToday, bool isSelected) {
    if (isSelected) {
      return Colors.orange.withValues(alpha: 0.2);
    }

    if (isToday) {
      return Colors.blue.withValues(alpha: 0.2);
    }

    if (tomatoCount == 0) {
      return Colors.grey.shade50;
    } else if (tomatoCount <= 2) {
      return Colors.green.withValues(alpha: 0.3);
    } else {
      return Colors.green.withValues(alpha: 0.7);
    }
  }

  /// 오늘 날짜인지 확인
  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  /// 선택된 날짜인지 확인
  bool _isSelectedDate(DateTime date) {
    if (selectedDate == null) return false;
    return date.year == selectedDate!.year &&
        date.month == selectedDate!.month &&
        date.day == selectedDate!.day;
  }

  /// 선택된 날짜 정보 위젯
  Widget _buildSelectedDateInfo(
    BuildContext context,
    WidgetRef ref,
    statisticsState,
  ) {
    if (selectedDate == null) return const SizedBox.shrink();

    final dailySummary = statisticsState.getDailySummary(selectedDate!);
    final farmList = ref.watch(farmListProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${selectedDate!.month}월 ${selectedDate!.day}일 (${_getWeekdayString(selectedDate!.weekday)})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      selectedDate = null;
                    });
                  },
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (dailySummary.hasActivity) ...[
              // 활동 요약
              Row(
                children: [
                  _buildInfoChip('🍅', '${dailySummary.totalTomatoes}개'),
                  const SizedBox(width: 12),
                  _buildInfoChip('⏱️', dailySummary.formattedTotalTime),
                  const SizedBox(width: 12),
                  _buildInfoChip('🎯', '${dailySummary.totalSessions}회'),
                ],
              ),
              const SizedBox(height: 16),

              // 농장별 활동 목록
              Text(
                '농장별 활동',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...dailySummary.activities.map(
                (activity) =>
                    _buildFarmActivityRow(context, activity, farmList),
              ),
            ] else ...[
              // 활동 없음 상태
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.eco_outlined,
                      color: Colors.grey.shade400,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '이 날에는 활동이 없었습니다',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 정보 칩 위젯
  Widget _buildInfoChip(String emoji, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// 농장 활동 행
  Widget _buildFarmActivityRow(
    BuildContext context,
    DailyStats activity,
    List farmList,
  ) {
    final farm = farmList.where((f) => f.id == activity.farmId).firstOrNull;
    final farmName = farm?.name ?? '농장 없음';
    final farmColor =
        farm != null
            ? Color(int.parse(farm.color.substring(1), radix: 16) + 0xFF000000)
            : Colors.grey.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: farmColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: farmColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: farmColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              farmName,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '🍅 ${activity.tomatoCount}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 8),
          Text(
            '⏱️ ${activity.focusMinutes}분',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// 요일 문자열 변환
  String _getWeekdayString(int weekday) {
    switch (weekday) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '';
    }
  }
}
