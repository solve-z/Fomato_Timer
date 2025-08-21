import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timer_provider.dart';
import '../providers/farm_provider.dart';
import '../models/timer_state.dart';

/// 타이머 메인 화면
/// 
/// 25분 집중 타이머의 핵심 기능을 담당합니다.
/// - 큰 원형 타이머 표시
/// - 집중/휴식 모드 전환
/// - 농장 선택
/// - 진행도 표시
class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final selectedFarm = ref.watch(selectedFarmProvider);
    final farmList = ref.watch(farmListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fomato Timer'),
        centerTitle: true,
        actions: [
          // 농장 선택 버튼
          IconButton(
            icon: const Icon(Icons.grass),
            onPressed: () => _showFarmSelector(context, ref),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 선택된 농장 표시
            if (selectedFarm != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Color(int.parse(selectedFarm.color.substring(1), radix: 16) + 0xFF000000),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedFarm.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        '🍅 ${selectedFarm.tomatoCount}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 메인 타이머 영역
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 현재 모드 표시
                    Text(
                      _getModeText(timerState.mode),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: _getModeColor(timerState.mode),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 원형 타이머 (임시로 Container 사용)
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getModeColor(timerState.mode),
                          width: 4,
                        ),
                        color: _getModeColor(timerState.mode).withValues(alpha: 0.1),
                      ),
                      child: Center(
                        child: Text(
                          timerState.formattedTime,
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getModeColor(timerState.mode),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 진행도 표시 (● ○ ○ ○)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(timerState.totalRounds, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < timerState.currentRound ? Icons.circle : Icons.circle_outlined,
                            color: _getModeColor(timerState.mode),
                            size: 16,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 40),

                    // 컨트롤 버튼들
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 시작/일시정지 버튼
                        ElevatedButton.icon(
                          onPressed: () {
                            if (timerState.isRunning) {
                              ref.read(timerProvider.notifier).pause();
                            } else {
                              ref.read(timerProvider.notifier).start();
                            }
                          },
                          icon: Icon(
                            timerState.isRunning ? Icons.pause : Icons.play_arrow,
                          ),
                          label: Text(
                            timerState.isRunning ? '일시정지' : '시작',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getModeColor(timerState.mode),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),

                        // 정지 버튼
                        OutlinedButton.icon(
                          onPressed: () {
                            ref.read(timerProvider.notifier).stop();
                          },
                          icon: const Icon(Icons.stop),
                          label: const Text('정지'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 농장 선택 다이얼로그
  void _showFarmSelector(BuildContext context, WidgetRef ref) {
    final farmList = ref.read(farmListProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('농장 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: farmList.map((farm) {
            return ListTile(
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(int.parse(farm.color.substring(1), radix: 16) + 0xFF000000),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(farm.name),
              trailing: Text('🍅 ${farm.tomatoCount}'),
              onTap: () {
                ref.read(selectedFarmProvider.notifier).state = farm;
                ref.read(timerProvider.notifier).selectFarm(farm.id);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  /// 모드별 텍스트 반환
  String _getModeText(TimerMode mode) {
    switch (mode) {
      case TimerMode.focus:
        return '집중 시간';
      case TimerMode.shortBreak:
        return '짧은 휴식';
      case TimerMode.longBreak:
        return '긴 휴식';
      case TimerMode.stopped:
        return '정지';
    }
  }

  /// 모드별 색상 반환
  Color _getModeColor(TimerMode mode) {
    switch (mode) {
      case TimerMode.focus:
        return Colors.red.shade400;      // 집중: 빨간색
      case TimerMode.shortBreak:
        return Colors.green.shade400;    // 짧은 휴식: 녹색
      case TimerMode.longBreak:
        return Colors.blue.shade400;     // 긴 휴식: 파란색
      case TimerMode.stopped:
        return Colors.grey.shade400;     // 정지: 회색
    }
  }
}