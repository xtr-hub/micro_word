import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 发音类型枚举
///
/// 定义了两种发音类型：
/// - american: 美式英语发音
/// - british: 英式英语发音
enum PronunciationType { american, british }

/// 将PronunciationType转换为字符串
///
/// 参数：
/// - type: 发音类型枚举值
///
/// 返回值：
/// - String: 对应的字符串表示
String pronunciationTypeToString(PronunciationType type) {
  switch (type) {
    case PronunciationType.american:
      return 'american';
    case PronunciationType.british:
      return 'british';
    default:
      return 'american';
  }
}

/// 将字符串转换为PronunciationType
///
/// 参数：
/// - typeString: 字符串表示的发音类型
///
/// 返回值：
/// - PronunciationType: 对应的枚举值
PronunciationType stringToPronunciationType(String typeString) {
  switch (typeString) {
    case 'american':
      return PronunciationType.american;
    case 'british':
      return PronunciationType.british;
    default:
      return PronunciationType.american;
  }
}

class Settings {
  bool autoPlayPronunciation;
  bool showExampleByDefault;
  PronunciationType pronunciationType;
  int studyGroupSize; // 学习分组大小
  int reviewGroupSize; // 复习分组大小

  Settings({
    this.autoPlayPronunciation = true,
    this.showExampleByDefault = false,
    this.pronunciationType = PronunciationType.american,
    this.studyGroupSize = 5, // 默认学习分组大小为5
    this.reviewGroupSize = 20, // 默认复习分组大小为20
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      autoPlayPronunciation: json['autoPlayPronunciation'],
      showExampleByDefault: json['showExampleByDefault'],
      pronunciationType: stringToPronunciationType(
        json['pronunciationType'] ?? 'american',
      ),
      studyGroupSize: json['studyGroupSize'] ?? 5,
      reviewGroupSize: json['reviewGroupSize'] ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoPlayPronunciation': autoPlayPronunciation,
      'showExampleByDefault': showExampleByDefault,
      'pronunciationType': pronunciationTypeToString(pronunciationType),
      'studyGroupSize': studyGroupSize,
      'reviewGroupSize': reviewGroupSize,
    };
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(toJson());
      await prefs.setString('settings', jsonString);
    } catch (e) {
      print('保存设置失败: $e');
    }
  }

  static Future<Settings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('settings');

      if (jsonString != null) {
        final jsonData = json.decode(jsonString) as Map<String, dynamic>;
        return Settings.fromJson(jsonData);
      }
    } catch (e) {
      print('加载设置失败: $e');
    }

    return Settings();
  }
}
