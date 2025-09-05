import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../models/task_category.dart';
import '../services/storage_service.dart';

/// 할일 목록 상태 관리 클래스
class TaskListNotifier extends StateNotifier<List<Task>> {
  TaskListNotifier() : super([]) {
    _loadTasks();
  }

  /// 저장된 할일 데이터 로드
  Future<void> _loadTasks() async {
    try {
      final tasks = await StorageService.loadTasks();
      state = tasks;
    } catch (e) {
      // 로드 실패 시 빈 리스트로 초기화
      state = [];
    }
  }

  /// 할일 목록 저장
  Future<void> _saveTasks() async {
    try {
      await StorageService.saveTasks(state);
    } catch (e) {
      // 저장 실패 시 에러 로그 (필요시 사용자에게 알림)
      print('할일 저장 실패: $e');
    }
  }

  /// 새 할일 추가
  void addTask(String farmId, String title, {DateTime? dueDate, String? categoryId, TaskStatus? status}) {
    final now = DateTime.now();
    final newTask = Task(
      id: 'task-${DateTime.now().millisecondsSinceEpoch}',
      farmId: farmId,
      title: title,
      dueDate: dueDate,
      categoryId: categoryId,
      status: status ?? TaskStatus.inProgress,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );

    state = [...state, newTask];
    _saveTasks();
  }

  /// 할일 수정
  void updateTask(String taskId, {String? title, String? memo, DateTime? dueDate, String? categoryId, TaskStatus? status, List<SubTask>? subTasks}) {
    state =
        state.map((task) {
          if (task.id == taskId) {
            return task.copyWith(
              title: title,
              memo: memo,
              dueDate: dueDate,
              categoryId: categoryId,
              status: status,
              subTasks: subTasks,
              updatedAt: DateTime.now(),
            );
          }
          return task;
        }).toList();
    _saveTasks();
  }

  /// 할일 삭제
  void deleteTask(String taskId) {
    state = state.where((task) => task.id != taskId).toList();
    _saveTasks();
  }

  /// 할일 완료/미완료 토글
  void toggleTask(String taskId) {
    state =
        state.map((task) {
          if (task.id == taskId) {
            return task.toggleComplete();
          }
          return task;
        }).toList();
    _saveTasks();
  }

  /// 서브태스크 추가
  void addSubTask(String taskId, String subTaskTitle) {
    final now = DateTime.now();
    final newSubTask = SubTask(id: 'subtask-${now.millisecondsSinceEpoch}', title: subTaskTitle, isCompleted: false, createdAt: now);

    state =
        state.map((task) {
          if (task.id == taskId) {
            final updatedSubTasks = [...task.subTasks, newSubTask];
            return task.copyWith(subTasks: updatedSubTasks, updatedAt: now);
          }
          return task;
        }).toList();
    _saveTasks();
  }

  /// 서브태스크 완료/미완료 토글
  void toggleSubTask(String taskId, String subTaskId) {
    final now = DateTime.now();
    state =
        state.map((task) {
          if (task.id == taskId) {
            final updatedSubTasks =
                task.subTasks.map((subTask) {
                  if (subTask.id == subTaskId) {
                    return subTask.copyWith(isCompleted: !subTask.isCompleted);
                  }
                  return subTask;
                }).toList();
            return task.copyWith(subTasks: updatedSubTasks, updatedAt: now);
          }
          return task;
        }).toList();
    _saveTasks();
  }

  /// 서브태스크 수정
  void updateSubTask(String taskId, String subTaskId, String newTitle) {
    final now = DateTime.now();
    state =
        state.map((task) {
          if (task.id == taskId) {
            final updatedSubTasks =
                task.subTasks.map((subTask) {
                  if (subTask.id == subTaskId) {
                    return subTask.copyWith(title: newTitle);
                  }
                  return subTask;
                }).toList();
            return task.copyWith(subTasks: updatedSubTasks, updatedAt: now);
          }
          return task;
        }).toList();
    _saveTasks();
  }

  /// 서브태스크 삭제
  void deleteSubTask(String taskId, String subTaskId) {
    final now = DateTime.now();
    state =
        state.map((task) {
          if (task.id == taskId) {
            final updatedSubTasks = task.subTasks.where((subTask) => subTask.id != subTaskId).toList();
            return task.copyWith(subTasks: updatedSubTasks, updatedAt: now);
          }
          return task;
        }).toList();
    _saveTasks();
  }

