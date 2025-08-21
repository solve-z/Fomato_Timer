import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';

/// 할일 목록 상태 관리 클래스
class TaskListNotifier extends StateNotifier<List<Task>> {
  TaskListNotifier() : super([]) {
    _loadInitialTasks();
  }

  /// 초기 할일 데이터 로드 (나중에 SharedPreferences에서 로드)
  void _loadInitialTasks() {
    final now = DateTime.now();
    state = [
      Task(
        id: 'task-1',
        farmId: 'farm-1',
        title: 'Flutter 위젯 공부하기',
        isCompleted: false,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      Task(
        id: 'task-2',
        farmId: 'farm-1',
        title: 'Riverpod 상태관리 학습',
        isCompleted: true,
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
        completedAt: now.subtract(const Duration(minutes: 30)),
      ),
      Task(
        id: 'task-3',
        farmId: 'farm-2',
        title: '30분 런닝하기',
        isCompleted: false,
        createdAt: now.subtract(const Duration(minutes: 30)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
      ),
    ];
  }

  /// 새 할일 추가
  void addTask(String farmId, String title) {
    final now = DateTime.now();
    final newTask = Task(
      id: 'task-${DateTime.now().millisecondsSinceEpoch}',
      farmId: farmId,
      title: title,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );
    
    state = [...state, newTask];
  }

  /// 할일 수정
  void updateTask(String taskId, {String? title}) {
    state = state.map((task) {
      if (task.id == taskId) {
        return task.copyWith(
          title: title,
          updatedAt: DateTime.now(),
        );
      }
      return task;
    }).toList();
  }

  /// 할일 삭제
  void deleteTask(String taskId) {
    state = state.where((task) => task.id != taskId).toList();
  }

  /// 할일 완료/미완료 토글
  void toggleTask(String taskId) {
    state = state.map((task) {
      if (task.id == taskId) {
        return task.toggleComplete();
      }
      return task;
    }).toList();
  }

  /// 특정 농장의 할일 목록 반환
  List<Task> getTasksByFarmId(String farmId) {
    return state.where((task) => task.farmId == farmId).toList();
  }

  /// 특정 농장의 완료된 할일 개수
  int getCompletedTaskCount(String farmId) {
    return state
        .where((task) => task.farmId == farmId && task.isCompleted)
        .length;
  }

  /// 특정 농장의 진행중 할일 개수
  int getInProgressTaskCount(String farmId) {
    return state
        .where((task) => task.farmId == farmId && !task.isCompleted)
        .length;
  }

  /// 특정 날짜에 완료된 할일 목록 (통계용)
  List<Task> getTasksCompletedOnDate(DateTime date, {String? farmId}) {
    return state.where((task) {
      if (task.completedAt == null) return false;
      
      final completedDate = task.completedAt!;
      final isSameDate = completedDate.year == date.year &&
          completedDate.month == date.month &&
          completedDate.day == date.day;
      
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
    final isSameDate = completedDate.year == date.year &&
        completedDate.month == date.month &&
        completedDate.day == date.day;
    
    if (!isSameDate) return false;
    
    // 농장 ID가 지정된 경우 해당 농장만 필터링
    if (farmId != null) {
      return task.farmId == farmId;
    }
    
    return true;
  }).toList();
});