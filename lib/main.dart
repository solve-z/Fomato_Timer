import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'widgets/bottom_navigation.dart';
import 'services/notification_service.dart';

/// Fomato 앱의 진입점
/// 
/// 토마토 농장형 뽀모도로 타이머 앱입니다.
/// 25분 집중하여 토마토 1개를 수확하세요!
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 알림 서비스 초기화
  await NotificationService().initialize();
  
  runApp(const ProviderScope(child: FomatoApp()));
}

/// 메인 앱 위젯
class FomatoApp extends StatelessWidget {
  const FomatoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainBottomNavigation(),
    );
  }
}
