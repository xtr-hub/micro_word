import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/word.dart';
import '../services/word_storage.dart';
import '../services/word_list_storage.dart';
import '../models/word_list.dart';
import '../models/study_progress.dart';
import 'platform_storage.dart';

class DataConsistencyService {
  static DataConsistencyService? _instance;
  static DataConsistencyService get instance =>
      _instance ??= DataConsistencyService._();

  DataConsistencyService._();

  static const String _backupDir = 'backups';
  static const int _maxBackups = 5;

  Future<void> validateAndRepairData() async {
    try {
      await _validateWordData();
      await _validateWordListData();
      await _validateProgressData();
      await _createBackup();
    } catch (e) {
      debugPrint('数据验证和修复失败: $e');
    }
  }

  Future<void> _validateWordData() async {
    final words = await WordStorage.loadWords();
    final wordIds = <int>{};

    for (final word in words) {
      if (word.id <= 0) {
        debugPrint('发现无效单词ID: ${word.id}');
        continue;
      }

      if (wordIds.contains(word.id)) {
        debugPrint('发现重复单词ID: ${word.id}');
        continue;
      }

      wordIds.add(word.id);

      if (word.word.isEmpty) {
        debugPrint('发现空单词: ID=${word.id}');
      }

      if (word.meaning.isEmpty) {
        debugPrint('发现空释义: ID=${word.id}');
      }
    }

    if (words.length != wordIds.length) {
      debugPrint('单词数据存在重复或无效项，需要修复');
      await _repairWordData(words, wordIds.toList());
    }
  }

  Future<void> _repairWordData(List<Word> words, List<int> validIds) async {
    final validWords = words
        .where((word) => validIds.contains(word.id))
        .toList();
    await WordStorage.saveWords(validWords);
    debugPrint('单词数据修复完成');
  }

  Future<void> _validateWordListData() async {
    final wordLists = await WordListStorage.loadWordLists();
    final words = await WordStorage.loadWords();
    final wordIds = words.map((word) => word.id).toSet();

    for (final wordList in wordLists) {
      final validWordIds = <int>[];

      for (final wordId in wordList.wordIds) {
        if (wordIds.contains(wordId)) {
          validWordIds.add(wordId);
        } else {
          debugPrint('单词表 ${wordList.name} 中发现无效单词ID: $wordId');
        }
      }

      if (validWordIds.length != wordList.wordIds.length) {
        wordList.wordIds = validWordIds;
        debugPrint('单词表 ${wordList.name} 已修复');
      }
    }

    await WordListStorage.saveWordLists(wordLists);
    debugPrint('单词表数据验证完成');
  }

  Future<void> _validateProgressData() async {
    final progress = await StudyProgress.load();

    if (progress.totalWordsStudied < 0) {
      progress.totalWordsStudied = 0;
      debugPrint('修复无效的总学习单词数');
    }

    if (progress.masteredWords < 0) {
      progress.masteredWords = 0;
      debugPrint('修复无效的已掌握单词数');
    }

    if (progress.todayWordsStudied < 0) {
      progress.todayWordsStudied = 0;
      debugPrint('修复无效的今日学习单词数');
    }

    if (progress.consecutiveDays < 0) {
      progress.consecutiveDays = 0;
      debugPrint('修复无效的连续学习天数');
    }

    if (progress.totalStudyTime < 0) {
      progress.totalStudyTime = 0;
      debugPrint('修复无效的总学习时长');
    }

    if (progress.dailyGoal <= 0) {
      progress.dailyGoal = 20;
      debugPrint('修复无效的每日学习目标');
    }

    if (progress.dailyReviewGoal <= 0) {
      progress.dailyReviewGoal = 50;
      debugPrint('修复无效的每日复习目标');
    }

    await progress.save();
    debugPrint('学习进度数据验证完成');
  }

  Future<void> _createBackup() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupKey = 'backup_$timestamp';

      final backupData = {
        'words': await WordStorage.loadWords(),
        'wordLists': await WordListStorage.loadWordLists(),
        'progress': await StudyProgress.load(),
        'timestamp': timestamp,
      };

      final jsonString = json.encode(backupData);
      await PlatformStorage.saveData(backupKey, jsonString);

      await _cleanupOldBackups();
      debugPrint('备份创建成功: $backupKey');
    } catch (e) {
      debugPrint('创建备份失败: $e');
    }
  }

  Future<void> _cleanupOldBackups() async {
    try {
      final allKeys = await PlatformStorage.getAllKeys();
      final backupKeys = allKeys
          .where((key) => key.startsWith('backup_'))
          .toList();

      if (backupKeys.length <= _maxBackups) {
        return;
      }

      backupKeys.sort();
      final keysToDelete = backupKeys.take(backupKeys.length - _maxBackups);
      for (final key in keysToDelete) {
        await PlatformStorage.deleteData(key);
        debugPrint('删除旧备份: $key');
      }
    } catch (e) {
      debugPrint('清理旧备份失败: $e');
    }
  }

  Future<bool> restoreFromBackup(String backupFileName) async {
    try {
      final jsonString = await PlatformStorage.loadData(backupFileName);

      if (jsonString == null) {
        debugPrint('备份文件不存在: $backupFileName');
        return false;
      }

      final backupData = json.decode(jsonString) as Map<String, dynamic>;

      final words = (backupData['words'] as List)
          .map((json) => Word.fromJson(json))
          .toList();
      await WordStorage.saveWords(words);

      final wordLists = (backupData['wordLists'] as List)
          .map((json) => WordList.fromJson(json))
          .toList();
      await WordListStorage.saveWordLists(wordLists);

      final progressJson = backupData['progress'] as Map<String, dynamic>;
      final progress = StudyProgress.fromJson(progressJson);
      await progress.save();

      debugPrint('从备份恢复成功: $backupFileName');
      return true;
    } catch (e) {
      debugPrint('从备份恢复失败: $e');
      return false;
    }
  }

  Future<List<String>> getBackupList() async {
    try {
      final allKeys = await PlatformStorage.getAllKeys();
      final backupKeys = allKeys
          .where((key) => key.startsWith('backup_'))
          .toList();

      backupKeys.sort((a, b) => b.compareTo(a));

      return backupKeys;
    } catch (e) {
      debugPrint('获取备份列表失败: $e');
      return [];
    }
  }

  Future<void> deleteBackup(String backupFileName) async {
    try {
      await PlatformStorage.deleteData(backupFileName);
      debugPrint('删除备份: $backupFileName');
    } catch (e) {
      debugPrint('删除备份失败: $e');
    }
  }
}
