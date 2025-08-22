import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timer_provider.dart';
import '../providers/farm_provider.dart';
import '../providers/task_provider.dart';
import '../models/farm.dart';
import '../models/timer_state.dart';
import '../utils/constants.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fomato Timer'),
        centerTitle: true,
        actions: [
          // 설정 버튼 (나중에 사용)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 설정 화면으로 이동 (추후 구현)
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 농장 선택 영역
            GestureDetector(
              onTap: () => _showFarmSelector(context, ref),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: selectedFarm != null
                      ? Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Color(int.parse(selectedFarm.color.substring(1), radix: 16) + 0xFF000000),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedFarm.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '🍅 ${selectedFarm.tomatoCount}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Icon(
                              Icons.grass_outlined,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '농장을 선택하세요...',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 메인 타이머 영역
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 현재 모드 표시
                    Text(
                      '집중 시간',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: TimerColors.modeColors[timerState.mode] ?? Colors.grey,
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
                          color: TimerColors.modeColors[timerState.mode] ?? Colors.grey,
                          width: 4,
                        ),
                        color: (TimerColors.modeColors[timerState.mode] ?? Colors.grey).withValues(alpha: 0.1),
                      ),
                      child: Center(
                        child: Text(
                          timerState.formattedTime,
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: TimerColors.modeColors[timerState.mode] ?? Colors.grey,
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
                            color: TimerColors.modeColors[timerState.mode] ?? Colors.grey,
                            size: 16,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 40),

                    // 컨트롤 버튼들
                    _buildTimerButtons(context, ref, timerState),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 농장 선택 바텀시트
  void _showFarmSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _FarmSelectorBottomSheet(
          scrollController: scrollController,
          onFarmSelected: (farm) {
            ref.read(selectedFarmProvider.notifier).selectFarm(farm);
            ref.read(timerProvider.notifier).selectFarm(farm.id);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  /// 타이머 상태에 따른 버튼들 빌드
  Widget _buildTimerButtons(BuildContext context, WidgetRef ref, timerState) {
    // 초기 상태: 시작 버튼만 표시
    if (timerState.status == TimerStatus.initial) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => ref.read(timerProvider.notifier).start(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('시작'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TimerColors.modeColors[timerState.mode] ?? Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }
    
    // 실행 중: 일시정지 버튼만 표시
    else if (timerState.status == TimerStatus.running) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => ref.read(timerProvider.notifier).pause(),
            icon: const Icon(Icons.pause),
            label: const Text('일시정지'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      );
    }
    
    // 완료 상태: 다음 모드 버튼 표시
    else if (timerState.status == TimerStatus.completed) {
      return Column(
        children: [
          // 완료 메시지
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  timerState.mode == TimerMode.focus ? '집중 완료! 토마토 수확 🍅' : '휴식 완료!',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // 다음 모드 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => ref.read(timerProvider.notifier).nextMode(),
                icon: const Icon(Icons.arrow_forward),
                label: Text(_getNextModeText(timerState)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 리셋 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showResetConfirmation(context, ref),
                icon: const Icon(Icons.refresh),
                label: const Text('리셋'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  side: BorderSide(color: Colors.grey.shade600),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      );
    }
    
    // 일시정지 상태: 재시작, 정지, 리셋 버튼 표시
    else {
      return Column(
        children: [
          // 첫 번째 행: 재시작 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => ref.read(timerProvider.notifier).resume(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('재시작'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TimerColors.modeColors[timerState.mode] ?? Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 두 번째 행: 정지, 리셋 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showStopConfirmation(context, ref),
                icon: const Icon(Icons.stop),
                label: const Text('정지'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade600),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showResetConfirmation(context, ref),
                icon: const Icon(Icons.refresh),
                label: const Text('리셋'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  side: BorderSide(color: Colors.grey.shade600),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  /// 다음 모드 텍스트 가져오기
  String _getNextModeText(TimerState timerState) {
    switch (timerState.mode) {
      case TimerMode.focus:
        // 집중 완료 후 짧은 휴식 또는 긴 휴식
        final isLongBreak = timerState.currentRound >= timerState.totalRounds;
        return isLongBreak ? '긴 휴식 시작' : '짧은 휴식 시작';
      case TimerMode.shortBreak:
        return '집중 모드 시작';
      case TimerMode.longBreak:
        return '집중 모드 시작';
      case TimerMode.stopped:
        return '시작';
    }
  }

  /// 정지 확인 다이얼로그
  void _showStopConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('타이머 정지'),
          ],
        ),
        content: const Text(
          '현재 진행 중인 타이머를 정지하시겠습니까?\n'
          '진행 상황은 유지되지만 타이머는 멈춥니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(timerProvider.notifier).stop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('정지', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 리셋 확인 다이얼로그
  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('타이머 리셋'),
          ],
        ),
        content: const Text(
          '타이머를 완전히 초기화하시겠습니까?\n'
          '현재 라운드와 진행 상황이 모두 초기화됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(timerProvider.notifier).reset();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('리셋', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// 농장 선택 바텀시트 위젯
class _FarmSelectorBottomSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final Function(Farm) onFarmSelected;

  const _FarmSelectorBottomSheet({
    required this.scrollController,
    required this.onFarmSelected,
  });

  @override
  ConsumerState<_FarmSelectorBottomSheet> createState() => _FarmSelectorBottomSheetState();
}

class _FarmSelectorBottomSheetState extends ConsumerState<_FarmSelectorBottomSheet> {
  Farm? _selectedFarm;
  final TextEditingController _taskController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final farmList = ref.watch(farmListProvider);
    final currentSelected = ref.watch(selectedFarmProvider);

    // 선택된 농장이 없으면 첫 번째 농장이나 가장 최근 선택된 농장을 기본 선택
    if (_selectedFarm == null && farmList.isNotEmpty) {
      _selectedFarm = currentSelected ?? farmList.first;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 핸들 바
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // 제목
          Row(
            children: [
              const Text(
                '농장 선택',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 농장이 없는 경우
          if (farmList.isEmpty) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.grass_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '농장 없음',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '집중할 프로젝트를 위한\n첫 번째 농장을 만들어보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showCreateFarmDialog(context, ref);
              },
              icon: const Icon(Icons.add),
              label: const Text('농장 만들기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ]
          // 농장이 있는 경우
          else ...[
            Expanded(
              child: ListView(
                controller: widget.scrollController,
                children: [
                  // 농장 목록
                  ...farmList.map((farm) {
                    final isSelected = _selectedFarm?.id == farm.id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isSelected ? Color(int.parse(farm.color.substring(1), radix: 16) + 0xFF000000).withValues(alpha: 0.1) : null,
                      child: ListTile(
                        leading: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(int.parse(farm.color.substring(1), radix: 16) + 0xFF000000),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                farm.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () => _showQuickAddTask(context, farm),
                              tooltip: '할일 추가',
                            ),
                          ],
                        ),
                        subtitle: Text('🍅 ${farm.tomatoCount}개 수확'),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedFarm = farm;
                          });
                        },
                      ),
                    );
                  }),

                  // 선택된 농장의 할일 목록
                  if (_selectedFarm != null) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    Text(
                      '${_selectedFarm!.name}의 할일',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Consumer(
                      builder: (context, ref, child) {
                        final farmTasks = ref.watch(farmTasksProvider(_selectedFarm!.id));
                        
                        if (farmTasks.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              '할일이 없습니다.',
                              style: TextStyle(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        return Column(
                          children: farmTasks.take(3).map((task) {
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                                color: task.isCompleted ? Colors.green : Colors.grey,
                                size: 20,
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: task.isCompleted ? Colors.grey : null,
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () {
                                ref.read(taskListProvider.notifier).toggleTask(task.id);
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                    if (ref.watch(farmTasksProvider(_selectedFarm!.id)).length > 3)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '+ ${ref.watch(farmTasksProvider(_selectedFarm!.id)).length - 3}개 더',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),
            
            // 하단 버튼들
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showCreateFarmDialog(context, ref);
                    },
                    child: const Text('농장 만들기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _selectedFarm != null
                        ? () => widget.onFarmSelected(_selectedFarm!)
                        : null,
                    child: const Text('선택하기'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showQuickAddTask(BuildContext context, Farm farm) {
    final taskController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${farm.name}에 할일 추가'),
        content: TextField(
          controller: taskController,
          decoration: const InputDecoration(
            labelText: '할일 제목',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (taskController.text.trim().isNotEmpty) {
                ref.read(taskListProvider.notifier).addTask(
                  farm.id,
                  taskController.text.trim(),
                );
              }
              Navigator.of(context).pop();
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _showCreateFarmDialog(BuildContext context, WidgetRef ref) {
    // 농장 생성 다이얼로그 (farm_screen.dart와 동일한 로직)
    final nameController = TextEditingController();
    String selectedColor = '#4CAF50';

    final colors = [
      '#4CAF50', '#2196F3', '#FF9800', '#9C27B0',
      '#F44336', '#009688', '#FF5722', '#607D8B',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('새 농장 만들기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '농장 이름',
                  hintText: '예: Flutter 공부',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text('농장 색상:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: colors.map((color) {
                  final isSelected = selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(int.parse(color.substring(1), radix: 16) + 0xFF000000),
                        shape: BoxShape.circle,
                        border: isSelected 
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                      ),
                      child: isSelected 
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  ref.read(farmListProvider.notifier).addFarm(
                    nameController.text.trim(),
                    selectedColor,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('만들기'),
            ),
          ],
        ),
      ),
    );
  }

}