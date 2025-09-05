import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/farm.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'task_detail_screen.dart';

/// 할일 필터 옵션
enum TaskFilter {
  all('전체'),
  inProgress('진행중'),
  completed('완료'),
  cancelled('취소');

  const TaskFilter(this.label);
  final String label;
}

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
  TaskFilter _selectedFilter = TaskFilter.all;
  
  // 고급 옵션 상태
  bool _showAdvancedOptions = false;
  DateTime? _selectedDueDate;
  String? _selectedCategoryId;

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(farmTasksProvider(widget.farm.id));
    final completedCount = ref.watch(farmCompletedTaskCountProvider(widget.farm.id));
    final inProgressCount = ref.watch(farmInProgressTaskCountProvider(widget.farm.id));
    
    // 필터에 따른 할일 목록
    final filteredTasks = _getFilteredTasks(allTasks);
    
    // 취소된 할일 개수
    final cancelledCount = allTasks.where((task) => task.status == TaskStatus.cancelled).length;

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

          // 필터 버튼 그룹
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TaskFilter.values.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  final count = _getFilterCount(allTasks, filter);
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text('${filter.label} ($count)'),
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      selectedColor: Color(int.parse(widget.farm.color.substring(1), radix: 16) + 0xFF000000).withValues(alpha: 0.2),
                      checkmarkColor: Color(int.parse(widget.farm.color.substring(1), radix: 16) + 0xFF000000),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 할일 추가 입력 영역 (확장 가능)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 기본 할일 입력 필드
                    Row(
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
                            onSubmitted: (value) => _addTaskWithOptions(),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _addTaskWithOptions(),
                          icon: const Icon(Icons.check),
                          color: Color(int.parse(widget.farm.color.substring(1), radix: 16) + 0xFF000000),
                        ),
                      ],
                    ),
                    
                    // 확장 옵션 영역
                    if (_showAdvancedOptions) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      
                      // 마감일 선택
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          const Text('마감일:'),
                          const Spacer(),
                          TextButton(
                            onPressed: _showDatePicker,
                            child: Text(
                              _selectedDueDate != null 
                                  ? '${_selectedDueDate!.month}/${_selectedDueDate!.day}' 
                                  : '설정',
                            ),
                          ),
                          if (_selectedDueDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () => setState(() => _selectedDueDate = null),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // 카테고리 선택
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.label_outline, size: 18),
                              const SizedBox(width: 8),
                              const Text('카테고리:'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Consumer(
                            builder: (context, ref, child) {
                              final categories = ref.watch(categoryListProvider);
                              return Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: categories.map((category) {
                                  final isSelected = _selectedCategoryId == category.id;
                                  return ChoiceChip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Color(int.parse(category.color.substring(1), radix: 16) + 0xFF000000),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(category.name),
                                      ],
                                    ),
                                    selected: isSelected,
                                    selectedColor: Color(int.parse(category.color.substring(1), radix: 16) + 0xFF000000).withValues(alpha: 0.2),
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCategoryId = selected ? category.id : null;
                                      });
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                    
                    // 옵션 토글 버튼
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _showAdvancedOptions = !_showAdvancedOptions),
                      icon: Icon(_showAdvancedOptions ? Icons.expand_less : Icons.expand_more),
                      label: Text(_showAdvancedOptions ? '간단히' : '더 많은 옵션'),
                      style: TextButton.styleFrom(
                        foregroundColor: Color(int.parse(widget.farm.color.substring(1), radix: 16) + 0xFF000000),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 할일 목록
          Expanded(
            child: filteredTasks.isEmpty
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
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      final category = task.categoryId != null 
                          ? ref.watch(categoryByIdProvider(task.categoryId!))
                          : null;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(
                                color: _getStatusColor(task.status),
                                width: 4,
                              ),
                            ),
                          ),
                          child: ListTile(
                            leading: Checkbox(
                              value: task.isCompleted,
                              onChanged: (value) {
                                ref.read(taskListProvider.notifier).toggleTask(task.id);
                              },
                              activeColor: Color(int.parse(widget.farm.color.substring(1), radix: 16) + 0xFF000000),
                            ),
                            title: Row(
                              children: [
                                // 카테고리 표시
                                if (category != null) ...[
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Color(int.parse(category.color.substring(1), radix: 16) + 0xFF000000),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    category.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      color: task.isCompleted
                                          ? Colors.grey
                                          : null,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                
                                // 체크리스트 진행률 프로그레스 바
                                if (task.subTasks.isNotEmpty) ...[
                                  LinearProgressIndicator(
                                    value: task.subTaskProgress,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: AlwaysStoppedAnimation(
                                      _getStatusColor(task.status),
                                    ),
                                    minHeight: 3,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '체크리스트 ${task.completedSubTaskCount}/${task.totalSubTaskCount} 완료',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                
                                // 마감일 개선된 표시
                                if (task.dueDate != null) ...[
                                  Text(
                                    _getRelativeDateString(task.dueDate!),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: task.isOverdue 
                                          ? Colors.red 
                                          : (task.daysUntilDue != null && task.daysUntilDue! <= 1)
                                              ? Colors.orange 
                                              : Colors.grey,
                                      fontWeight: task.isOverdue ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                
                                // 완료 시간 표시
                                if (task.isCompleted && task.completedAt != null)
                                  Text(
                                    '완료: ${_formatDateTime(task.completedAt!)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
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
                            onTap: () => _navigateToTaskDetail(task),
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

  /// 필터에 따른 할일 목록 반환
  List<Task> _getFilteredTasks(List<Task> tasks) {
    switch (_selectedFilter) {
      case TaskFilter.all:
        return tasks;
      case TaskFilter.inProgress:
        return tasks.where((task) => task.status == TaskStatus.inProgress).toList();
      case TaskFilter.completed:
        return tasks.where((task) => task.status == TaskStatus.completed).toList();
      case TaskFilter.cancelled:
        return tasks.where((task) => task.status == TaskStatus.cancelled).toList();
    }
  }

  /// 필터별 할일 개수 반환
  int _getFilterCount(List<Task> tasks, TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return tasks.length;
      case TaskFilter.inProgress:
        return tasks.where((task) => task.status == TaskStatus.inProgress).length;
      case TaskFilter.completed:
        return tasks.where((task) => task.status == TaskStatus.completed).length;
      case TaskFilter.cancelled:
        return tasks.where((task) => task.status == TaskStatus.cancelled).length;
    }
  }

  /// 상태에 따른 색상 반환
  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
    }
  }

  /// 상대적인 날짜 문자열 반환
  String _getRelativeDateString(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    final difference = targetDate.difference(today).inDays;
    
    if (difference == 0) {
      return '오늘 마감';
    } else if (difference == 1) {
      return '내일 마감';
    } else if (difference == -1) {
      return '어제 마감됨';
    } else if (difference > 1) {
      return '${difference}일 후 마감';
    } else {
      return '${-difference}일 지남';
    }
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

  /// 고급 옵션을 포함한 할일 추가
  void _addTaskWithOptions() {
    if (_taskController.text.trim().isNotEmpty) {
      ref.read(taskListProvider.notifier).addTask(
        widget.farm.id, 
        _taskController.text.trim(),
        dueDate: _selectedDueDate,
        categoryId: _selectedCategoryId,
      );
      
      // 입력 필드 및 옵션 초기화
      _taskController.clear();
      setState(() {
        _selectedDueDate = null;
        _selectedCategoryId = null;
        _showAdvancedOptions = false;
      });
    }
  }

  /// 마감일 선택 DatePicker 표시
  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(int.parse(widget.farm.color.substring(1), radix: 16) + 0xFF000000),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    final difference = targetDate.difference(today).inDays;
    
    if (difference == 0) {
      return '오늘';
    } else if (difference == 1) {
      return '내일';
    } else if (difference == -1) {
      return '어제';
    } else if (difference > 1) {
      return '${difference}일 후';
    } else {
      return '${-difference}일 전';
    }
  }

  void _navigateToTaskDetail(task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );
  }
}