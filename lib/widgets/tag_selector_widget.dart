import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tag_provider.dart';
import '../models/tag.dart';
import 'tag_chip_widget.dart';

class TagSelectorWidget extends ConsumerStatefulWidget {
  final List<String> selectedTagIds;
  final Function(List<String>) onTagsChanged;
  final String? title;
  final bool allowQuickAdd;

  const TagSelectorWidget({
    super.key,
    required this.selectedTagIds,
    required this.onTagsChanged,
    this.title,
    this.allowQuickAdd = true,
  });

  @override
  ConsumerState<TagSelectorWidget> createState() => _TagSelectorWidgetState();
}

class _TagSelectorWidgetState extends ConsumerState<TagSelectorWidget> {
  final TextEditingController _quickAddController = TextEditingController();
  bool _isEditMode = false;

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTags = ref.watch(tagProvider);
    final selectedTags = ref.watch(tagsByIdsProvider(widget.selectedTagIds));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Row(
            children: [
              Text(
                widget.title!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // 태그 관리 아이콘들
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 태그 선택/변경 버튼
                  IconButton(
                    onPressed: () => _showTagSelectionDialog(context, allTags),
                    icon: const Icon(Icons.local_offer, size: 18),
                    tooltip: selectedTags.isEmpty ? '태그 선택' : '태그 변경',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      padding: const EdgeInsets.all(6),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 편집 모드 토글 버튼
                  if (selectedTags.isNotEmpty)
                    IconButton(
                      onPressed: () => setState(() => _isEditMode = !_isEditMode),
                      icon: Icon(_isEditMode ? Icons.check : Icons.edit, size: 18),
                      tooltip: _isEditMode ? '편집 완료' : '편집 모드',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      style: IconButton.styleFrom(
                        backgroundColor: _isEditMode ? Colors.green.shade100 : Colors.grey.shade100,
                        foregroundColor: _isEditMode ? Colors.green : Colors.grey.shade700,
                        padding: const EdgeInsets.all(6),
                      ),
                    ),
                  if (selectedTags.isNotEmpty) const SizedBox(width: 4),
                  // 빠른 추가 버튼
                  if (widget.allowQuickAdd)
                    IconButton(
                      onPressed: () => _showQuickAddDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      tooltip: '새 태그 추가',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue.shade100,
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.all(6),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        // 선택된 태그 표시
        if (selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: selectedTags.map((tag) {
              return TagChipWidget(
                tag: tag,
                chipHeight: 28.0,
                showDeleteButton: _isEditMode,
                onDelete: () {
                  final newTagIds = List<String>.from(widget.selectedTagIds);
                  newTagIds.remove(tag.id);
                  widget.onTagsChanged(newTagIds);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }


  void _showTagSelectionDialog(BuildContext context, List<Tag> allTags) {
    List<String> tempSelectedTagIds = List.from(widget.selectedTagIds);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('태그 선택'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: allTags.isEmpty
                ? const Center(
                    child: Text('사용 가능한 태그가 없습니다.\n설정에서 태그를 추가해주세요.'),
                  )
                : ListView.builder(
                    itemCount: allTags.length,
                    itemBuilder: (context, index) {
                      final tag = allTags[index];
                      final isSelected = tempSelectedTagIds.contains(tag.id);
                      const chipHeight = 24.0;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: InkWell(
                          onTap: () {
                            setDialogState(() {
                              if (isSelected) {
                                tempSelectedTagIds.remove(tag.id);
                              } else {
                                tempSelectedTagIds.add(tag.id);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // 태그 칩
                                TagChipWidget(
                                  tag: tag,
                                  chipHeight: chipHeight,
                                ),
                                const Spacer(),
                                // 체크박스
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setDialogState(() {
                                      if (value == true) {
                                        tempSelectedTagIds.add(tag.id);
                                      } else {
                                        tempSelectedTagIds.remove(tag.id);
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onTagsChanged(tempSelectedTagIds);
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickAddDialog(BuildContext context) {
    _quickAddController.clear();
    Color selectedColor = Colors.blue;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('새 태그 추가'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _quickAddController,
                  decoration: const InputDecoration(
                    labelText: '태그 이름',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '태그 이름을 입력해주세요';
                    }
                    if (value.trim().length > 20) {
                      return '태그 이름은 20자를 초과할 수 없습니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('색상:'),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _getColorOptions().map((color) {
                    final isSelected = selectedColor.value == color.value;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color,
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final tagName = _quickAddController.text.trim();
                    final colorHex = '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';
                    
                    final newTag = Tag(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: tagName,
                      color: colorHex,
                      createdAt: DateTime.now(),
                    );
                    
                    await ref.read(tagProvider.notifier).addTag(newTag);
                    
                    // 새로 추가된 태그를 선택 목록에 추가
                    final newTagIds = List<String>.from(widget.selectedTagIds);
                    newTagIds.add(newTag.id);
                    widget.onTagsChanged(newTagIds);

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('태그가 추가되고 선택되었습니다'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getColorOptions() {
    return [
      const Color(0xFF4CAF50), // 녹색
      const Color(0xFF2196F3), // 파란색
      const Color(0xFFFF9800), // 주황색
      const Color(0xFFE91E63), // 분홍색
      const Color(0xFF9C27B0), // 보라색
      const Color(0xFF607D8B), // 회색
      const Color(0xFFF44336), // 빨간색
      const Color(0xFFFFEB3B), // 노란색
    ];
  }
}