import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 로컬 알림 서비스
/// 
/// flutter_local_notifications 패키지를 사용하여
/// 타이머 완료, 휴식 완료 등의 알림을 관리합니다.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// 알림 서비스 초기화
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Android 설정
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher', // 기본 앱 아이콘 사용
      );

      // iOS 설정
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // 수동으로 권한 요청
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      // 전체 초기화 설정
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // 알림 플러그인 초기화
      final bool? result = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = result ?? false;
      
      if (kDebugMode) {
        print('NotificationService initialized: $_isInitialized');
      }
      
      return _isInitialized;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize NotificationService: $e');
      }
      return false;
    }
  }

  /// 알림 권한 요청 (Android 13+ 및 iOS)
  Future<bool> requestPermissions() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Android 권한 요청
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      bool androidGranted = true;
      if (androidImplementation != null) {
        androidGranted = await androidImplementation.requestNotificationsPermission() ?? false;
      }

      // iOS 권한 요청
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      
      bool iosGranted = true;
      if (iosImplementation != null) {
        iosGranted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ?? false;
      }

      final bool granted = androidGranted && iosGranted;
      
      if (kDebugMode) {
        print('Notification permissions granted: $granted');
      }
      
      return granted;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to request notification permissions: $e');
      }
      return false;
    }
  }

  /// 알림 권한 상태 확인
  Future<bool> arePermissionsGranted() async {
    if (!_isInitialized) return false;

    try {
      // Android 권한 확인
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final bool? granted = await androidImplementation.areNotificationsEnabled();
        return granted ?? false;
      }

      // iOS는 별도 확인 방법이 제한적이므로 true 반환
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to check notification permissions: $e');
      }
      return false;
    }
  }

  /// 집중 시간 완료 알림
  Future<void> showFocusCompleteNotification({
    required String farmName,
    required int tomatoCount,
  }) async {
    if (!_isInitialized) return;

    const int notificationId = 1001;
    const String channelId = 'focus_complete';
    const String channelName = '집중 완료 알림';
    const String channelDescription = '25분 집중 완료 시 표시되는 알림';

    await _showNotification(
      id: notificationId,
      title: '🍅 집중 완료!',
      body: '$farmName에서 토마토 1개를 수확했습니다! (총 ${tomatoCount + 1}개)',
      channelId: channelId,
      channelName: channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
  }

  /// 휴식 시간 완료 알림
  Future<void> showBreakCompleteNotification({
    required bool isLongBreak,
    required String nextMode,
  }) async {
    if (!_isInitialized) return;

    const int notificationId = 1002;
    const String channelId = 'break_complete';
    const String channelName = '휴식 완료 알림';
    const String channelDescription = '휴식 시간 완료 시 표시되는 알림';

    final String breakType = isLongBreak ? '긴 휴식' : '짧은 휴식';
    
    await _showNotification(
      id: notificationId,
      title: '⏰ $breakType 완료!',
      body: '이제 $nextMode 시간입니다. 준비되셨나요?',
      channelId: channelId,
      channelName: channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
  }

  /// 타이머 실행 중 알림 (집중시간)
  Future<void> showTimerRunningNotification({
    required String mode,
    required String timeLeft,
    required String farmName,
  }) async {
    if (!_isInitialized) return;

    const int notificationId = 1003;
    const String channelId = 'timer_running';
    const String channelName = '타이머 실행 중';
    const String channelDescription = '타이머가 백그라운드에서 실행 중임을 알리는 알림';

    await _showNotification(
      id: notificationId,
      title: farmName.isNotEmpty ? '🕐 $mode 중 - $farmName' : '🕐 $mode 중',
      body: timeLeft,
      channelId: channelId,
      channelName: channelName,
      channelDescription: channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // 지속적 알림
      autoCancel: false, // 탭해도 자동 삭제 안됨
    );
  }

  /// 휴식시간 실행 중 알림
  Future<void> showBreakRunningNotification({
    required String mode,
    required String timeLeft,
  }) async {
    if (!_isInitialized) return;

    const int notificationId = 1003; // 동일한 ID 사용 (기존 알림 대체)
    const String channelId = 'timer_running';
    const String channelName = '타이머 실행 중';
    const String channelDescription = '타이머가 백그라운드에서 실행 중임을 알리는 알림';

    // 휴식시간별 이모지
    final String emoji = mode.contains('긴') ? '😴' : '😌';
    
    await _showNotification(
      id: notificationId,
      title: '$emoji $mode 중',
      body: timeLeft,
      channelId: channelId,
      channelName: channelName,
      channelDescription: channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // 지속적 알림
      autoCancel: false, // 탭해도 자동 삭제 안됨
    );
  }

  /// 실행 중 타이머 알림 제거
  Future<void> cancelTimerRunningNotification() async {
    await _notifications.cancel(1003);
  }

  /// 모든 알림 제거
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// 특정 알림 제거
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// 내부 알림 표시 메서드
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String channelDescription,
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
    bool ongoing = false,
    bool autoCancel = true,
  }) async {
    try {
      // Android 알림 설정
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: importance,
        priority: priority,
        ongoing: ongoing,
        autoCancel: autoCancel,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: const Color(0xFF4CAF50), // 앱 Primary 색상
      );

      // iOS 알림 설정
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // 통합 알림 설정
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 알림 표시
      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
      );

      if (kDebugMode) {
        print('Notification shown: $title - $body');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to show notification: $e');
      }
    }
  }

  /// 알림 탭 이벤트 처리
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('Notification tapped: ${response.id} - ${response.payload}');
    }
    
    // TODO: 알림 탭 시 특정 화면으로 이동하는 로직 구현
    // 예: 타이머 화면으로 이동, 특정 농장 상세로 이동 등
  }

  /// 서비스 정리
  void dispose() {
    // 필요시 리소스 정리
  }
}