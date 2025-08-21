import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/statistics_provider.dart';
import '../providers/farm_provider.dart';

/// 통계 화면
/// 
/// 토마토 수확 통계를 캘린더와 요약 정보로 표시합니다.
/// - 월간 캘린더 뷰
/// - 농장별 필터링
/// - 월간 통계 요약
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsState = ref.watch(statisticsProvider);
    final monthlyStats = ref.watch(currentMonthStatsProvider);
    final farmList = ref.watch(farmListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('통계'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 농장 필터 드롭다운
            _buildFarmFilter(context, ref, farmList, statisticsState.selectedFarmId),
            const SizedBox(height: 20),

            // 월 선택 헤더
            _buildMonthSelector(context, ref, statisticsState.selectedMonth),
            const SizedBox(height: 20),

            // 월간 요약 카드들
            _buildMonthlySummary(context, monthlyStats),
            const SizedBox(height: 20),

            // 캘린더 (임시 구현)
            _buildCalendarPlaceholder(context, ref, statisticsState),
          ],
        ),
      ),
    );
  }

  /// 농장 필터 드롭다운
  Widget _buildFarmFilter(BuildContext context, WidgetRef ref, List farmList, String? selectedFarmId) {
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
                  ...farmList.map((farm) => DropdownMenuItem<String?>(
                    value: farm.id,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(int.parse(farm.color.substring(1), radix: 16) + 0xFF000000),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(farm.name),
                      ],
                    ),
                  )),
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
  Widget _buildMonthSelector(BuildContext context, WidgetRef ref, DateTime selectedMonth) {
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
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

  /// 캘린더 임시 구현 (나중에 table_calendar 사용)
  Widget _buildCalendarPlaceholder(BuildContext context, WidgetRef ref, statisticsState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '월간 캘린더',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 임시 캘린더 그리드 (7x6)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: 42, // 6주 x 7일
              itemBuilder: (context, index) {
                // 임시로 랜덤하게 토마토 표시
                final dayNumber = (index % 31) + 1;
                final hasTomatoes = (index + dayNumber) % 5 == 0;
                final tomatoCount = hasTomatoes ? (index % 3) + 1 : 0;
                
                return Container(
                  decoration: BoxDecoration(
                    color: tomatoCount > 0 
                        ? Colors.green.withValues(alpha: 0.1 + (tomatoCount * 0.2))
                        : Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayNumber <= 31 ? dayNumber.toString() : '',
                          style: TextStyle(
                            fontSize: 10,
                            color: dayNumber <= 31 ? Colors.black87 : Colors.transparent,
                          ),
                        ),
                        if (tomatoCount > 0)
                          Text(
                            '🍅',
                            style: const TextStyle(fontSize: 8),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            
            // 범례
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('토마토 없음', Colors.grey.shade50),
                const SizedBox(width: 16),
                _buildLegendItem('1-2개', Colors.green.withValues(alpha: 0.3)),
                const SizedBox(width: 16),
                _buildLegendItem('3개 이상', Colors.green.withValues(alpha: 0.7)),
              ],
            ),
          ],
        ),
      ),
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
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}