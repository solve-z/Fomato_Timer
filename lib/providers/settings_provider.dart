import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

/// 사운드 설정 Provider
class SoundSettingsNotifier extends StateNotifier<SoundSettings> {
  SoundSettingsNotifier() : super(const SoundSettings()) {
    _loadSettings();
  }

  /// 설정 로드
  void _loadSettings() async {
    try {
      final soundEnabled = await StorageService.loadSoundEnabled();
      final vibrationEnabled = await StorageService.loadVibrationEnabled();
      
      state = SoundSettings(
        soundEnabled: soundEnabled,
        vibrationEnabled: vibrationEnabled,
      );
    } catch (e) {
      // 에러 발생 시 기본값 유지
    }
  }

  /// 사운드 설정 변경
  void setSoundEnabled(bool enabled) async {
    state = state.copyWith(soundEnabled: enabled);
    await StorageService.saveSoundEnabled(enabled);
  }

  /// 진동 설정 변경
  void setVibrationEnabled(bool enabled) async {
    state = state.copyWith(vibrationEnabled: enabled);
    await StorageService.saveVibrationEnabled(enabled);
  }
}

/// 알림 설정 Provider
class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings()) {
    _loadSettings();
  }

  /// 설정 로드
  void _loadSettings() async {
    try {
      final notificationEnabled = await StorageService.loadNotificationEnabled();
      
      state = NotificationSettings(
        notificationEnabled: notificationEnabled,
      );
    } catch (e) {
      // 에러 발생 시 기본값 유지
    }
  }

  /// 알림 설정 변경
  void setNotificationEnabled(bool enabled) async {
    state = state.copyWith(notificationEnabled: enabled);
    await StorageService.saveNotificationEnabled(enabled);
  }
}

/// 사운드 설정 상태
class SoundSettings {
  final bool soundEnabled;
  final bool vibrationEnabled;

  const SoundSettings({
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  SoundSettings copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return SoundSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}

/// 알림 설정 상태
class NotificationSettings {
  final bool notificationEnabled;

  const NotificationSettings({
    this.notificationEnabled = false,
  });

  NotificationSettings copyWith({
    bool? notificationEnabled,
  }) {
    return NotificationSettings(
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }
}

/// 사운드 설정 Provider
final soundSettingsProvider = StateNotifierProvider<SoundSettingsNotifier, SoundSettings>((ref) {
  return SoundSettingsNotifier();
});

/// 알림 설정 Provider
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier();
});

/// 개발자 모드 설정 Provider
class DeveloperModeNotifier extends StateNotifier<bool> {
  DeveloperModeNotifier() : super(false) {
    _loadSettings();
  }

  /// 설정 로드
  void _loadSettings() async {
    try {
      final enabled = await StorageService.loadDeveloperModeEnabled();
      state = enabled;
    } catch (e) {
      // 에러 발생 시 기본값 유지
    }
  }

  /// 개발자 모드 토글
  void toggle() async {
    state = !state;
    await StorageService.saveDeveloperModeEnabled(state);
  }
}

/// 개발자 모드 Provider
final developerModeProvider = StateNotifierProvider<DeveloperModeNotifier, bool>((ref) {
  return DeveloperModeNotifier();
});