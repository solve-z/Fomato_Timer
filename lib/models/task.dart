/// 할일 상태 열거형
enum TaskStatus {
  inProgress('진행중'),
  completed('완료'),
  cancelled('취소');

  const TaskStatus(this.label);
  final String label;
}

/// 서브태스크 데이터 모델
class SubTask {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;

  const SubTask({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
  });

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  SubTask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 할일 데이터 모델
///
/// 농장 내에서 관리되는 개별 할일을 나타냅니다.
class Task {
  final String id;           // 고유 식별자
  final String farmId;       // 속한 농장 ID
  final String title;        // 할일 제목
  final String memo;         // 메모
  final DateTime? dueDate;   // 마감일
  final List<String> tagIds;  // 태그 ID 목록
  final TaskStatus status;   // 현재 상태
  final List<SubTask> subTasks;   // 체크리스트
  final bool isCompleted;    // 완료 여부 (호환성 유지)
  final DateTime createdAt;  // 생성 시간
  final DateTime updatedAt;  // 마지막 업데이트 시간
  final DateTime? completedAt; // 완료 시간

  const Task({
    required this.id,
    required this.farmId,
    required this.title,
    this.memo = '',
    this.dueDate,
    this.tagIds = const [],
    this.status = TaskStatus.inProgress,
    this.subTasks = const [],
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  /// JSON에서 Task 객체 생성
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      farmId: json['farmId'] as String,
      title: json['title'] as String,
      memo: json['memo'] as String? ?? '',
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate'] as String) 
          : null,
      tagIds: (json['tagIds'] as List<dynamic>? ?? []).cast<String>(),
      status: TaskStatus.values.firstWhere(
        (status) => status.name == (json['status'] as String? ?? 'inProgress'),
        orElse: () => TaskStatus.inProgress,
      ),
      subTasks: (json['subTasks'] as List<dynamic>? ?? [])
          .map((subTaskJson) => SubTask.fromJson(subTaskJson as Map<String, dynamic>))
          .toList(),
      isCompleted: json['isCompleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
    );
  }

  /// Task 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      'title': title,
      'memo': memo,
      'dueDate': dueDate?.toIso8601String(),
      'tagIds': tagIds,
      'status': status.name,
      'subTasks': subTasks.map((subTask) => subTask.toJson()).toList(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  /// 할일 정보를 업데이트한 새로운 Task 객체 생성
  Task copyWith({
    String? id,
    String? farmId,
    String? title,
    String? memo,
    DateTime? dueDate,
    List<String>? tagIds,
    TaskStatus? status,
    List<SubTask>? subTasks,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      title: title ?? this.title,
      memo: memo ?? this.memo,
      dueDate: dueDate ?? this.dueDate,
      tagIds: tagIds ?? this.tagIds,
      status: status ?? this.status,
      subTasks: subTasks ?? this.subTasks,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// 할일 완료/미완료 토글
  Task toggleComplete() {
    final now = DateTime.now();
    final newStatus = isCompleted ? TaskStatus.inProgress : TaskStatus.completed;
    return copyWith(
      isCompleted: !isCompleted,
      status: newStatus,
      updatedAt: now,
      completedAt: !isCompleted ? now : null,
    );
  }

  /// 완료된 서브태스크 개수
  int get completedSubTaskCount {
    return subTasks.where((subTask) => subTask.isCompleted).length;
  }

  /// 전체 서브태스크 개수
  int get totalSubTaskCount {
    return subTasks.length;
  }

  /// 서브태스크 완료율 (0.0 ~ 1.0)
  double get subTaskProgress {
    if (totalSubTaskCount == 0) return 0.0;
    return completedSubTaskCount / totalSubTaskCount;
  }

  /// 마감일까지 남은 일수
  int? get daysUntilDue {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final difference = dueDate!.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }

  /// 마감일이 지났는지 여부
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    return dueDate!.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// 태그 추가
  Task addTag(String tagId) {
    if (tagIds.contains(tagId)) return this;
    return copyWith(
      tagIds: [...tagIds, tagId],
      updatedAt: DateTime.now(),
    );
  }

  /// 태그 제거
  Task removeTag(String tagId) {
    if (!tagIds.contains(tagId)) return this;
    return copyWith(
      tagIds: tagIds.where((id) => id != tagId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// 태그 목록 설정
  Task setTags(List<String> newTagIds) {
    return copyWith(
      tagIds: List.from(newTagIds),
      updatedAt: DateTime.now(),
    );
  }

  /// 특정 태그를 가지고 있는지 확인
  bool hasTag(String tagId) {
    return tagIds.contains(tagId);
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}