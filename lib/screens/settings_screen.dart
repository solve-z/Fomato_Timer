import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timer_provider.dart';

/// 설정 화면
/// 
/// 앱의 각종 설정을 관리합니다.
/// - 타이머 시간 설정
/// - 사운드 설정
/// - 알림 설정
/// - 기타 설정
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerSettings = ref.watch(timerSettingsProvider);

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
          _buildTimerSettingsCard(context, ref, timerSettings),
          const SizedBox(height: 20),

          // 사운드 & 알림 설정 섹션
          _buildSectionHeader(context, '사운드 & 알림'),
          _buildSoundSettingsCard(context, ref),
          const SizedBox(height: 20),

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
  Widget _buildTimerSettingsCard(BuildContext context, WidgetRef ref, TimerSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 집중 시간 설정
            _buildSliderSetting(
              context,
              '집중 시간',
              '${settings.focusMinutes}분',
              settings.focusMinutes.toDouble(),
              15, // 최소값
              60, // 최대값
              5,  // 증가값
              Icons.work,
              (value) {
                ref.read(timerSettingsProvider.notifier).state = 
                    settings.copyWith(focusMinutes: value.round());
              },
            ),
            const Divider(),

            // 짧은 휴식 시간 설정
            _buildSliderSetting(
              context,
              '짧은 휴식',
              '${settings.shortBreakMinutes}분',
              settings.shortBreakMinutes.toDouble(),
              3,  // 최소값
              15, // 최대값
              1,  // 증가값
              Icons.coffee,
              (value) {
                ref.read(timerSettingsProvider.notifier).state = 
                    settings.copyWith(shortBreakMinutes: value.round());
              },
            ),
            const Divider(),

            // 긴 휴식 시간 설정
            _buildSliderSetting(
              context,
              '긴 휴식',
              '${settings.longBreakMinutes}분',
              settings.longBreakMinutes.toDouble(),
              10, // 최소값
              30, // 최대값
              5,  // 증가값
              Icons.hotel,
              (value) {
                ref.read(timerSettingsProvider.notifier).state = 
                    settings.copyWith(longBreakMinutes: value.round());
              },
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
              (value) {
                ref.read(timerSettingsProvider.notifier).state = 
                    settings.copyWith(roundsUntilLongBreak: value.round());
              },
            ),
            const Divider(),

            // 자동 시작 설정
            SwitchListTile(
              title: const Text('다음 모드 자동 시작'),
              subtitle: const Text('타이머 완료 후 자동으로 다음 모드 시작'),
              value: settings.autoStartNext,
              onChanged: (value) {
                ref.read(timerSettingsProvider.notifier).state = 
                    settings.copyWith(autoStartNext: value);
              },
              secondary: const Icon(Icons.play_circle),
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
    ValueChanged<double> onChanged,
  ) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Slider(
          value: currentValue,
          min: min,
          max: max,
          divisions: ((max - min) / divisions).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// 사운드 설정 카드
  Widget _buildSoundSettingsCard(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('사운드 알림'),
              subtitle: const Text('타이머 완료 시 소리로 알림'),
              value: true, // 임시값
              onChanged: (value) {
                // TODO: 사운드 설정 Provider 구현
              },
              secondary: const Icon(Icons.volume_up),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('진동 알림'),
              subtitle: const Text('타이머 완료 시 진동으로 알림'),
              value: true, // 임시값
              onChanged: (value) {
                // TODO: 진동 설정 Provider 구현
              },
              secondary: const Icon(Icons.vibration),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('푸시 알림'),
              subtitle: const Text('앱이 백그라운드에 있을 때도 알림'),
              value: false, // 임시값
              onChanged: (value) {
                // TODO: 푸시 알림 설정 Provider 구현
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
          ],
        ),
      ),
    );
  }

  /// 앱 정보 카드
  Widget _buildAppInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('앱 버전'),
              subtitle: const Text('1.0.0'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
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
}