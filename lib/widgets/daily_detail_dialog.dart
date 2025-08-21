import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/statistics.dart';
import '../providers/farm_provider.dart';
import '../utils/constants.dart';

/// 일별 활동 상세 보기 다이얼로그
/// 
/// 특정 날짜에 수행한 모든 농장 활동을 보여줍니다.
class DailyDetailDialog extends ConsumerWidget {
  final DailySummary dailySummary;

  const DailyDetailDialog({
    super.key,
    required this.dailySummary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmList = ref.watch(farmListProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            _buildHeader(context),
            
            // 내용
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 총 요약
                    _buildTotalSummary(context),
                    const SizedBox(height: 20),
                    
                    // 농장별 활동 목록
                    if (dailySummary.activities.isNotEmpty) ...[
                      _buildSectionTitle(context, '농장별 활동'),
                      const SizedBox(height: 12),
                      ...dailySummary.activities.map((activity) => 
                        _buildFarmActivityCard(context, activity, farmList)
                      ),
                    ] else
                      _buildEmptyState(context),
                  ],
                ),
              ),
            ),
            
            // 닫기 버튼
            _buildCloseButton(context),
          ],
        ),
      ),
    );
  }

  /// 헤더 (날짜 및 아이콘)
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSizes.cardBorderRadius),
          topRight: Radius.circular(AppSizes.cardBorderRadius),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSizes.buttonBorderRadius),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dailySummary.date.month}월 ${dailySummary.date.day}일',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _getWeekdayString(dailySummary.date.weekday),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (dailySummary.hasActivity)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(AppSizes.buttonBorderRadius),
              ),
              child: const Text(
                '활동',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 총 요약 정보
  Widget _buildTotalSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.buttonBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildSummaryItem(
                context,
                '🍅',
                '${dailySummary.totalTomatoes}개',
                '토마토 수확',
              ),
              const SizedBox(width: 20),
              _buildSummaryItem(
                context,
                '⏱️',
                dailySummary.formattedTotalTime,
                '총 집중 시간',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryItem(
                context,
                '🎯',
                '${dailySummary.totalSessions}회',
                '완료 세션',
              ),
              const SizedBox(width: 20),
              _buildSummaryItem(
                context,
                '🏠',
                '${dailySummary.farmCount}개',
                '활동한 농장',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 요약 아이템
  Widget _buildSummaryItem(
    BuildContext context,
    String emoji,
    String value,
    String label,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 섹션 제목
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  /// 농장 활동 카드
  Widget _buildFarmActivityCard(BuildContext context, DailyStats activity, List farmList) {
    // 농장 정보 찾기
    final farm = farmList.where((f) => f.id == activity.farmId).firstOrNull;
    final farmName = farm?.name ?? '농장 없음';
    final farmColor = farm != null 
        ? Color(int.parse(farm.color.substring(1), radix: 16) + 0xFF000000)
        : AppColors.disabled;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.buttonBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // 농장 색상 점
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: farmColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          
          // 농장 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farmName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '🍅 ${activity.tomatoCount}개',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '⏱️ ${activity.focusMinutes}분',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 세션 수
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: farmColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.buttonBorderRadius),
            ),
            child: Text(
              '${activity.completedSessions}세션',
              style: TextStyle(
                color: farmColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 활동 없음 상태
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.eco_outlined,
            size: 48,
            color: AppColors.disabled,
          ),
          const SizedBox(height: 16),
          Text(
            '이 날에는 활동이 없었습니다',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '뽀모도로 타이머로 토마토를 수확해보세요!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.disabled,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 닫기 버튼
  Widget _buildCloseButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ),
    );
  }

  /// 요일 문자열 변환
  String _getWeekdayString(int weekday) {
    switch (weekday) {
      case 1: return '월요일';
      case 2: return '화요일';
      case 3: return '수요일';
      case 4: return '목요일';
      case 5: return '금요일';
      case 6: return '토요일';
      case 7: return '일요일';
      default: return '';
    }
  }
}

/// 일별 상세 보기 다이얼로그를 보여주는 헬퍼 함수
void showDailyDetailDialog(BuildContext context, DailySummary dailySummary) {
  showDialog(
    context: context,
    builder: (context) => DailyDetailDialog(dailySummary: dailySummary),
  );
}