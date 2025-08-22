import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/farm.dart';
import '../services/storage_service.dart';

/// 농장 목록 상태 관리 클래스
class FarmListNotifier extends StateNotifier<List<Farm>> {
  FarmListNotifier() : super([]) {
    _loadInitialFarms();
  }

  /// 초기 농장 데이터 로드 (SharedPreferences에서 로드)
  void _loadInitialFarms() async {
    try {
      final savedFarms = await StorageService.loadFarms();
      if (savedFarms.isNotEmpty) {
        state = savedFarms;
      } else {
        // 저장된 농장이 없으면 기본 농장 생성
        final now = DateTime.now();
        final defaultFarms = [
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
        state = defaultFarms;
        await _saveFarms();
      }
    } catch (e) {
      // 에러 발생 시 빈 리스트
      state = [];
    }
  }

  /// 농장 목록을 저장소에 저장
  Future<void> _saveFarms() async {
    await StorageService.saveFarms(state);
  }

  /// 새 농장 추가
  void addFarm(String name, String color) async {
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
    await _saveFarms();
  }

  /// 농장 수정
  void updateFarm(String farmId, {String? name, String? color}) async {
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
    await _saveFarms();
  }

  /// 농장 삭제
  void deleteFarm(String farmId) async {
    state = state.where((farm) => farm.id != farmId).toList();
    await _saveFarms();
  }

  /// 토마토 수확 (집중 시간 완료 시)
  void harvestTomato(String farmId) async {
    state = state.map((farm) {
      if (farm.id == farmId) {
        return farm.addTomato();
      }
      return farm;
    }).toList();
    await _saveFarms();
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

/// 선택된 농장 관리 클래스
class SelectedFarmNotifier extends StateNotifier<Farm?> {
  SelectedFarmNotifier(this.ref) : super(null) {
    _loadSelectedFarm();
  }

  final Ref ref;

  /// 선택된 농장 로드
  void _loadSelectedFarm() async {
    try {
      // 농장 목록이 로드될 때까지 잠시 대기
      await Future.delayed(const Duration(milliseconds: 50));
      
      final selectedFarmId = await StorageService.loadSelectedFarmId();
      final farmList = ref.read(farmListProvider);
      
      if (selectedFarmId != null && farmList.isNotEmpty) {
        final selectedFarm = farmList.where((farm) => farm.id == selectedFarmId).firstOrNull;
        if (selectedFarm != null) {
          state = selectedFarm;
          return;
        }
      }
      
      // 저장된 농장이 없거나 유효하지 않으면 첫 번째 농장 선택
      if (farmList.isNotEmpty) {
        state = farmList.first;
        await _saveSelectedFarm(farmList.first.id);
      } else {
        // 농장 목록이 아직 비어있으면 좀 더 대기 후 재시도
        Future.delayed(const Duration(milliseconds: 200), () {
          final updatedFarmList = ref.read(farmListProvider);
          if (updatedFarmList.isNotEmpty) {
            state = updatedFarmList.first;
            _saveSelectedFarm(updatedFarmList.first.id);
          }
        });
      }
    } catch (e) {
      // 에러 발생 시 나중에 재시도
      Future.delayed(const Duration(milliseconds: 200), () {
        final farmList = ref.read(farmListProvider);
        if (farmList.isNotEmpty) {
          state = farmList.first;
        }
      });
    }
  }

  /// 농장 선택
  void selectFarm(Farm? farm) async {
    state = farm;
    await _saveSelectedFarm(farm?.id);
  }

  /// 선택된 농장 ID 저장
  Future<void> _saveSelectedFarm(String? farmId) async {
    await StorageService.saveSelectedFarmId(farmId);
  }

  /// 농장 목록 변경 시 선택된 농장 업데이트
  void updateFromFarmList(List<Farm> farmList) {
    if (state != null) {
      // 현재 선택된 농장이 여전히 존재하는지 확인
      final currentFarm = farmList.where((farm) => farm.id == state!.id).firstOrNull;
      if (currentFarm != null) {
        // 농장 데이터 업데이트 (토마토 수확 등)
        state = currentFarm;
      } else if (farmList.isNotEmpty) {
        // 선택된 농장이 삭제되었으면 첫 번째 농장 선택
        selectFarm(farmList.first);
      } else {
        // 농장이 모두 삭제되었으면 null
        selectFarm(null);
      }
    } else if (farmList.isNotEmpty) {
      // 선택된 농장이 없으면 첫 번째 농장 선택
      selectFarm(farmList.first);
    }
  }
}

/// 선택된 농장 Provider
final selectedFarmProvider = StateNotifierProvider<SelectedFarmNotifier, Farm?>((ref) {
  final notifier = SelectedFarmNotifier(ref);
  
  // 농장 목록 변경 시 선택된 농장 업데이트
  ref.listen<List<Farm>>(farmListProvider, (previous, next) {
    notifier.updateFromFarmList(next);
  });
  
  return notifier;
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