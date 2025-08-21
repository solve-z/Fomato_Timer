import 'package:flutter/material.dart';
import '../screens/timer_screen.dart';
import '../screens/farm_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/settings_screen.dart';

/// 하단 네비게이션 바 메인 위젯
/// 
/// 4개 탭 간의 전환을 관리합니다:
/// - 타이머: 25분 집중 타이머
/// - 농장: 농장 관리 및 시각화
/// - 통계: 수확 통계 및 캘린더
/// - 설정: 앱 설정
class MainBottomNavigation extends StatefulWidget {
  const MainBottomNavigation({super.key});

  @override
  State<MainBottomNavigation> createState() => _MainBottomNavigationState();
}

class _MainBottomNavigationState extends State<MainBottomNavigation> {
  int _currentIndex = 0;

  // 각 탭에 해당하는 화면들
  final List<Widget> _screens = [
    const TimerScreen(),
    const FarmScreen(),
    const StatisticsScreen(),
    const SettingsScreen(),
  ];

  // 각 탭의 네비게이션 정보
  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.timer),
      activeIcon: Icon(Icons.timer),
      label: '타이머',
      tooltip: '뽀모도로 타이머',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.grass),
      activeIcon: Icon(Icons.grass),
      label: '농장',
      tooltip: '내 농장 관리',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.bar_chart),
      activeIcon: Icon(Icons.bar_chart),
      label: '통계',
      tooltip: '수확 통계',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      activeIcon: Icon(Icons.settings),
      label: '설정',
      tooltip: '앱 설정',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        items: _navItems,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 8,
        backgroundColor: Colors.white,
      ),
    );
  }

  /// 탭 선택 시 호출되는 함수
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}