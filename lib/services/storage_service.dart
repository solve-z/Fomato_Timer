import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/farm.dart';
import '../models/statistics.dart';

/// 로컬 저장소 서비스
/// 
/// SharedPreferences를 사용하여 앱 데이터를 로컬에 저장/로드합니다.
/// - 농장 데이터
/// - 통계 데이터  
/// - 설정 데이터
class StorageService {
  static const String _farmsKey = 'farms';
  static const String _statisticsKey = 'statistics';
  static const String _selectedFarmIdKey = 'selected_farm_id';
  static const String _timerSettingsKey = 'timer_settings';

  /// SharedPreferences 인스턴스 가져오기
  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // ==== 농장 데이터 관리 ====

  /// 농장 목록 저장
  static Future<void> saveFarms(List<Farm> farms) async {
    final prefs = await _prefs;
    final farmsJson = farms.map((farm) => farm.toJson()).toList();
    await prefs.setString(_farmsKey, jsonEncode(farmsJson));
  }

  /// 농장 목록 로드
  static Future<List<Farm>> loadFarms() async {
    try {
      final prefs = await _prefs;
      final farmsString = prefs.getString(_farmsKey);
      
      if (farmsString == null) return [];
      
      final farmsJson = jsonDecode(farmsString) as List<dynamic>;
      return farmsJson
          .map((json) => Farm.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // 에러 발생 시 빈 리스트 반환
      return [];
    }
  }

  /// 선택된 농장 ID 저장
  static Future<void> saveSelectedFarmId(String? farmId) async {
    final prefs = await _prefs;
    if (farmId != null) {
      await prefs.setString(_selectedFarmIdKey, farmId);
    } else {
      await prefs.remove(_selectedFarmIdKey);
    }
  }

  /// 선택된 농장 ID 로드
  static Future<String?> loadSelectedFarmId() async {
    final prefs = await _prefs;
    return prefs.getString(_selectedFarmIdKey);
  }

  // ==== 통계 데이터 관리 ====

  /// 통계 데이터 저장
  static Future<void> saveStatistics(List<DailyStats> stats) async {
    final prefs = await _prefs;
    final statsJson = stats.map((stat) => stat.toJson()).toList();
    await prefs.setString(_statisticsKey, jsonEncode(statsJson));
  }

  /// 통계 데이터 로드
  static Future<List<DailyStats>> loadStatistics() async {
    try {
      final prefs = await _prefs;
      final statsString = prefs.getString(_statisticsKey);
      
      if (statsString == null) return [];
      
      final statsJson = jsonDecode(statsString) as List<dynamic>;
      return statsJson
          .map((json) => DailyStats.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // 에러 발생 시 빈 리스트 반환
      return [];
    }
  }

  // ==== 타이머 설정 관리 ====

  /// 타이머 설정 저장
  static Future<void> saveTimerSettings({
    required int focusMinutes,
    required int shortBreakMinutes,
    required int longBreakMinutes,
    required int roundsUntilLongBreak,
    required bool autoStartNext,
  }) async {
    final prefs = await _prefs;
    final settings = {
      'focusMinutes': focusMinutes,
      'shortBreakMinutes': shortBreakMinutes,
      'longBreakMinutes': longBreakMinutes,
      'roundsUntilLongBreak': roundsUntilLongBreak,
      'autoStartNext': autoStartNext,
    };
    await prefs.setString(_timerSettingsKey, jsonEncode(settings));
  }

  /// 타이머 설정 로드
  static Future<Map<String, dynamic>?> loadTimerSettings() async {
    try {
      final prefs = await _prefs;
      final settingsString = prefs.getString(_timerSettingsKey);
      
      if (settingsString == null) return null;
      
      return jsonDecode(settingsString) as Map<String, dynamic>;
    } catch (e) {
      // 에러 발생 시 null 반환
      return null;
    }
  }

  // ==== 기타 설정 관리 ====

  /// 사운드 설정 저장
  static Future<void> saveSoundEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool('sound_enabled', enabled);
  }

  /// 사운드 설정 로드
  static Future<bool> loadSoundEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool('sound_enabled') ?? true;
  }

  /// 진동 설정 저장
  static Future<void> saveVibrationEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool('vibration_enabled', enabled);
  }

  /// 진동 설정 로드
  static Future<bool> loadVibrationEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool('vibration_enabled') ?? true;
  }

  /// 알림 설정 저장
  static Future<void> saveNotificationEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool('notification_enabled', enabled);
  }

  /// 알림 설정 로드
  static Future<bool> loadNotificationEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool('notification_enabled') ?? false;
  }

  /// 개발자 모드 설정 저장
  static Future<void> saveDeveloperModeEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool('developer_mode_enabled', enabled);
  }

  /// 개발자 모드 설정 로드
  static Future<bool> loadDeveloperModeEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool('developer_mode_enabled') ?? false;
  }

  // ==== 데이터 관리 ====

  /// 모든 데이터 삭제 (앱 리셋)
  static Future<void> clearAllData() async {
    final prefs = await _prefs;
    await prefs.clear();
  }

  /// 특정 키의 데이터 삭제
  static Future<void> removeData(String key) async {
    final prefs = await _prefs;
    await prefs.remove(key);
  }

  /// 저장된 데이터 크기 계산 (디버그용)
  static Future<int> getDataSize() async {
    final prefs = await _prefs;
    final keys = prefs.getKeys();
    int totalSize = 0;
    
    for (String key in keys) {
      final value = prefs.get(key);
      if (value is String) {
        totalSize += value.length;
      }
    }
    
    return totalSize;
  }

  /// 저장된 모든 키 목록 가져오기 (디버그용)
  static Future<Set<String>> getAllKeys() async {
    final prefs = await _prefs;
    return prefs.getKeys();
  }
}