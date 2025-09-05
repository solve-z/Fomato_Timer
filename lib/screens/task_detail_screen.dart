import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../models/task_category.dart';
import '../providers/task_provider.dart';

/// 할일 상세 화면
///
/// 특정 할일의 상세 정보를 보고 편집할 수 있습니다.
class TaskDetailScreen extends ConsumerStatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _memoController;
  late TextEditingController _subTaskController;

  late Task _currentTask;
  DateTime? _selectedDueDate;
  String? _selectedCategoryId;
  TaskStatus _selectedStatus = TaskStatus.todo;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _titleController = TextEditingController(text: _currentTask.title);
    _memoController = TextEditingController(text: _currentTask.memo);
    _subTaskController = TextEditingController();
    _selectedDueDate = _currentTask.dueDate;
    _selectedCategoryId = _currentTask.categoryId;
    _selectedStatus = _currentTask.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 실시간으로 업데이트된 Task 정보 가져오기
    final tasks = ref.watch(taskListProvider);
    _currentTask = tasks.firstWhere((task) => task.id == widget.task.id, orElse: () => _currentTask);

    return WillPopScope(
      onWillPop: () async {
        _autoSave();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('할일 상세')]),
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          actions: [
            PopupMenuButton(
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: const Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('삭제', style: TextStyle(color: Colors.red))]),
                    ),
                  ],
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteConfirmation();
                }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleSection(),
              const SizedBox(height: 16),
              _buildStatusSection(),
              const SizedBox(height: 16),
              _buildSubTasksSection(),
              const SizedBox(height: 16),
              _buildDueDateSection(),
              const SizedBox(height: 16),
              _buildCategorySection(),
              const SizedBox(height: 16),
              _buildMemoSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('할일 제목', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: '할일 제목을 입력하세요', border: OutlineInputBorder()),
              style: const TextStyle(fontSize: 18),
              onChanged: (value) => _autoSave(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('상태', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<TaskStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items:
                    TaskStatus.values.map((status) {
                      return DropdownMenuItem<TaskStatus>(
                        value: status,
                        child: Row(
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: _getStatusColor(status), shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(status.label),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                    _autoSave();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('마감일', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDueDate != null ? _formatDate(_selectedDueDate!) : '마감일 없음',
                    style: TextStyle(fontSize: 16, color: _selectedDueDate != null ? Colors.black87 : Colors.grey[600]),
                  ),
                ),
                TextButton.icon(onPressed: _selectDueDate, icon: const Icon(Icons.calendar_today), label: const Text('선택')),
                if (_selectedDueDate != null)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDueDate = null;
                      });
                      _autoSave();
                    },
                    icon: const Icon(Icons.clear),
                    tooltip: '마감일 제거',
                  ),
              ],
            ),
            if (_selectedDueDate != null && _currentTask.isOverdue)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [Icon(Icons.warning, color: Colors.red, size: 16), SizedBox(width: 8), Text('마감일이 지났습니다', style: TextStyle(color: Colors.red))],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('카테고리', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<TaskCategory>>(
              future: _loadCategories(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final categories = snapshot.data!;
                return Column(
                  children: [
                    DropdownButtonFormField<String?>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '카테고리 선택'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('카테고리 없음')),
                        ...categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category.id,
                            child: Row(
                              children: [
                                Icon(_getIconData(category.icon), color: Color(int.parse(category.color.substring(1), radix: 16) + 0xFF000000), size: 20),
                                const SizedBox(width: 8),
                                Text(category.name),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                        _autoSave();
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('메모', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(hintText: '자세한 내용을 적어보세요', border: OutlineInputBorder()),
              maxLines: 4,
              onChanged: (value) => _autoSave(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTasksSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('체크리스트', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${_currentTask.completedSubTaskCount}/${_currentTask.totalSubTaskCount}', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),

            // 서브태스크 추가 입력란
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subTaskController,
                    decoration: const InputDecoration(hintText: '새 항목 추가', border: OutlineInputBorder()),
                    onSubmitted: (value) => _addSubTask(value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _addSubTask(_subTaskController.text),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(backgroundColor: Colors.green[600], foregroundColor: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 서브태스크 목록
            if (_currentTask.subTasks.isNotEmpty) ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _currentTask.subTasks.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final subTask = _currentTask.subTasks[index];
                  return Container(
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      leading: Checkbox(
                        value: subTask.isCompleted,
                        onChanged: (value) {
                          ref.read(taskListProvider.notifier).toggleSubTask(_currentTask.id, subTask.id);
                        },
                      ),
                      title: Text(
                        subTask.title,
                        style: TextStyle(
                          decoration: subTask.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                          color: subTask.isCompleted ? Colors.grey : Colors.black87,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showEditSubTaskDialog(subTask), color: Colors.blue),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            onPressed: () {
                              ref.read(taskListProvider.notifier).deleteSubTask(_currentTask.id, subTask.id);
                            },
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.checklist, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('체크리스트가 없습니다.\n위의 입력란에서 항목을 추가해보세요!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<List<TaskCategory>> _loadCategories() async {
    try {
      return await Future.value(TaskCategory.getDefaultCategories());
    } catch (e) {
      return TaskCategory.getDefaultCategories();
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.onHold:
        return Colors.orange;
      case TaskStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school;
      case 'work':
        return Icons.work;
      case 'person':
        return Icons.person;
      case 'favorite':
        return Icons.favorite;
      case 'palette':
        return Icons.palette;
      case 'attach_money':
        return Icons.attach_money;
      default:
        return Icons.category;
    }
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
      return '${difference}일 후 (${date.month}/${date.day})';
    } else {
      return '${-difference}일 전 (${date.month}/${date.day})';
    }
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
      _autoSave();
    }
  }

  void _addSubTask(String title) {
    if (title.trim().isNotEmpty) {
      ref.read(taskListProvider.notifier).addSubTask(_currentTask.id, title.trim());
      _subTaskController.clear();
    }
  }

  void _autoSave() {
    // 제목이 비어있으면 저장하지 않음
    if (_titleController.text.trim().isEmpty) {
      return;
    }

    ref
        .read(taskListProvider.notifier)
        .updateTask(
          _currentTask.id,
          title: _titleController.text.trim(),
          memo: _memoController.text.trim(),
          dueDate: _selectedDueDate,
          categoryId: _selectedCategoryId,
          status: _selectedStatus,
        );
  }

  void _showEditSubTaskDialog(SubTask subTask) {
    final editController = TextEditingController(text: subTask.title);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('항목 수정'),
            content: TextField(
              controller: editController,
              decoration: const InputDecoration(labelText: '항목 제목', border: OutlineInputBorder()),
              autofocus: true,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
              TextButton(
                onPressed: () {
                  if (editController.text.trim().isNotEmpty) {
                    ref.read(taskListProvider.notifier).updateSubTask(_currentTask.id, subTask.id, editController.text.trim());
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('저장'),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('할일 삭제'),
            content: Text('"${_currentTask.title}"을(를) 삭제하시겠습니까?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
              TextButton(
                onPressed: () {
                  ref.read(taskListProvider.notifier).deleteTask(_currentTask.id);
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  Navigator.of(context).pop(); // 상세 페이지 닫기
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('삭제'),
              ),
            ],
          ),
    );
  }
}
