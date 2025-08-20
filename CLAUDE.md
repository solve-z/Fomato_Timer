# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Fomato** - 토마토 농장형 뽀모도로 앱
토마토 농장으로 할 일을 시각화하고, 25분 집중 시 토마토 1개를 수확하는 심플한 뽀모도로 타이머 앱입니다.

## Development Commands

```bash
# 프로젝트 실행
flutter run

# 패키지 설치
flutter pub get

# 코드 분석
flutter analyze

# 테스트 실행
flutter test

# 빌드
flutter build apk           # Android
flutter build ios          # iOS
flutter build web          # Web
```

## Architecture & State Management

### 상태 관리: Flutter Riverpod
프로젝트는 Riverpod을 기반으로 한 상태 관리를 사용합니다.

### 주요 Provider 구조
```dart
// 농장 목록 및 선택
final farmListProvider = StateNotifierProvider<FarmListNotifier, List<Farm>>();
final selectedFarmProvider = StateProvider<Farm?>();

// 타이머 상태
final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>();
final timerSettingsProvider = StateProvider<TimerSettingsState>();

// 애니메이션, 사운드, 통계
final animationProvider = StateProvider<AnimationState>();
final soundSettingsProvider = StateProvider<SoundSettingsState>();
final statisticsProvider = StateNotifierProvider<StatisticsNotifier, StatisticsState>();
```

### 핵심 상태 흐름
1. **타이머 시작** → 남은 시간 업데이트 → 25분 달성 시 토마토 수확 +1
2. **농장 선택** → 타이머 연동 → 통계 필터 적용
3. **설정 변경** → 타이머/애니메이션/사운드 전체 반영

## Project Structure

```
lib/
├── main.dart                 # 앱 진입점
├── models/                   # 데이터 모델
│   ├── farm.dart
│   ├── timer_state.dart
│   └── statistics.dart
├── providers/                # Riverpod Providers
│   ├── farm_provider.dart
│   ├── timer_provider.dart
│   └── settings_provider.dart
├── screens/                  # 화면 위젯
│   ├── timer_screen.dart
│   ├── farm_screen.dart
│   ├── statistics_screen.dart
│   └── settings_screen.dart
├── widgets/                  # 재사용 위젯
│   ├── timer_widget.dart
│   ├── farm_widget.dart
│   └── bottom_navigation.dart
├── services/                 # 서비스 로직
│   ├── timer_service.dart
│   ├── notification_service.dart
│   └── storage_service.dart
└── utils/                    # 유틸리티
    ├── constants.dart
    └── theme.dart
```

## Key Features & Implementation

### 1. 타이머 (Timer Screen)
- 집중/휴식/긴휴식 모드
- 25분 집중 완료 시 토마토 1개 수확
- 진행도 표시 (● ○ ○ ○)
- 애니메이션 배경

### 2. 농장 (Farm Management)
- 농장 = 프로젝트/할 일 그룹
- 잔디 모양 UI로 토마토 수확 시각화
- 농장 선택 시 타이머와 연동

### 3. 통계 (Statistics)
- 캘린더 뷰: 토마토 수확 표시
- 월간 요약: 총 토마토, 집중 시간 등
- 농장별 필터링

### 4. 설정 (Settings)
- 타이머 설정 (집중/휴식 시간, 반복 횟수)
- 사운드 설정 (무음/백색소음/휴식 소리)
- 애니메이션 선택
- D-DAY 설정

## Design System

### 컬러 팔레트 (appstyle.json 기반)
- Primary: #4CAF50 (녹색)
- Secondary: #FFC107 (노란색)  
- Background: #FFFFFF (흰색)
- Surface: #F7F7F7 (연한 회색)

### UI 스타일
- 심플하고 미니멀한 화이트톤
- 귀여운 토마토 캐릭터 일러스트 중심
- 둥근 모서리 (borderRadius: 12-16)
- 그림자 효과 최소화 (elevation: 0-2)

## Core Business Rules

1. **25분 집중 = 토마토 1개 수확** (할 일 완료 여부와 무관)
2. **농장 선택 시 해당 농장 데이터만 표시**
3. **통계는 토마토 수확 기준으로 표시**
4. **설정 변경 시 전체 앱에 즉시 반영**

## Development Notes

- Flutter SDK: ^3.7.2
- 상태 관리: flutter_riverpod 사용 예정
- 로컬 저장: SharedPreferences 또는 Hive 사용 예정
- 알림: flutter_local_notifications 사용 예정
- 애니메이션: 기본 Flutter Animation 사용