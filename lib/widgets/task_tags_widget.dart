import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tag_provider.dart';
import '../models/tag.dart';
import 'tag_chip_widget.dart';

class TaskTagsWidget extends ConsumerWidget {
  final List<String> tagIds;
  final bool showCount;
  final int maxTags;
  final double chipHeight;

  const TaskTagsWidget({
    super.key,
    required this.tagIds,
    this.showCount = true,
    this.maxTags = 3,
    this.chipHeight = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tagIds.isEmpty) return const SizedBox.shrink();

    final tags = ref.watch(tagsByIdsProvider(tagIds));
    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        // 표시할 태그들
        ...tags.take(maxTags).map((tag) => TagChipWidget(
          tag: tag,
          chipHeight: chipHeight.toDouble(),
        )),
        // 더 많은 태그가 있는 경우 개수 표시
        if (showCount && tags.length > maxTags)
          TagCountChipWidget(
            count: tags.length - maxTags,
            chipHeight: chipHeight.toDouble(),
          ),
      ],
    );
  }

}