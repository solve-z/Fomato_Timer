# 🎓 Fomato 프로젝트 학습 가이드

**Phase 1 완성 코드를 체계적으로 이해하기**

현재 여러분이 만든 Fomato 앱의 코드를 단계별로 분석하며 Flutter + Riverpod의 핵심 개념을 익혀보세요.

---

## 📚 **학습 순서 (3-5일 권장)**

### **Day 1: Flutter 기본 구조 이해**
### **Day 2: 데이터 모델 & 상태 관리**  
### **Day 3: UI 구조 & 네비게이션**
### **Day 4: Provider 패턴 심화**
### **Day 5: 전체 플로우 정리**

---

## 🚀 **Day 1: Flutter 기본 구조 이해**

### 🔍 **1단계: 앱의 진입점 분석**
**파일**: `lib/main.dart`

```dart
void main() {
  runApp(const ProviderScope(child: FomatoApp()));
}
```

**❓ 이해해야 할 질문들:**
1. `runApp()`은 무엇을 하는 함수인가?
2. `ProviderScope`는 왜 필요한가?
3. `const` 키워드는 언제 사용하는가?

**🔎 학습 활동:**
- `main.dart`에서 `ProviderScope`를 제거해보고 어떤 오류가 나는지 확인
- `FomatoApp` 위젯의 `build` 메서드가 무엇을 반환하는지 확인
- `MaterialApp`의 주요 속성들(`title`, `theme`, `home`) 이해

### 🎨 **2단계: 테마 시스템 분석**
**파일**: `lib/utils/theme.dart`, `lib/utils/constants.dart`

**❓ 이해해야 할 질문들:**
1. `AppColors.primary`는 어떻게 앱 전체에 적용되는가?
2. `ThemeData`의 각 속성이 어떤 UI에 영향을 주는가?
3. 상수(`AppConstants`)를 별도 파일로 분리하는 이유는?

**🔎 학습 활동:**
- `AppColors.primary` 색상을 다른 색으로 바꿔보기
- `AppSizes.cardBorderRadius` 값을 변경해서 카드 모양 변화 확인
- 새로운 상수를 `AppConstants`에 추가해보기

---

## 🗂️ **Day 2: 데이터 모델 & 상태 관리**

### 📋 **1단계: 데이터 모델 분석**
**파일**: `lib/models/farm.dart`

```dart
class Farm {
  final String id;
  final String name;
  final String color;
  final int tomatoCount;
  // ...
}
```

**❓ 이해해야 할 질문들:**
1. 왜 모든 필드가 `final`인가?
2. `fromJson`, `toJson` 메서드는 언제 사용되는가?
3. `copyWith` 메서드의 용도는 무엇인가?

**🔎 학습 활동:**
- `Farm` 객체를 생성하고 `addTomato()` 메서드 테스트
- `toJson()` 결과를 출력해보기
- 새로운 필드(예: `createdDate`)를 추가해보기

### 🔄 **2단계: Provider 기본 개념**
**파일**: `lib/providers/farm_provider.dart`

```dart
final farmListProvider = StateNotifierProvider<FarmListNotifier, List<Farm>>((ref) {
  return FarmListNotifier();
});
```

**❓ 이해해야 할 질문들:**
1. `StateNotifierProvider`와 `StateProvider`의 차이점은?
2. `ref.watch()`와 `ref.read()`는 언제 사용하는가?
3. `state = [...state, newFarm]`에서 스프레드 연산자(`...`)의 역할은?

**🔎 학습 활동:**
- 농장 추가/삭제 기능을 직접 테스트
- `FarmListNotifier`의 각 메서드 동작 확인
- `selectedFarmProvider`가 어떻게 연동되는지 추적

---

## 🎨 **Day 3: UI 구조 & 네비게이션**

### 📱 **1단계: 화면 구조 분석**
**파일**: `lib/widgets/bottom_navigation.dart`

```dart
body: IndexedStack(
  index: _currentIndex,
  children: _screens,
),
```

**❓ 이해해야 할 질문들:**
1. `IndexedStack`과 일반적인 조건부 렌더링의 차이점은?
2. `StatefulWidget`과 `StatelessWidget`의 차이점은?
3. `setState()`는 무엇을 트리거하는가?

**🔎 학습 활동:**
- 탭 전환 시 각 화면의 상태가 유지되는지 확인
- 새로운 탭을 추가해보기
- `_currentIndex` 값이 어떻게 UI에 반영되는지 관찰

### 🖼️ **2단계: 화면별 위젯 분석**
**파일**: `lib/screens/timer_screen.dart`

```dart
class TimerScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    // ...
  }
}
```

**❓ 이해해야 할 질문들:**
1. `ConsumerWidget`과 일반 `StatelessWidget`의 차이점은?
2. `ref.watch()`가 호출되면 언제 UI가 다시 빌드되는가?
3. `Scaffold`, `AppBar`, `Body`의 역할 구분은?

**🔎 학습 활동:**
- `timerState` 값을 다른 Provider로 변경해보기
- 농장 선택 다이얼로그 동작 방식 분석
- UI 레이아웃이 어떻게 구성되어 있는지 확인

---

