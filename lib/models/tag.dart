/// 할일 태그 데이터 모델
class Tag {
  final String id;
  final String name;        // 태그 이름
  final String color;       // 태그 색상 (HEX 코드)
  final DateTime createdAt; // 생성 시간

  const Tag({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  /// JSON에서 Tag 객체 생성
  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Tag 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 태그 정보를 업데이트한 새로운 Tag 객체 생성
  Tag copyWith({
    String? id,
    String? name,
    String? color,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 기본 태그 목록
  static List<Tag> getDefaultTags() {
    final now = DateTime.now();
    return [
      Tag(
        id: 'default-study',
        name: '공부',
        color: '#4CAF50',
        createdAt: now,
      ),
      Tag(
        id: 'default-work',
        name: '업무',
        color: '#2196F3',
        createdAt: now,
      ),
      Tag(
        id: 'default-personal',
        name: '개인',
        color: '#FF9800',
        createdAt: now,
      ),
      Tag(
        id: 'default-health',
        name: '건강',
        color: '#E91E63',
        createdAt: now,
      ),
      Tag(
        id: 'default-hobby',
        name: '취미',
        color: '#9C27B0',
        createdAt: now,
      ),
      Tag(
        id: 'default-finance',
        name: '금융',
        color: '#607D8B',
        createdAt: now,
      ),
    ];
  }

  @override
  String toString() {
    return 'Tag(id: $id, name: $name, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}