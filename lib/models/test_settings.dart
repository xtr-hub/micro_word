import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './word_list.dart';

/// 测试设置类
///
/// 用于存储和管理测试相关的设置
class TestSettings {
  int testWordCount;
  int? selectedWordListId;
  String? customWordListPath;

  TestSettings({
    this.testWordCount = 10,
    this.selectedWordListId,
    this.customWordListPath,
  });

  factory TestSettings.fromJson(Map<String, dynamic> json) {
    return TestSettings(
      testWordCount: json['testWordCount'] ?? 10,
      selectedWordListId: json['selectedWordListId'],
      customWordListPath: json['customWordListPath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'testWordCount': testWordCount,
      'selectedWordListId': selectedWordListId,
      'customWordListPath': customWordListPath,
    };
  }
}

/// 测试设置存储服务
///
/// 用于处理测试设置的持久化存储和读取
class TestSettingsStorage {
  static const String _testSettingsKey = 'test_settings';

  /// 保存测试设置
  ///
  /// 参数：
  /// - settings: 要保存的测试设置对象
  /// - wordList: 选中的单词表（可选）
  static Future<bool> saveTestSettings(
    TestSettings settings, [
    WordList? wordList,
  ]) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 如果提供了wordList，更新selectedWordListId
      if (wordList != null) {
        settings.selectedWordListId = wordList.id;
      }

      final jsonString = json.encode(settings.toJson());
      await prefs.setString(_testSettingsKey, jsonString);
      return true;
    } catch (e) {
      debugPrint('保存测试设置失败: $e');
      return false;
    }
  }

  /// 加载测试设置
  ///
  /// 返回：
  /// - TestSettings: 加载的测试设置对象
  static Future<TestSettings> loadTestSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_testSettingsKey);

      if (jsonString != null) {
        final jsonData = json.decode(jsonString) as Map<String, dynamic>;
        return TestSettings.fromJson(jsonData);
      }
    } catch (e) {
      debugPrint('加载测试设置失败: $e');
    }

    return TestSettings();
  }

  /// 删除测试设置
  ///
  /// 返回：
  /// - bool: 删除是否成功
  static Future<bool> deleteTestSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_testSettingsKey);
      return true;
    } catch (e) {
      debugPrint('删除测试设置失败: $e');
      return false;
    }
  }
}
