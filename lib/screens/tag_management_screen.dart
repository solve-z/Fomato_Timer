import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tag_provider.dart';
import '../models/tag.dart';

class TagManagementScreen extends ConsumerStatefulWidget {
  const TagManagementScreen({super.key});

  @override
  ConsumerState<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends ConsumerState<TagManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(searchTagsProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('태그 관리'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTagDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 필드
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '태그 검색...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // 태그 목록
          Expanded(
            child: tags.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_offer,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? '태그가 없습니다' : '검색 결과가 없습니다',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_searchQuery.isEmpty)
                          ElevatedButton.icon(
                            onPressed: () => _showAddTagDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('첫 번째 태그 추가'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: tags.length,
                    itemBuilder: (context, index) {
                      final tag = tags[index];
                      return _buildTagCard(context, tag);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagCard(BuildContext context, Tag tag) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(int.parse(tag.color.substring(1, 7), radix: 16) + 0xFF000000),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.local_offer,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          tag.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '생성일: ${_formatDate(tag.createdAt)}',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditTagDialog(context, tag);
                break;
              case 'delete':
                _showDeleteTagDialog(context, tag);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('수정'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('삭제', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTagDialog(BuildContext context) {
    _showTagDialog(context, null);
  }

  void _showEditTagDialog(BuildContext context, Tag tag) {
    _showTagDialog(context, tag);
  }

  void _showTagDialog(BuildContext context, Tag? existingTag) {
    final isEditing = existingTag != null;
    final nameController = TextEditingController(text: existingTag?.name ?? '');
    Color selectedColor = existingTag != null 
        ? Color(int.parse(existingTag.color.substring(1, 7), radix: 16) + 0xFF000000)
        : Colors.blue;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? '태그 수정' : '새 태그 추가'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
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
                  child: Text('색상 선택:'),
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
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
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
                    final tagName = nameController.text.trim();
                    final colorHex = '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';
                    
                    if (isEditing) {
                      final updatedTag = existingTag.copyWith(
                        name: tagName,
                        color: colorHex,
                      );
                      await ref.read(tagProvider.notifier).updateTag(existingTag.id, updatedTag);
                    } else {
                      final newTag = Tag(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: tagName,
                        color: colorHex,
                        createdAt: DateTime.now(),
                      );
                      await ref.read(tagProvider.notifier).addTag(newTag);
                    }

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? '태그가 수정되었습니다' : '태그가 추가되었습니다'),
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
              child: Text(isEditing ? '수정' : '추가'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteTagDialog(BuildContext context, Tag tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.red, size: 48),
        title: const Text('태그 삭제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('태그 "${tag.name}"을 삭제하시겠습니까?'),
            const SizedBox(height: 8),
            const Text(
              '이 태그가 사용된 모든 할일에서 제거됩니다.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(tagProvider.notifier).deleteTag(tag.id, ref);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('태그가 삭제되었습니다. 관련된 할일에서도 제거되었습니다.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('태그 삭제 중 오류가 발생했습니다: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
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
      const Color(0xFF009688), // 청록색
      const Color(0xFF795548), // 갈색
      const Color(0xFF3F51B5), // 남색
      const Color(0xFFFF5722), // 진한 주황색
    ];
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}