## 🧠 **Day 4: Provider 패턴 심화**

### 🔄 **1단계: 상태 변경 플로우 추적**
**파일**: `lib/providers/timer_provider.dart`

```dart
void start() {
  state = state.copyWith(
    status: TimerStatus.running,
    startTime: DateTime.now(),
  );
  _startTicking();
}
```

**❓ 이해해야 할 질문들:**
1. `state` 변경이 어떻게 UI 업데이트를 트리거하는가?
2. `Timer.periodic`은 어떻게 매초 실행되는가?
3. `StateNotifier`의 생명주기는 어떻게 관리되는가?

**🔎 학습 활동:**
- 타이머 시작/정지 버튼 클릭 시 상태 변화 추적
- `_startTicking()` 메서드의 로직 단계별 분석
- `ref.read().notifier`와 `ref.watch()`의 사용 구분

### 🔗 **2단계: Provider 간 의존성**
**파일**: `lib/providers/statistics_provider.dart`

```dart
void recordTomatoHarvest({
  required String farmId,
  required DateTime date,
  int focusMinutes = 25,
}) {
  // 통계 업데이트 로직
}
```

**❓ 이해해야 할 질문들:**
1. 타이머 완료 시 어떻게 통계가 자동 업데이트되는가?
2. 여러 Provider가 어떻게 서로 소통하는가?
3. `Provider.family`의 활용 방법은?

**🔎 학습 활동:**
- 토마토 수확 시 데이터 흐름 전체 추적
- 농장 선택 시 통계 필터링 동작 확인
- Provider 간 순환 의존성이 없는지 확인

---

## 🎯 **Day 5: 전체 플로우 정리**

### 🧩 **1단계: 데이터 흐름 전체 그림**

```
[UI 이벤트] → [Provider] → [State 변경] → [UI 업데이트]
     ↓              ↓              ↓              ↓
타이머 시작 → TimerNotifier → 남은시간 감소 → 화면 업데이트
농장 선택   → FarmProvider  → 선택 상태    → 농장 표시
토마토 수확 → 다중 Provider → 통계 갱신    → 수치 업데이트
```

**🔎 학습 활동:**
- 하나의 기능(예: 토마토 수확)을 처음부터 끝까지 추적
- 각 Provider의 역할과 책임 범위 정리
- UI 컴포넌트와 비즈니스 로직의 분리 확인

### 📝 **2단계: 코드 품질 체크**

**확인할 항목들:**
1. **불변성**: 모든 상태가 불변 객체로 관리되는가?
2. **단일 책임**: 각 Provider가 명확한 책임을 가지는가?
3. **재사용성**: UI 컴포넌트가 적절히 분리되어 있는가?
4. **타입 안전성**: 타입이 명확히 정의되어 있는가?

**🔎 학습 활동:**
- `flutter analyze` 결과 확인
- 코드 중복 부분 찾아보기
- 개선할 수 있는 부분 리스트업

---

## 🎓 **추가 학습 리소스**

### 📖 **공식 문서**
- [Flutter 위젯 카탈로그](https://docs.flutter.dev/ui/widgets)
- [Riverpod 공식 가이드](https://riverpod.dev/docs/introduction/getting_started)
- [Dart 언어 투어](https://dart.dev/guides/language/language-tour)

### 🛠️ **실습 아이디어**
1. **새로운 필드 추가**: 농장에 `description` 필드 추가해보기
2. **새로운 Provider**: 앱 설정을 관리하는 Provider 만들기
3. **UI 커스터마이징**: 타이머 모양을 원형으로 바꿔보기
4. **에러 처리**: 잘못된 입력에 대한 에러 처리 추가

### 🔍 **디버깅 팁**
```dart
// Provider 상태 확인
print('Current farm list: ${ref.read(farmListProvider)}');

// 위젯 리빌드 확인
Widget build(BuildContext context, WidgetRef ref) {
  print('TimerScreen rebuilt');
  // ...
}
```

---

## ✅ **학습 완료 체크리스트**

### **기본 개념**
- [ ] Flutter 위젯 트리 구조 이해
- [ ] StatelessWidget vs StatefulWidget 차이점
- [ ] BuildContext의 역할
- [ ] Hot Reload vs Hot Restart

### **Riverpod 상태 관리**
- [ ] Provider vs StateNotifierProvider 차이점
- [ ] ref.watch() vs ref.read() 사용법
- [ ] 상태 불변성의 중요성
- [ ] Provider 간 의존성 관리

### **프로젝트 구조**
- [ ] 각 폴더의 역할과 책임
- [ ] 데이터 모델 설계 원칙
- [ ] UI와 비즈니스 로직 분리
- [ ] 코드 재사용성 고려

### **실무 스킬**
- [ ] 디버깅 방법
- [ ] 에러 처리 패턴  
- [ ] 코드 품질 관리
- [ ] 성능 최적화 고려사항

---

**🎯 완료 후 다음 단계**: Phase 2로 진행하여 실제 타이머 기능을 구현해보세요!

이 가이드를 통해 현재 코드를 완전히 이해하고 나면, 다음 단계에서 더 복잡한 기능을 자신 있게 구현할 수 있을 것입니다.