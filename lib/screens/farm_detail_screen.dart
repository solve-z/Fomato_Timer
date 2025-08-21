import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/farm.dart';
import '../providers/task_provider.dart';

/// 농장 상세 화면
/// 
/// 특정 농장의 할일 목록을 관리하고 통계를 표시합니다.
class FarmDetailScreen extends ConsumerStatefulWidget {
  final Farm farm;

  const FarmDetailScreen({
    super.key,
    required this.farm,
  });

  @override
  ConsumerState<FarmDetailScreen> createState() => _FarmDetailScreenState();
}

class _FarmDetailScreenState extends ConsumerState<FarmDetailScreen> {
  final TextEditingController _taskController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final farmTasks = ref.watch(farmTasksProvider(widget.farm.id));
    final completedCount = ref.watch(farmCompletedTaskCountProvider(widget.farm.id));
    final inProgressCount = ref.watch(farmInProgressTaskCountProvider(widget.farm.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.farm.name),
        backgroundColor: Color(int.parse(widget.farm.color.substring(1), radix: 16) + 0xFF000000),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 상단 통계 카드
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      '진행중',
                      inProgressCount.toString(),
                      Colors.orange,
                    ),
                    _buildStatItem(
                      '완료됨',
                      completedCount.toString(),
                      Colors.green,
                    ),
                    _buildStatItem(
                      '토마토',
                      '🍅 ${widget.farm.tomatoCount}',
                      Color(int.parse(widget.farm.color.substring(1), radix: 16) + 0xFF000000),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 할일 추가 입력 영역
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.add,
                      color: Color(int.parse(widget.farm.color.substring(1), radix: 16) + 0xFF000000),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _taskController,
                        decoration: const InputDecoration(
                          hintText: '+ 작업 추가',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (value) => _addTask(value),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _addTask(_taskController.text),
                      icon: const Icon(Icons.check),
                      color: Color(int.parse(widget.farm.color.substring(1), radix: 16) + 0xFF000000),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 할일 목록
          Expanded(
            child: farmTasks.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '할일이 없습니다.\n위의 입력란에서 작업을 추가해보세요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: farmTasks.length,
                    itemBuilder: (context, index) {
                      final task = farmTasks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Checkbox(
                            value: task.isCompleted,
                            onChanged: (value) {
                              ref.read(taskListProvider.notifier).toggleTask(task.id);
                            },
                            activeColor: Color(int.parse(widget.farm.color.substring(1), radix: 16) + 0xFF000000),
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: task.isCompleted
                                  ? Colors.grey
                                  : null,
                            ),
                          ),
                          subtitle: task.isCompleted && task.completedAt != null
                              ? Text(
                                  '완료: ${_formatDateTime(task.completedAt!)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _showEditDialog(task.id, task.title),
                                color: Colors.blue,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () => _showDeleteConfirmation(task.id, task.title),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _addTask(String title) {
    if (title.trim().isNotEmpty) {
      ref.read(taskListProvider.notifier).addTask(widget.farm.id, title.trim());
      _taskController.clear();
    }
  }

  void _showEditDialog(String taskId, String currentTitle) {
    final editController = TextEditingController(text: currentTitle);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할일 수정'),
        content: TextField(
          controller: editController,
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
              if (editController.text.trim().isNotEmpty) {
                ref.read(taskListProvider.notifier).updateTask(
                  taskId,
                  title: editController.text.trim(),
                );
              }
              Navigator.of(context).pop();
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String taskId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할일 삭제'),
        content: Text('"$title"을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              ref.read(taskListProvider.notifier).deleteTask(taskId);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}