# Fomato 프로젝트 학습 가이드

## 📖 프로젝트 개요

**Fomato**는 토마토 농장형 뽀모도로 타이머 앱으로, Flutter와 Riverpod를 기반으로 구축된 학습 프로젝트입니다. 25분 집중 시 토마토 1개를 수확하는 재미있는 방식으로 할 일을 시각화합니다.

### 🎯 학습 목표
- Flutter 기본 개념과 위젯 시스템 이해
- Riverpod 상태관리 패턴 마스터
- Stream 기반 실시간 상태 동기화
- 로컬 저장소와 알림 시스템 구현

---

## 🏗️ 프로젝트 아키텍처 분석

### 1. 전체 구조 개요

```
lib/
├── main.dart                 # 앱 진입점 + ProviderScope 설정
├── models/                   # 데이터 모델 (Farm,TimerState, Task, Statistics)
├── providers/                # Riverpod 상태관리 (5개 주요 Provider)
├── screens/                  # 화면 UI (타이머, 농장, 통계, 설정)
├── services/                 # 비즈니스 로직 (타이머, 알림, 저장소)
├── widgets/                  # 재사용 위젯 (네비게이션, 다이얼로그)
└── utils/                    # 상수, 테마, 헬퍼 함수
```

### 2. 핵심 의존성 분석

```yaml
dependencies:
  flutter_riverpod: ^2.4.9     # 상태관리
  shared_preferences: ^2.2.2   # 로컬 저장소
  flutter_local_notifications: ^19.4.0  # 알림
  table_calendar: ^3.0.9       # 캘린더 위젯
```

---

## 🔄 상태관리 시스템 (Riverpod)

### 1. Provider 구조 맵

```dart
// 5개 핵심 Provider
farmListProvider        -> 농장 목록 관리
selectedFarmProvider    -> 현재 선택된 농장
timerProvider          -> 타이머 상태 + 서비스 연동
statisticsProvider     -> 통계 데이터 관리
taskProvider           -> 할일 목록 관리
```

### 2. Provider 간 연동 패턴

**타이머 → 농장 → 통계 연동 흐름:**
```dart
// 1. 타이머 완료 시 토마토 수확
TimerNotifier._harvestTomato() {
  ref.read(farmListProvider.notifier).harvestTomato(farmId);  // 농장 업데이트
  ref.read(statisticsProvider.notifier).recordTomatoHarvest(...);  // 통계 기록
}

// 2. 농장 선택 변화 시 타이머 동기화
ref.listen<Farm?>(selectedFarmProvider, (previous, next) {
  notifier.selectFarm(next?.id);  // 타이머에 농장 ID 전달
});
```

### 3. StateNotifier vs StateProvider 사용 구분

- **StateNotifier**: 복잡한 비즈니스 로직 (타이머, 농장 목록, 통계)
- **StateProvider**: 간단한 상태 (선택된 농장, 설정값)

---

## ⏰ 타이머 시스템 심화 분석

### 1. 이중 상태 관리 구조

```dart
TimerService (비즈니스 로직)
    ↓ Stream
TimerProvider (UI 상태 관리)
    ↓ watch()
UI 컴포넌트 (화면 표시)
```

### 2. Stream 기반 실시간 동기화

```dart
// TimerService에서 상태 변화 발생
_stateController.add(newState);

// TimerProvider에서 구독하여 UI 업데이트
_stateSubscription = _timerService!.stateStream.listen((newState) {
  state = newState;  // UI에 즉시 반영
});
```

### 3. 자동 전환 로직 분석

```dart
// 완료 시 자동 전환 처리
if (newState.status == TimerStatus.completed && !_hasAutoTransitioned) {
  _hasAutoTransitioned = true;
  
  // 집중 완료 시만 토마토 수확
  if (newState.mode == TimerMode.focus && !_hasHarvestedForCurrentSession) {
    _harvestTomato();
  }
  
  // 설정에 따라 자동 시작 여부 결정
  if (settings.autoStartNext) {
    Future.delayed(Duration(seconds: 2), () {
      _timerService?.nextMode();
      _timerService?.start();
    });
  }
}
```

---

## 🌱 데이터 모델 시스템

### 1. Farm 모델 설계

```dart
class Farm {
  final String id;           // 고유 식별자
  final String name;         // 농장 이름 (프로젝트명)
  final String color;        // HEX 색상 코드
  final int tomatoCount;     // 수확한 토마토 개수
  final DateTime createdAt;  // 생성 시간
  final DateTime updatedAt;  // 업데이트 시간
}
```