  /// 특정 농장의 할일 목록 반환
  List<Task> getTasksByFarmId(String farmId) {
    return state.where((task) => task.farmId == farmId).toList();
  }

  /// 특정 농장의 완료된 할일 개수
  int getCompletedTaskCount(String farmId) {
    return state.where((task) => task.farmId == farmId && task.isCompleted).length;
  }

  /// 특정 농장의 진행중 할일 개수
  int getInProgressTaskCount(String farmId) {
    return state.where((task) => task.farmId == farmId && !task.isCompleted).length;
  }

  /// 특정 날짜에 완료된 할일 목록 (통계용)
  List<Task> getTasksCompletedOnDate(DateTime date, {String? farmId}) {
    return state.where((task) {
      if (task.completedAt == null) return false;

      final completedDate = task.completedAt!;
      final isSameDate = completedDate.year == date.year && completedDate.month == date.month && completedDate.day == date.day;

      if (!isSameDate) return false;

      // 농장 ID가 지정된 경우 해당 농장만 필터링
      if (farmId != null) {
        return task.farmId == farmId;
      }

      return true;
    }).toList();
  }
}

/// 할일 목록 Provider
final taskListProvider = StateNotifierProvider<TaskListNotifier, List<Task>>((ref) {
  return TaskListNotifier();
});

/// 특정 농장의 할일 목록 Provider
final farmTasksProvider = Provider.family<List<Task>, String>((ref, farmId) {
  final tasks = ref.watch(taskListProvider);
  return tasks.where((task) => task.farmId == farmId).toList();
});

/// 특정 농장의 완료된 할일 개수 Provider
final farmCompletedTaskCountProvider = Provider.family<int, String>((ref, farmId) {
  final tasks = ref.watch(taskListProvider);
  return tasks.where((task) => task.farmId == farmId && task.isCompleted).length;
});

/// 특정 농장의 진행중 할일 개수 Provider
final farmInProgressTaskCountProvider = Provider.family<int, String>((ref, farmId) {
  final tasks = ref.watch(taskListProvider);
  return tasks.where((task) => task.farmId == farmId && !task.isCompleted).length;
});

/// 특정 날짜의 완료된 할일 Provider (통계용)
final dateCompletedTasksProvider = Provider.family<List<Task>, Map<String, dynamic>>((ref, params) {
  final tasks = ref.watch(taskListProvider);
  final DateTime date = params['date'] as DateTime;
  final String? farmId = params['farmId'] as String?;

  return tasks.where((task) {
    if (task.completedAt == null) return false;

    final completedDate = task.completedAt!;
    final isSameDate = completedDate.year == date.year && completedDate.month == date.month && completedDate.day == date.day;

    if (!isSameDate) return false;

    // 농장 ID가 지정된 경우 해당 농장만 필터링
    if (farmId != null) {
      return task.farmId == farmId;
    }

    return true;
  }).toList();
});

/// 카테고리 목록 상태 관리 클래스
class CategoryListNotifier extends StateNotifier<List<TaskCategory>> {
  CategoryListNotifier() : super([]) {
    _loadCategories();
  }

  /// 저장된 카테고리 데이터 로드
  Future<void> _loadCategories() async {
    try {
      final categories = await StorageService.loadCategories();
      state = categories.isEmpty ? TaskCategory.getDefaultCategories() : categories;
    } catch (e) {
      // 로드 실패 시 기본 카테고리로 초기화
      state = TaskCategory.getDefaultCategories();
    }
  }

  /// 카테고리 목록 저장
  Future<void> _saveCategories() async {
    try {
      await StorageService.saveCategories(state);
    } catch (e) {
      print('카테고리 저장 실패: $e');
    }
  }
}

/// 카테고리 목록 Provider
final categoryListProvider = StateNotifierProvider<CategoryListNotifier, List<TaskCategory>>((ref) {
  return CategoryListNotifier();
});

/// ID로 특정 카테고리 찾기 Provider
final categoryByIdProvider = Provider.family<TaskCategory?, String>((ref, categoryId) {
  final categories = ref.watch(categoryListProvider);
  try {
    return categories.firstWhere((category) => category.id == categoryId);
  } catch (e) {
    return null;
  }
});
