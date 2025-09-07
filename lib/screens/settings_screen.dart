import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timer_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/farm_provider.dart';
import '../providers/task_provider.dart';
import '../providers/statistics_provider.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../models/timer_state.dart';
import 'tag_management_screen.dart';

/// 설정 화면
/// 
/// 앱의 각종 설정을 관리합니다.
/// - 타이머 시간 설정
/// - 사운드 설정
/// - 알림 설정
/// - 기타 설정
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _versionTapCount = 0;

  @override
  Widget build(BuildContext context) {
    final timerSettings = ref.watch(timerSettingsProvider);
    final timerState = ref.watch(timerProvider);
    final isDeveloperMode = ref.watch(developerModeProvider);
    
    // 타이머가 실행 중이거나 일시정지 상태인지 확인
    final isTimerActive = timerState.status == TimerStatus.running || timerState.status == TimerStatus.paused;

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 타이머 설정 섹션
          _buildSectionHeader(context, '타이머 설정'),
          _buildTimerSettingsCard(context, ref, timerSettings, isTimerActive),
          const SizedBox(height: 20),

          // 사운드 & 알림 설정 섹션
          _buildSectionHeader(context, '사운드 & 알림'),
          _buildSoundSettingsCard(context, ref),
          const SizedBox(height: 20),

          // 태그 관리 섹션
          _buildSectionHeader(context, '태그 관리'),
          _buildTagManagementCard(context),
          const SizedBox(height: 20),

          // 개발자 모드 섹션 (활성화된 경우만 표시)
          if (isDeveloperMode) ...[
            _buildSectionHeader(context, '개발자 모드'),
            _buildDeveloperModeCard(context, ref, timerSettings, isTimerActive),
            const SizedBox(height: 20),
          ],

          // 기타 설정 섹션
          _buildSectionHeader(context, '기타'),
          _buildOtherSettingsCard(context, ref),
          const SizedBox(height: 20),

          // 앱 정보 섹션
          _buildSectionHeader(context, '앱 정보'),
          _buildAppInfoCard(context),
        ],
      ),
    );
  }

  /// 섹션 헤더
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  /// 타이머 설정 카드
  Widget _buildTimerSettingsCard(BuildContext context, WidgetRef ref, TimerSettings settings, bool isTimerActive) {
    final isDeveloperMode = ref.watch(developerModeProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 타이머 활성화 시 경고 메시지
            if (isTimerActive)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '타이머 실행 중에는 설정을 변경할 수 없습니다',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // 집중 시간 설정
            if (isDeveloperMode || settings.focusMinutes >= 15) 
              _buildSliderSetting(
                context,
                '집중 시간',
                settings.focusMinutes == 0 ? '5초 (테스트)' : '${settings.focusMinutes}분',
                isDeveloperMode ? settings.focusMinutes.toDouble() : 
                  math.max(settings.focusMinutes.toDouble(), 15.0),
                isDeveloperMode ? 0 : 15,
                60,
                isDeveloperMode ? 1 : 5,
                Icons.work,
                isTimerActive ? null : (value) {
                  ref.read(timerSettingsProvider.notifier).updateSettings(
                      settings.copyWith(focusMinutes: value.round()));
                },
                enabled: !isTimerActive,
              )
            else
              // 개발자 모드가 아닌데 0값인 경우 자동 복원 메시지
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '개발자 모드 설정이 감지되었습니다',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(timerSettingsProvider.notifier).updateSettings(
                          const TimerSettings(),
                        );
                      },
                      child: const Text('기본값으로 복원'),
                    ),
                  ],
                ),
              ),
            const Divider(),

            // 짧은 휴식 시간 설정
            if (isDeveloperMode || settings.shortBreakMinutes >= 3)
              _buildSliderSetting(
                context,
                '짧은 휴식',
                settings.shortBreakMinutes == 0 ? '5초 (테스트)' : '${settings.shortBreakMinutes}분',
                isDeveloperMode ? settings.shortBreakMinutes.toDouble() : 
                  math.max(settings.shortBreakMinutes.toDouble(), 3.0),
                isDeveloperMode ? 0 : 3,
                15,
                1,
                Icons.coffee,
                isTimerActive ? null : (value) {
                  ref.read(timerSettingsProvider.notifier).updateSettings(
                      settings.copyWith(shortBreakMinutes: value.round()));
                },
                enabled: !isTimerActive,
              ),
            const Divider(),

            // 긴 휴식 시간 설정
            if (isDeveloperMode || settings.longBreakMinutes >= 10)
              _buildSliderSetting(
                context,
                '긴 휴식',
                settings.longBreakMinutes == 0 ? '5초 (테스트)' : '${settings.longBreakMinutes}분',
                isDeveloperMode ? settings.longBreakMinutes.toDouble() : 
                  math.max(settings.longBreakMinutes.toDouble(), 10.0),
                isDeveloperMode ? 0 : 10,
                30,
                isDeveloperMode ? 1 : 5,
                Icons.hotel,
                isTimerActive ? null : (value) {
                  ref.read(timerSettingsProvider.notifier).updateSettings(
                      settings.copyWith(longBreakMinutes: value.round()));
                },
                enabled: !isTimerActive,
              ),
            const Divider(),

            // 라운드 수 설정
            _buildSliderSetting(
              context,
              '긴 휴식까지 라운드',
              '${settings.roundsUntilLongBreak}라운드',
              settings.roundsUntilLongBreak.toDouble(),
              2, // 최소값
              8, // 최대값
              1, // 증가값
              Icons.repeat,
              isTimerActive ? null : (value) {
                ref.read(timerSettingsProvider.notifier).updateSettings(
                    settings.copyWith(roundsUntilLongBreak: value.round()));
              },
              enabled: !isTimerActive,
            ),
          ],
        ),
      ),
    );
  }

  /// 슬라이더 설정 위젯
  Widget _buildSliderSetting(
    BuildContext context,
    String title,
    String value,
    double currentValue,
    double min,
    double max,
    double divisions,
    IconData icon,
    ValueChanged<double>? onChanged, {
    bool enabled = true,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: enabled ? null : Colors.grey),
          title: Text(
            title,
            style: enabled ? null : TextStyle(color: Colors.grey.shade600),
          ),
          trailing: Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: enabled ? null : Colors.grey.shade600,
            ),
          ),
        ),
        Slider(
          value: currentValue,
          min: min,
          max: max,
          divisions: ((max - min) / divisions).round(),
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }

  /// 태그 관리 카드
  Widget _buildTagManagementCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListTile(
          leading: const Icon(Icons.local_offer),
          title: const Text('태그 관리'),
          subtitle: const Text('할일에 사용할 태그를 추가, 수정, 삭제할 수 있습니다'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const TagManagementScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 사운드 설정 카드
  Widget _buildSoundSettingsCard(BuildContext context, WidgetRef ref) {
    final soundSettings = ref.watch(soundSettingsProvider);
    final notificationSettings = ref.watch(notificationSettingsProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('사운드 알림'),
              subtitle: const Text('타이머 완료 시 소리로 알림'),
              value: soundSettings.soundEnabled,
              onChanged: (value) {
                ref.read(soundSettingsProvider.notifier).setSoundEnabled(value);
              },
              secondary: const Icon(Icons.volume_up),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('진동 알림'),
              subtitle: const Text('타이머 완료 시 진동으로 알림'),
              value: soundSettings.vibrationEnabled,
              onChanged: (value) {
                ref.read(soundSettingsProvider.notifier).setVibrationEnabled(value);
              },
              secondary: const Icon(Icons.vibration),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('푸시 알림'),
              subtitle: const Text('앱이 백그라운드에 있을 때도 알림'),
              value: notificationSettings.notificationEnabled,
              onChanged: (value) async {
                if (value) {
                  // 알림 활성화 시 권한 요청
                  final granted = await NotificationService().requestPermissions();
                  if (granted) {
                    ref.read(notificationSettingsProvider.notifier).setNotificationEnabled(value);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('알림 권한이 허용되었습니다'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('알림 권한이 거부되었습니다. 설정에서 직접 허용해주세요'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                } else {
                  // 알림 비활성화
                  ref.read(notificationSettingsProvider.notifier).setNotificationEnabled(value);
                }
              },
              secondary: const Icon(Icons.notifications),
            ),
          ],
        ),
      ),
    );
  }

  /// 기타 설정 카드
  Widget _buildOtherSettingsCard(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('다크 모드'),
              subtitle: const Text('어두운 테마 사용'),
              trailing: Switch(
                value: false, // 임시값
                onChanged: (value) {
                  // TODO: 다크 모드 Provider 구현
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('언어 설정'),
              subtitle: const Text('한국어'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: 언어 설정 화면 이동
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('언어 설정은 추후 구현 예정입니다')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('데이터 백업'),
              subtitle: const Text('농장 및 통계 데이터 백업'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: 데이터 백업 기능 구현
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('데이터 백업은 추후 구현 예정입니다')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red.shade600),
              title: Text(
                '모든 데이터 초기화',
                style: TextStyle(color: Colors.red.shade600),
              ),
              subtitle: const Text('농장, 통계, 설정 등 모든 데이터 삭제'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showResetDataDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  /// 개발자 모드 카드
  Widget _buildDeveloperModeCard(BuildContext context, WidgetRef ref, TimerSettings settings, bool isTimerActive) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 개발자 모드 헤더
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.developer_mode, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '개발자 모드 (테스트용)',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // 개발자 모드 비활성화 시 5초 타이머가 설정되어 있으면 기본값으로 복원
                      if (settings.focusMinutes == 0 || settings.shortBreakMinutes == 0 || settings.longBreakMinutes == 0) {
                        ref.read(timerSettingsProvider.notifier).updateSettings(
                          const TimerSettings(), // 기본값으로 복원
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('타이머 설정이 기본값으로 복원되었습니다'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                      ref.read(developerModeProvider.notifier).toggle();
                    },
                    child: const Text('비활성화'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5초 타이머 설정
            ElevatedButton.icon(
              onPressed: isTimerActive ? null : () {
                ref.read(timerSettingsProvider.notifier).updateSettings(
                  TimerSettings(
                    focusMinutes: 0, // 5초를 위한 특수값
                    shortBreakMinutes: 0,
                    longBreakMinutes: 0,
                    roundsUntilLongBreak: settings.roundsUntilLongBreak,
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('모든 타이머가 5초로 설정되었습니다 (테스트용)'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.speed),
              label: const Text('5초 테스트 타이머 설정'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // 기본값 복원
            ElevatedButton.icon(
              onPressed: isTimerActive ? null : () {
                ref.read(timerSettingsProvider.notifier).updateSettings(
                  const TimerSettings(), // 기본값으로 복원
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('타이머 설정이 기본값으로 복원되었습니다'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.restore),
              label: const Text('기본값으로 복원'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade400,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 앱 정보 카드
  Widget _buildAppInfoCard(BuildContext context) {
    final isDeveloperMode = ref.watch(developerModeProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('앱 버전'),
              subtitle: Text(isDeveloperMode ? '1.0.0 (개발자 모드)' : '1.0.0'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                setState(() {
                  _versionTapCount++;
                });

                if (_versionTapCount >= 10 && !isDeveloperMode) {
                  ref.read(developerModeProvider.notifier).toggle();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔧 개발자 모드가 활성화되었습니다!'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                  setState(() {
                    _versionTapCount = 0;
                  });
                } else if (_versionTapCount < 10 && !isDeveloperMode) {
                  // 힌트 표시 (5번 탭 이후)
                  if (_versionTapCount >= 5) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('개발자 모드까지 ${10 - _versionTapCount}번 남았습니다'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                } else {
                  // 일반적인 정보 다이얼로그
                  showAboutDialog(
                    context: context,
                    applicationName: 'Fomato',
                    applicationVersion: '1.0.0',
                    applicationIcon: const Icon(Icons.eco, size: 48),
                    children: [
                      const Text('토마토 농장형 뽀모도로 타이머'),
                      const Text('25분 집중하여 토마토를 수확하세요!'),
                    ],
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('도움말'),
              subtitle: const Text('앱 사용법 및 FAQ'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: 도움말 화면 이동
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('도움말은 추후 구현 예정입니다')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('피드백 보내기'),
              subtitle: const Text('의견이나 문제점을 알려주세요'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: 피드백 기능 구현
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('피드백 기능은 추후 구현 예정입니다')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 데이터 초기화 확인 다이얼로그
  void _showResetDataDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: Icon(Icons.warning, color: Colors.red.shade600, size: 48),
          title: const Text('모든 데이터 초기화'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('다음 데이터가 모두 삭제됩니다:'),
              SizedBox(height: 8),
              Text('• 모든 농장 데이터'),
              Text('• 토마토 수확 기록'),
              Text('• 통계 데이터'),
              Text('• 할일 목록'),
              Text('• 타이머 설정'),
              Text('• 사운드/알림 설정'),
              SizedBox(height: 16),
              Text(
                '이 작업은 되돌릴 수 없습니다.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('초기화'),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true && context.mounted) {
      _resetAllData(context, ref);
    }
  }

  /// 모든 데이터 초기화 실행
  void _resetAllData(BuildContext context, WidgetRef ref) async {
    // BuildContext 마운트 상태 확인을 위한 변수
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      // 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('데이터를 초기화하고 있습니다...'),
            ],
          ),
        ),
      );

      // StorageService를 통해 모든 데이터 삭제
      await StorageService.clearAllData();

      // Provider 상태들을 기본값으로 리셋
      ref.invalidate(farmListProvider);
      ref.invalidate(statisticsProvider);
      ref.invalidate(timerSettingsProvider);
      ref.invalidate(soundSettingsProvider);
      ref.invalidate(notificationSettingsProvider);
      ref.invalidate(selectedFarmProvider);
      ref.invalidate(taskListProvider);
      ref.invalidate(developerModeProvider);

      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        navigator.pop();
        
        // 성공 메시지 표시
        messenger.showSnackBar(
          const SnackBar(
            content: Text('모든 데이터가 성공적으로 초기화되었습니다'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        navigator.pop();
        
        // 에러 메시지 표시
        messenger.showSnackBar(
          SnackBar(
            content: Text('데이터 초기화 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}