**핵심 비즈니스 로직:**
- `addTomato()`: 25분 집중 완료 시 토마토 +1
- `copyWith()`: 불변 객체 패턴으로 상태 업데이트

### 2. TimerState 모델 설계

```dart
class TimerState {
  final TimerMode mode;           // focus/shortBreak/longBreak
  final TimerStatus status;       // initial/running/paused/completed
  final int remainingSeconds;     // 남은 시간 (초)
  final int totalSeconds;         // 전체 시간 (초)
  final int currentRound;         // 현재 라운드 (1-4)
  final String? selectedFarmId;   // 선택된 농장 ID
}
```

**계산 프로퍼티:**
- `progress`: 진행률 (0.0-1.0)
- `formattedTime`: MM:SS 형식 표시
- `isRunning`, `isCompleted`: 상태 확인 헬퍼

---

## 💾 로컬 저장소 시스템

### 1. SharedPreferences 래퍼 패턴

```dart
class StorageService {
  // 농장 데이터 JSON 저장/로드
  static Future<void> saveFarms(List<Farm> farms)
  static Future<List<Farm>> loadFarms()
  
  // 타이머 설정 저장/로드
  static Future<void> saveTimerSettings(...)
  static Future<Map<String, dynamic>?> loadTimerSettings()
  
  // 선택된 농장 ID 저장/로드
  static Future<void> saveSelectedFarmId(String? farmId)
  static Future<String?> loadSelectedFarmId()
}
```

### 2. 데이터 영속성 패턴

```dart
// Provider 초기화 시 자동 로드
FarmListNotifier() : super([]) {
  _loadInitialFarms();  // SharedPreferences에서 복원
}

// 상태 변경 시 자동 저장
void addFarm(String name, String color) {
  state = [...state, newFarm];
  await _saveFarms();  // 즉시 저장
}
```

---

## 🔔 알림 시스템 구조

### 1. 실시간 진행 알림

```dart
// 타이머 시작 시 지속적 알림 표시
void _showRunningNotification() {
  _notificationService.showProgressNotification(
    title: '${_getFarmName()} 집중 시간',
    body: '${_currentState.formattedTime}',
    ongoing: true,  // 스와이프 삭제 방지
  );
}
```

### 2. 콜백 기반 정보 제공

```dart
// TimerProvider에서 알림에 필요한 정보 제공
_timerService?.setNotificationCallbacks(
  getFarmName: () => _getSelectedFarmName(),
  getTomatoCount: () => _getSelectedFarmTomatoCount(),
  isNotificationEnabled: () => _isNotificationEnabled(),
);
```

---

## 🎨 UI 컴포넌트 시스템

### 1. 테마 시스템 (Material 3)

```dart
// constants.dart에서 디자인 토큰 정의
class AppColors {
  static const Color primary = Color(0xFF4CAF50);    // 녹색
  static const Color secondary = Color(0xFFFFC107);  // 노란색
}

class AppSizes {
  static const double cardBorderRadius = 16.0;
  static const double paddingMedium = 16.0;
}
```

### 2. 상태 기반 UI 렌더링

```dart
// 타이머 상태에 따른 버튼 표시
Widget _buildActionButtons(TimerState state) {
  switch (state.status) {
    case TimerStatus.initial:
      return ElevatedButton(onPressed: () => ref.read(timerProvider.notifier).start());
    case TimerStatus.running:
      return ElevatedButton(onPressed: () => ref.read(timerProvider.notifier).pause());
    case TimerStatus.paused:
      return Row([시작 버튼, 정지 버튼, 리셋 버튼]);
  }
}
```

### 3. 확인 다이얼로그 패턴

```dart
// 중요한 액션 시 확인 다이얼로그 표시
void _showStopConfirmDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('타이머 정지'),
      content: Text('정말 타이머를 정지하시겠습니까?'),
      actions: [취소, 확인],
    ),
  );
}
```

---

## 📊 통계 시스템 구조

### 1. 일별 활동 기록

```dart
class DailySummary {
  final DateTime date;
  final Map<String, int> farmTomatoCounts;  // 농장별 토마토 수
  final Map<String, int> farmFocusMinutes;  // 농장별 집중 시간
  final Map<String, List<String>> farmCompletedTasks;  // 완료된 할일
}
```

### 2. 실시간 통계 업데이트

```dart
// 타이머 완료 시 통계 즉시 업데이트
void recordTomatoHarvest({required String farmId, required DateTime date}) {
  final dateKey = _dateToString(date);
  final summary = _dailySummaries[dateKey] ?? DailySummary.empty(date);
  
  // 통계 업데이트
  summary.farmTomatoCounts[farmId] = (summary.farmTomatoCounts[farmId] ?? 0) + 1;
  
  _dailySummaries[dateKey] = summary;
  state = state.copyWith(dailySummaries: Map.from(_dailySummaries));
}
```

