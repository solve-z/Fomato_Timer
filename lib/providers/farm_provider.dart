import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/farm.dart';

/// 농장 목록 상태 관리 클래스
class FarmListNotifier extends StateNotifier<List<Farm>> {
  FarmListNotifier() : super([]) {
    _loadInitialFarms();
  }

  /// 초기 농장 데이터 로드 (나중에 SharedPreferences에서 로드)
  void _loadInitialFarms() {
    final now = DateTime.now();
    state = [
      Farm(
        id: 'farm-1',
        name: 'Flutter 공부',
        color: '#4CAF50',
        tomatoCount: 0,
        createdAt: now,
        updatedAt: now,
      ),
      Farm(
        id: 'farm-2',
        name: '운동하기',
        color: '#2196F3',
        tomatoCount: 0,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// 새 농장 추가
  void addFarm(String name, String color) {
    final now = DateTime.now();
    final newFarm = Farm(
      id: 'farm-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      color: color,
      tomatoCount: 0,
      createdAt: now,
      updatedAt: now,
    );
    
    state = [...state, newFarm];
  }

  /// 농장 수정
  void updateFarm(String farmId, {String? name, String? color}) {
    state = state.map((farm) {
      if (farm.id == farmId) {
        return farm.copyWith(
          name: name,
          color: color,
          updatedAt: DateTime.now(),
        );
      }
      return farm;
    }).toList();
  }

  /// 농장 삭제
  void deleteFarm(String farmId) {
    state = state.where((farm) => farm.id != farmId).toList();
  }

  /// 토마토 수확 (25분 집중 완료 시)
  void harvestTomato(String farmId) {
    state = state.map((farm) {
      if (farm.id == farmId) {
        return farm.addTomato();
      }
      return farm;
    }).toList();
  }

  /// 특정 농장 찾기
  Farm? findFarmById(String farmId) {
    try {
      return state.firstWhere((farm) => farm.id == farmId);
    } catch (e) {
      return null;
    }
  }
}

/// 농장 목록 Provider
final farmListProvider = StateNotifierProvider<FarmListNotifier, List<Farm>>((ref) {
  return FarmListNotifier();
});

/// 선택된 농장 Provider
final selectedFarmProvider = StateProvider<Farm?>((ref) {
  final farmList = ref.watch(farmListProvider);
  
  // 농장이 있으면 첫 번째 농장을 기본 선택
  if (farmList.isNotEmpty) {
    return farmList.first;
  }
  return null;
});

/// 선택된 농장 ID Provider (편의를 위한)
final selectedFarmIdProvider = Provider<String?>((ref) {
  final selectedFarm = ref.watch(selectedFarmProvider);
  return selectedFarm?.id;
});

/// 농장별 토마토 개수 Provider
final farmTomatoCountProvider = Provider.family<int, String>((ref, farmId) {
  final farmList = ref.watch(farmListProvider);
  final farm = farmList.where((farm) => farm.id == farmId).firstOrNull;
  return farm?.tomatoCount ?? 0;
});

/// 전체 토마토 개수 Provider
final totalTomatoCountProvider = Provider<int>((ref) {
  final farmList = ref.watch(farmListProvider);
  return farmList.fold(0, (total, farm) => total + farm.tomatoCount);
});