Fomato – 토마토 농장형 뽀모도로 앱 (최종 기획서)
1. 핵심 컨셉

할 일 → 토마토 농장으로 시각화

집중 시간 25분 → 토마토 1개 수확

할 일 완료 여부와 무관

UI 스타일: "심플하고 미니멀한 화이트톤, 캐릭터 일러스트 중심"

2. 핵심 기능
2.1 타이머

집중/휴식/긴 휴식 설정 가능

반복 횟수 설정 (예: 4회 집중 후 긴 휴식)

화면 구성

상단: 선택된 농장/클릭 시 할 일 목록볼수있는 아이콘, 큰 타이머, 상태 표시, 집중 횟수 진행도 (● ○ ○ ○)

중단: 집중/휴식 애니메이션

하단: 화면 전환 가능한 바텀네비게이션바 

배경: 집중/휴식 애니메이션

규칙

25분 집중 → 토마토 1개 수확

2.2 스톱워치

단순 누적 기록

선택한 할 일/농장에 집중 시간 누적

2.3 농장 (할 일 목록)

농장 = 프로젝트 / 할 일 그룹

여러 농장 생성 가능

잔디 모양 UI로 시각화

농장 선택 시 타이머와 연동

농장 성장 → 토마토 수확 데이터 반영

2.4 통계

농장 선택 드롭다운: 전체/농장별

캘린더 뷰: 토마토 수확 표시

날짜 클릭 시 상세 정보:

토마토 수확 개수
집중 시간


하단 월간 요약:

총 토마토 수확
총 수확한 날
총 집중 시간
완료한 세션 수
평균 집중 시간

2.5 내 정보

오른쪽 상단 톱니바퀴 → 설정창 진입

포함 설정

집중 설정 (기본 집중 시간, 반복 횟수)

D-DAY 설정

사용자 지정 시간 설정

무음 모드 토글

백색소음 설정

휴식 소리 설정

알림 설정

다음 휴식/집중 자동 시작 토글

집중 애니메이션 선택

휴식 애니메이션 선택

3. 데이터 흐름

[타이머 실행]

25분 집중 달성 → 토마토 1개 수확

농장 성장 데이터 업데이트

[농장 UI]

토마토 수확 개수 → 시각적 반영

[통계]

캘린더: 토마토 수확 표시

상세 정보: 토마토 수확 개수, 집중 시간

월간 요약: 총 수확 토마토, 총 집중 시간

[내 정보 설정]

집중/휴식 시간, 반복 횟수 → 타이머 기본값 반영

D-DAY, 사용자 지정 시간 → 알림/캘린더 반영

무음/백색소음/휴식 소리 → 타이머 사운드 설정

다음 휴식/집중 자동 시작 → 타이머 자동 전환

집중/휴식 애니메이션 → 타이머 배경 애니메이션 적용

4. 핵심 규칙 요약

집중 25분 → 토마토 1개 수확

할 일 완료 여부와 무관

통계/캘린더 → 토마토 수확 기준으로 표시

농장 선택 시 해당 농장 데이터 확인 가능

내 정보 설정 → 타이머, 알림, 사운드, 애니메이션 등 전체 반영

Fomato – Riverpod 기반 상태 관리 구조
1. 핵심 상태 정의
1.1 농장 관련 상태

FarmListState

농장 목록, 선택된 농장 정보, 농장별 토마토 수확 개수

SelectedFarmState

현재 선택된 농장

타이머 연동, 통계 반영

1.2 타이머 관련 상태

TimerState

현재 모드 (집중 / 휴식 / 긴휴식 / 스톱워치)

남은 시간

진행 중 여부 (running / paused / stopped)

집중 횟수 (25분 단위, 토마토 수확과 연결)

TimerSettingsState

집중/휴식/긴휴식 시간

반복 횟수

자동 전환 여부 (다음 집중/휴식 자동 시작)

1.3 애니메이션 상태

AnimationState

집중 애니메이션 선택

휴식 애니메이션 선택

1.4 사운드 & 알림 상태

SoundSettingsState

무음 모드

백색소음 ON/OFF

휴식 소리 ON/OFF

NotificationSettingsState

알림 설정

D-DAY, 사용자 지정 시간

1.5 통계 상태

StatisticsState

농장별 토마토 수확 기록

집중 시간 기록

달력 표시용 상태

2. Riverpod Provider 설계
// 농장 목록 및 선택
final farmListProvider = StateNotifierProvider<FarmListNotifier, List<Farm>>(...);
final selectedFarmProvider = StateProvider<Farm?>((ref) => null);

// 타이머 상태
final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>(...);
final timerSettingsProvider = StateProvider<TimerSettingsState>((ref) => ...);

// 애니메이션 선택
final animationProvider = StateProvider<AnimationState>((ref) => ...);

// 사운드 & 알림
final soundSettingsProvider = StateProvider<SoundSettingsState>((ref) => ...);
final notificationSettingsProvider = StateProvider<NotificationSettingsState>((ref) => ...);

// 통계
final statisticsProvider = StateNotifierProvider<StatisticsNotifier, StatisticsState>(...);

3. 상태 흐름 예시

[타이머 시작]

timerProvider 상태 변경 → 남은 시간 업데이트

25분 달성 시 → selectedFarmProvider 토마토 수확 +1

statisticsProvider 업데이트 → 달력 & 월간 통계 반영

animationProvider → 선택된 애니메이션 표시

soundSettingsProvider → 사운드/백색소음/휴식 소리 재생

[농장 선택]

selectedFarmProvider 변경 → timerProvider 연동

statisticsProvider 필터 적용 (선택 농장 기준)

[내 정보 설정 변경]

timerSettingsProvider → 타이머 시간/반복 횟수 반영

animationProvider → 애니메이션 변경

soundSettingsProvider → 사운드/무음/백색소음 반영

notificationSettingsProvider → 알림/자동 시작 반영