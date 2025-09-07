import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/tag.dart';
// 순환 import 방지를 위해 필요할 때만 import
// ignore: unused_import
import 'task_provider.dart';

class TagNotifier extends StateNotifier<List<Tag>> {
  TagNotifier() : super([]) {
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tagListJson = prefs.getStringList('tags') ?? [];
      
      if (tagListJson.isEmpty) {
        // 기본 태그 로드
        final defaultTags = Tag.getDefaultTags();
        state = defaultTags;
        await _saveTags();
      } else {
        state = tagListJson
            .map((tagJson) => Tag.fromJson(json.decode(tagJson)))
            .toList();
      }
    } catch (e) {
      // 에러 발생 시 기본 태그로 초기화
      state = Tag.getDefaultTags();
    }
  }

  Future<void> _saveTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tagListJson = state
          .map((tag) => json.encode(tag.toJson()))
          .toList();
      await prefs.setStringList('tags', tagListJson);
    } catch (e) {
      // 저장 실패 시 에러 처리 (필요에 따라 구현)
      print('태그 저장 실패: $e');
    }
  }

  /// 새 태그 추가
  Future<void> addTag(Tag tag) async {
    // 중복 이름 검사
    if (state.any((existingTag) => existingTag.name == tag.name)) {
      throw Exception('이미 존재하는 태그 이름입니다.');
    }

    state = [...state, tag];
    await _saveTags();
  }

  /// 태그 업데이트
  Future<void> updateTag(String tagId, Tag updatedTag) async {
    // 다른 태그와 이름 중복 검사 (자기 자신 제외)
    if (state.any((existingTag) => 
        existingTag.id != tagId && existingTag.name == updatedTag.name)) {
      throw Exception('이미 존재하는 태그 이름입니다.');
    }

    state = state.map((tag) => 
        tag.id == tagId ? updatedTag : tag).toList();
    await _saveTags();
  }

  /// 태그 삭제 (관련 할일에서도 태그 제거)
  Future<void> deleteTag(String tagId, WidgetRef? ref) async {
    state = state.where((tag) => tag.id != tagId).toList();
    await _saveTags();
    
    // 관련 할일에서도 해당 태그 제거
    if (ref != null) {
      ref.read(taskListProvider.notifier).removeTagFromAllTasks(tagId);
    }
  }

  /// ID로 태그 찾기
  Tag? getTagById(String tagId) {
    try {
      return state.firstWhere((tag) => tag.id == tagId);
    } catch (e) {
      return null;
    }
  }

  /// 여러 ID로 태그 목록 찾기
  List<Tag> getTagsByIds(List<String> tagIds) {
    return state.where((tag) => tagIds.contains(tag.id)).toList();
  }

  /// 태그 이름으로 검색
  List<Tag> searchTags(String query) {
    if (query.isEmpty) return state;
    return state.where((tag) => 
        tag.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  /// 기본 태그로 초기화
  Future<void> resetToDefaults() async {
    state = Tag.getDefaultTags();
    await _saveTags();
  }
}

/// 태그 관리 Provider
final tagProvider = StateNotifierProvider<TagNotifier, List<Tag>>((ref) {
  return TagNotifier();
});

/// 특정 태그 조회 Provider
final tagByIdProvider = Provider.family<Tag?, String>((ref, tagId) {
  final tags = ref.watch(tagProvider);
  try {
    return tags.firstWhere((tag) => tag.id == tagId);
  } catch (e) {
    return null;
  }
});

/// 여러 태그 조회 Provider
final tagsByIdsProvider = Provider.family<List<Tag>, List<String>>((ref, tagIds) {
  final tags = ref.watch(tagProvider);
  return tags.where((tag) => tagIds.contains(tag.id)).toList();
});

/// 태그 검색 Provider
final searchTagsProvider = Provider.family<List<Tag>, String>((ref, query) {
  final tags = ref.watch(tagProvider);
  if (query.isEmpty) return tags;
  return tags.where((tag) => 
      tag.name.toLowerCase().contains(query.toLowerCase())).toList();
});