---

## 🧩 할일 관리 시스템

### 1. 농장-할일 연결 구조

```dart
class Task {
  final String id;
  final String farmId;      // 소속 농장 ID
  final String title;       // 할일 제목
  final bool isCompleted;   // 완료 여부
  final DateTime? completedAt;  // 완료 시간
}
```

### 2. 완료 할일 추적

```dart
// 할일 완료 시 통계에 기록
void toggleTaskCompletion(String taskId) {
  final task = state.firstWhere((t) => t.id == taskId);
  final updatedTask = task.copyWith(
    isCompleted: !task.isCompleted,
    completedAt: !task.isCompleted ? DateTime.now() : null,
  );
  
  // 통계 Provider에 완료 할일 알림
  if (updatedTask.isCompleted) {
    ref.read(statisticsProvider.notifier).recordTaskCompletion(updatedTask);
  }
}
```

---

## 🔧 학습 단계별 가이드

### 📚 Step 1: 기초 구조 이해 (1-2일)

**학습 목표:** Flutter 프로젝트 구조와 기본 개념 파악

```bash
# 프로젝트 실행 및 핫 리로드 체험
flutter run

# 파일 구조 탐색
lib/
├── main.dart          # ProviderScope와 MaterialApp 이해
├── utils/
│   ├── constants.dart # 상수 중심 개발 패턴
│   └── theme.dart     # Material 3 테마 시스템
```

**실습 과제:**
1. `main.dart`에서 ProviderScope의 역할 이해
2. `constants.dart`에서 타이머 기본값 변경해보기
3. `theme.dart`에서 앱 색상 변경 후 핫 리로드 확인

### 🔄 Step 2: 상태관리 시스템 (3-5일)

**학습 목표:** Riverpod Provider 패턴과 상태 연동 이해

```dart
// farm_provider.dart 분석 포인트
1. StateNotifier<List<Farm>> 패턴
2. _loadInitialFarms()에서 SharedPreferences 연동
3. addFarm(), updateFarm() 등 CRUD 메서드
4. _saveFarms()에서 자동 저장 패턴
```

**실습 과제:**
1. 새로운 농장 색상을 `constants.dart`에 추가
2. `FarmListNotifier`에 농장 정렬 기능 추가
3. `selectedFarmProvider`의 초기화 과정 따라가기

### ⏰ Step 3: 타이머 핵심 로직 (5-7일)

**학습 목표:** Stream 기반 실시간 상태 동기화와 서비스 레이어 분리

```dart
// timer_service.dart 핵심 분석
1. StreamController<TimerState> 패턴
2. Timer.periodic()을 이용한 1초마다 업데이트
3. 모드 전환 로직 (집중 → 휴식 → 긴휴식)
4. 알림 서비스와의 콜백 연동
```

**실습 과제:**
1. 개발자 모드로 5초 타이머 설정하여 전체 플로우 테스트
2. 자동 전환 vs 수동 전환 차이점 체험
3. 타이머 완료 시 토마토 수확 로직 추적

### 💾 Step 4: 데이터 영속성 (7-8일)

**학습 목표:** SharedPreferences와 JSON 직렬화 패턴

```dart
// storage_service.dart 분석 포인트
1. static 메서드 패턴으로 전역 접근
2. JSON 직렬화/역직렬화 (toJson/fromJson)
3. 예외 처리와 기본값 반환
4. await/async 비동기 패턴
```

**실습 과제:**
1. 새로운 설정값 저장/로드 메서드 추가
2. 에러 상황에서 기본값 복원 테스트
3. 앱 재시작 후 데이터 복원 확인

### 🎨 Step 5: UI 컴포넌트 시스템 (8-10일)

**학습 목표:** 상태 기반 UI 렌더링과 사용자 인터랙션

```dart
// timer_screen.dart 분석 포인트
1. ConsumerWidget vs Consumer 사용법
2. ref.watch()로 상태 구독
3. ref.read().notifier로 액션 호출
4. 조건부 UI 렌더링 (status에 따른 버튼 변화)
```

**실습 과제:**
1. 타이머 화면에 새로운 정보 표시 위젯 추가
2. 확인 다이얼로그 커스터마이징
3. 농장 선택 바텀시트 UI 개선

### 🔔 Step 6: 알림 시스템 (10-11일)

**학습 목표:** 로컬 알림과 백그라운드 실행

