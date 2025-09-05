/// 할일 카테고리 데이터 모델
class TaskCategory {
  final String id;
  final String name;        // 카테고리 이름
  final String color;       // 카테고리 색상 (HEX 코드)
  final String icon;        // 카테고리 아이콘 (Material Icons 코드명)
  final bool isDefault;     // 기본 카테고리 여부
  final DateTime createdAt; // 생성 시간

  const TaskCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.isDefault,
    required this.createdAt,
  });

  /// JSON에서 TaskCategory 객체 생성
  factory TaskCategory.fromJson(Map<String, dynamic> json) {
    return TaskCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String,
      isDefault: json['isDefault'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// TaskCategory 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 카테고리 정보를 업데이트한 새로운 TaskCategory 객체 생성
  TaskCategory copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return TaskCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 기본 카테고리 목록
  static List<TaskCategory> getDefaultCategories() {
    final now = DateTime.now();
    return [
      TaskCategory(
        id: 'default-study',
        name: '공부',
        color: '#4CAF50',
        icon: 'school',
        isDefault: true,
        createdAt: now,
      ),
      TaskCategory(
        id: 'default-work',
        name: '업무',
        color: '#2196F3',
        icon: 'work',
        isDefault: true,
        createdAt: now,
      ),
      TaskCategory(
        id: 'default-personal',
        name: '개인',
        color: '#FF9800',
        icon: 'person',
        isDefault: true,
        createdAt: now,
      ),
      TaskCategory(
        id: 'default-health',
        name: '건강',
        color: '#E91E63',
        icon: 'favorite',
        isDefault: true,
        createdAt: now,
      ),
      TaskCategory(
        id: 'default-hobby',
        name: '취미',
        color: '#9C27B0',
        icon: 'palette',
        isDefault: true,
        createdAt: now,
      ),
      TaskCategory(
        id: 'default-finance',
        name: '금융',
        color: '#607D8B',
        icon: 'attach_money',
        isDefault: true,
        createdAt: now,
      ),
    ];
  }

  @override
  String toString() {
    return 'TaskCategory(id: $id, name: $name, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}