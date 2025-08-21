/// 농장(프로젝트) 데이터 모델
/// 
/// 농장은 할 일을 그룹화하는 단위입니다.
/// 예: "Flutter 공부", "운동하기", "독서" 등
class Farm {
  final String id;           // 고유 식별자
  final String name;         // 농장 이름
  final String color;        // 농장 색상 (HEX)
  final int tomatoCount;     // 수확한 토마토 개수
  final DateTime createdAt;  // 생성 시간
  final DateTime updatedAt;  // 마지막 업데이트 시간

  const Farm({
    required this.id,
    required this.name,
    required this.color,
    required this.tomatoCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// JSON에서 Farm 객체 생성
  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      tomatoCount: json['tomatoCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Farm 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'tomatoCount': tomatoCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 농장 정보를 업데이트한 새로운 Farm 객체 생성
  Farm copyWith({
    String? id,
    String? name,
    String? color,
    int? tomatoCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Farm(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      tomatoCount: tomatoCount ?? this.tomatoCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 토마토 1개 추가 (25분 집중 완료 시)
  Farm addTomato() {
    return copyWith(
      tomatoCount: tomatoCount + 1,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Farm(id: $id, name: $name, tomatoCount: $tomatoCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Farm && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}