```dart
// notification_service.dart 분석 포인트
1. flutter_local_notifications 플러그인 사용
2. Android/iOS 플랫폼별 설정
3. ongoing 알림으로 스와이프 삭제 방지
4. 콜백 패턴으로 동적 정보 제공
```

**실습 과제:**
1. 알림 권한 요청 플로우 이해
2. 커스텀 알림 사운드 추가
3. 타이머 완료 시 다른 스타일 알림 테스트

### 📊 Step 7: 통계 및 캘린더 (11-12일)

**학습 목표:** 복합 데이터 처리와 캘린더 UI

```dart
// statistics_provider.dart 분석 포인트
1. Map<String, DailySummary> 구조로 일별 데이터 관리
2. 월간 집계 계산 로직
3. 농장별 필터링 기능
4. 실시간 업데이트 패턴
```

**실습 과제:**
1. 주간/연간 통계 추가
2. 통계 데이터 내보내기 기능
3. 캘린더에서 특정 날짜 통계 상세보기

---

## 🚀 고급 학습 주제

### 1. 성능 최적화

```dart
// Provider 최적화
final specificDataProvider = Provider((ref) {
  final allData = ref.watch(sourceProvider);
  return allData.where((item) => item.isActive).toList();
});

// 불필요한 리빌드 방지
ref.listen<TimerState>(timerProvider, (previous, next) {
  if (previous?.status != next.status) {
    // 상태 변화시만 실행
  }
});
```

### 2. 에러 처리 패턴

```dart
// AsyncValue를 활용한 에러 상태 관리
final dataProvider = FutureProvider<List<Farm>>((ref) async {
  try {
    return await StorageService.loadFarms();
  } catch (error, stackTrace) {
    // 에러 로깅 및 기본값 반환
    return [];
  }
});
```

### 3. 테스트 가능한 코드 설계

```dart
// 의존성 주입 패턴
class TimerService {
  TimerService({
    NotificationService? notificationService,
    StorageService? storageService,
  }) : _notificationService = notificationService ?? NotificationService(),
       _storageService = storageService ?? StorageService();
}
```

---

## 📝 실습 프로젝트 아이디어

### 초급 프로젝트
1. **새로운 통계 지표 추가**: 연속 집중 일수, 최장 집중 시간 등
2. **농장 카테고리 시스템**: 학습/운동/독서 등 카테고리별 관리
3. **성취 시스템**: 토마토 개수에 따른 뱃지/레벨 시스템

### 중급 프로젝트
1. **다크 모드 지원**: ThemeData와 상태관리 연동
2. **데이터 내보내기**: CSV/JSON 형식으로 통계 데이터 추출
3. **위젯 커스터마이징**: 홈 화면 위젯으로 타이머 표시

### 고급 프로젝트
1. **클라우드 동기화**: Firebase/Supabase 연동
2. **팀 농장 기능**: 여러 사용자가 함께 농장 관리
3. **AI 추천 시스템**: 사용 패턴 분석 후 최적 집중 시간 추천

---

## 🔗 추가 학습 자료

### 공식 문서
- [Flutter 공식 문서](https://docs.flutter.dev/)
- [Riverpod 공식 가이드](https://riverpod.dev/)
- [Dart 언어 가이드](https://dart.dev/guides)

### 핵심 개념별 문서
- [StateNotifier 패턴](https://riverpod.dev/docs/concepts/providers#statenotifierprovider)
- [SharedPreferences 가이드](https://pub.dev/packages/shared_preferences)
- [Local Notifications 설정](https://pub.dev/packages/flutter_local_notifications)

### 디버깅 도구
```bash
# Flutter Inspector로 위젯 트리 분석
flutter run --debug

# Riverpod 상태 변화 로깅
ref.listen(provider, (previous, next) {
  print('State changed: $previous -> $next');
});

# 성능 분석
flutter run --profile
```

---

## 💡 핵심 학습 포인트 요약

1. **상태 중심 설계**: UI는 상태의 반영일 뿐, 비즈니스 로직은 Provider에서 관리
2. **단방향 데이터 플로우**: Action → State Update → UI Rebuild
3. **관심사의 분리**: Service(비즈니스) → Provider(상태) → Widget(UI)
4. **불변성 원칙**: copyWith 패턴으로 안전한 상태 업데이트
5. **실시간 동기화**: Stream을 활용한 반응형 프로그래밍

**🎯 최종 목표: Flutter/Riverpod 패턴을 완전히 이해하여 확장 가능하고 유지보수 가능한 앱을 설계할 수 있는 능력 배양**