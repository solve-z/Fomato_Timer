/// 할일 데이터 모델
///
/// 농장 내에서 관리되는 개별 할일을 나타냅니다.
class Task {
  final String id;           // 고유 식별자
  final String farmId;       // 속한 농장 ID
  final String title;        // 할일 제목
  final bool isCompleted;    // 완료 여부
  final DateTime createdAt;  // 생성 시간
  final DateTime updatedAt;  // 마지막 업데이트 시간
  final DateTime? completedAt; // 완료 시간

  const Task({
    required this.id,
    required this.farmId,
    required this.title,
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
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// 할일 완료/미완료 토글
  Task toggleComplete() {
    final now = DateTime.now();
    return copyWith(
      isCompleted: !isCompleted,
      updatedAt: now,
      completedAt: !isCompleted ? now : null,
    );
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