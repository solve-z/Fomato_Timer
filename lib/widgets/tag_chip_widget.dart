import 'package:flutter/material.dart';
import '../models/tag.dart';

/// 공통 태그 칩 위젯
/// 모든 곳에서 일관된 태그 스타일을 제공합니다.
class TagChipWidget extends StatelessWidget {
  final Tag tag;
  final double chipHeight;
  final bool showDeleteButton;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TagChipWidget({
    super.key,
    required this.tag,
    this.chipHeight = 24.0,
    this.showDeleteButton = false,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: chipHeight,
        decoration: BoxDecoration(
          color: Color(int.parse(tag.color.substring(1, 7), radix: 16) + 0xFF000000),
          borderRadius: BorderRadius.circular(chipHeight / 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(left: chipHeight * 0.5),
              child: Text(
                tag.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: chipHeight * 0.43,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showDeleteButton && onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  margin: EdgeInsets.only(left: 4, right: chipHeight * 0.3),
                  child: Icon(
                    Icons.close,
                    size: chipHeight * 0.5,
                    color: Colors.white,
                  ),
                ),
              )
            else
              SizedBox(width: chipHeight * 0.5),
          ],
        ),
      ),
    );
  }
}

/// 태그 개수 표시 칩
class TagCountChipWidget extends StatelessWidget {
  final int count;
  final double chipHeight;
  final VoidCallback? onTap;

  const TagCountChipWidget({
    super.key,
    required this.count,
    this.chipHeight = 24.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: chipHeight,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(chipHeight / 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: chipHeight * 0.4),
              child: Text(
                '+$count',
                style: TextStyle(
                  fontSize: chipHeight * 0.43,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}