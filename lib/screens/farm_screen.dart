import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/farm_provider.dart';
import '../models/farm.dart';

/// 농장 관리 화면
/// 
/// 농장(프로젝트) 목록을 관리하고 시각화합니다.
/// - 농장 생성/수정/삭제
/// - 잔디형 토마토 수확 현황 표시
/// - 농장별 통계 요약
class FarmScreen extends ConsumerWidget {
  const FarmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmList = ref.watch(farmListProvider);
    final selectedFarm = ref.watch(selectedFarmProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 농장'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddFarmDialog(context, ref),
          ),
        ],
      ),
      body: farmList.isEmpty 
          ? _buildEmptyState(context, ref)
          : _buildFarmList(context, ref, farmList, selectedFarm),
    );
  }

  /// 농장이 없을 때 빈 상태 표시
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grass,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 농장이 없습니다',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 농장을 만들어 보세요!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddFarmDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('농장 만들기'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 농장 목록 표시
  Widget _buildFarmList(BuildContext context, WidgetRef ref, List<Farm> farmList, Farm? selectedFarm) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: farmList.length,
      itemBuilder: (context, index) {
        final farm = farmList[index];
        final isSelected = selectedFarm?.id == farm.id;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 4 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected 
                ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              ref.read(selectedFarmProvider.notifier).state = farm;
            },
            onLongPress: () => _showFarmOptions(context, ref, farm),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 농장 헤더
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Color(int.parse(farm.color.substring(1), radix: 16) + 0xFF000000),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          farm.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 토마토 수확 현황
                  Row(
                    children: [
                      const Icon(Icons.eco, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        '토마토 ${farm.tomatoCount}개 수확',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${farm.tomatoCount * 25}분 집중',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 잔디형 시각화 (간단한 버전)
                  _buildTomatoVisualization(farm.tomatoCount),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 토마토 수확 시각화 (잔디형)
  Widget _buildTomatoVisualization(int tomatoCount) {
    const int maxItemsPerRow = 10;
    const int maxRows = 3;
    const double itemSize = 12;
    const double spacing = 3;

    final int totalItems = (tomatoCount > maxItemsPerRow * maxRows) 
        ? maxItemsPerRow * maxRows 
        : tomatoCount;

    return SizedBox(
      height: (itemSize + spacing) * maxRows - spacing,
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(maxItemsPerRow * maxRows, (index) {
          final bool isHarvested = index < totalItems;
          return Container(
            width: itemSize,
            height: itemSize,
            decoration: BoxDecoration(
              color: isHarvested 
                  ? Colors.green.shade400 
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  /// 농장 추가 다이얼로그
  void _showAddFarmDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedColor = '#4CAF50';

    final colors = [
      '#4CAF50', '#2196F3', '#FF9800', '#9C27B0',
      '#F44336', '#009688', '#FF5722', '#607D8B',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('새 농장 만들기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '농장 이름',
                  hintText: '예: Flutter 공부',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text('농장 색상:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: colors.map((color) {
                  final isSelected = selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(int.parse(color.substring(1), radix: 16) + 0xFF000000),
                        shape: BoxShape.circle,
                        border: isSelected 
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                      ),
                      child: isSelected 
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  ref.read(farmListProvider.notifier).addFarm(
                    nameController.text.trim(),
                    selectedColor,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('만들기'),
            ),
          ],
        ),
      ),
    );
  }

  /// 농장 옵션 메뉴 (수정/삭제)
  void _showFarmOptions(BuildContext context, WidgetRef ref, Farm farm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('농장 수정'),
              onTap: () {
                Navigator.of(context).pop();
                _showEditFarmDialog(context, ref, farm);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('농장 삭제', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pop();
                _showDeleteConfirmDialog(context, ref, farm);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 농장 수정 다이얼로그
  void _showEditFarmDialog(BuildContext context, WidgetRef ref, Farm farm) {
    // 농장 추가와 유사한 로직 (생략 - 실제로는 구현 필요)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('농장 수정 기능은 추후 구현 예정입니다')),
    );
  }

  /// 농장 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, Farm farm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('농장 삭제'),
        content: Text('${farm.name} 농장을 삭제하시겠습니까?\n수확한 토마토 데이터도 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(farmListProvider.notifier).deleteFarm(farm.id);
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${farm.name} 농장이 삭제되었습니다')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}