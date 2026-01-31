/// JSON编码解码库，用于将对象转换为JSON字符串和从JSON字符串转换为对象
import 'dart:convert';

/// Flutter调试库，用于输出调试信息
import 'package:flutter/foundation.dart';

/// 跨平台存储服务
import '../services/platform_storage.dart';

/// 测试模式枚举
enum TestMode {
  multipleChoice, // 选择题
  blankFill, // 填空题
}

/// 测试题目状态枚举
enum QuestionStatus {
  correct, // 正确
  wrong, // 错误
  unattempted, // 未作答
}

/// 测试题目记录类
class TestQuestion {
  /// 题目ID
  final String id;

  /// 题型
  final TestMode mode;

  /// 题干（选择题：单词，填空题：释义）
  final String question;

  /// 用户答案
  final String? userAnswer;

  /// 正确答案
  final String correctAnswer;

  /// 作答状态
  final QuestionStatus status;

  /// 选项（仅选择题有）
  final List<String>? options;

  /// 构造函数
  TestQuestion({
    required this.id,
    required this.mode,
    required this.question,
    this.userAnswer,
    required this.correctAnswer,
    required this.status,
    this.options,
  });

  /// 从JSON映射创建TestQuestion实例
  factory TestQuestion.fromJson(Map<String, dynamic> json) {
    return TestQuestion(
      id: json['id'],
      mode: TestMode.values[json['mode']],
      question: json['question'],
      userAnswer: json['userAnswer'],
      correctAnswer: json['correctAnswer'],
      status: QuestionStatus.values[json['status']],
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
    );
  }

  /// 将TestQuestion实例转换为JSON映射
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mode': mode.index,
      'question': question,
      'userAnswer': userAnswer,
      'correctAnswer': correctAnswer,
      'status': status.index,
      'options': options,
    };
  }
}

/// 测试记录类
class TestRecord {
  /// 测试ID
  final String id;

  /// 测试时间
  final DateTime testTime;

  /// 测试时长（秒）
  final int testDuration;

  /// 总题数
  final int totalQuestions;

  /// 答对题数
  final int correctQuestions;

  /// 得分（百分比）
  final int score;

  /// 测试模式
  final TestMode testMode;

  /// 测试单词数
  final int testWordCount;

  /// 测试范围描述
  final String testRange;

  /// 题目记录列表
  final List<TestQuestion> questions;

  /// 构造函数
  TestRecord({
    String? id,
    required this.testTime,
    required this.testDuration,
    required this.totalQuestions,
    required this.correctQuestions,
    required this.score,
    required this.testMode,
    required this.testWordCount,
    required this.testRange,
    required this.questions,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  /// 从JSON映射创建TestRecord实例
  factory TestRecord.fromJson(Map<String, dynamic> json) {
    return TestRecord(
      id: json['id'],
      testTime: DateTime.parse(json['testTime']),
      testDuration: json['testDuration'],
      totalQuestions: json['totalQuestions'],
      correctQuestions: json['correctQuestions'],
      score: json['score'],
      testMode: TestMode.values[json['testMode']],
      testWordCount: json['testWordCount'],
      testRange: json['testRange'],
      questions: (json['questions'] as List)
          .map((q) => TestQuestion.fromJson(q))
          .toList(),
    );
  }

  /// 将TestRecord实例转换为JSON映射
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testTime': testTime.toIso8601String(),
      'testDuration': testDuration,
      'totalQuestions': totalQuestions,
      'correctQuestions': correctQuestions,
      'score': score,
      'testMode': testMode.index,
      'testWordCount': testWordCount,
      'testRange': testRange,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

  /// 获取测试时长的格式化字符串（分钟:秒）
  String get formattedDuration {
    final minutes = testDuration ~/ 60;
    final seconds = testDuration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 获取测试日期时间的格式化字符串
  String get formattedTestTime {
    return '${testTime.year}-${testTime.month.toString().padLeft(2, '0')}-${testTime.day.toString().padLeft(2, '0')} ${testTime.hour.toString().padLeft(2, '0')}:${testTime.minute.toString().padLeft(2, '0')}:${testTime.second.toString().padLeft(2, '0')}';
  }
}

/// 测试记录存储服务
class TestRecordStorage {
  /// 存储键名称
  static const String _storageKey = 'test_records';

  /// 保存测试记录列表
  static Future<void> saveRecords(List<TestRecord> records) async {
    try {
      final jsonRecords = records.map((record) => record.toJson()).toList();
      final jsonString = jsonEncode(jsonRecords);
      await PlatformStorage.saveData(_storageKey, jsonString);
    } catch (e) {
      debugPrint('保存测试记录失败: $e');
    }
  }

  /// 加载测试记录列表
  static Future<List<TestRecord>> loadRecords() async {
    try {
      final jsonString = await PlatformStorage.loadData(_storageKey);
      if (jsonString == null) {
        return [];
      }
      final jsonRecords = jsonDecode(jsonString) as List;
      return jsonRecords.map((json) => TestRecord.fromJson(json)).toList();
    } catch (e) {
      debugPrint('加载测试记录失败: $e');
      return [];
    }
  }

  /// 添加测试记录
  static Future<void> addRecord(TestRecord record) async {
    final records = await loadRecords();
    records.insert(0, record); // 插入到列表开头
    await saveRecords(records);
  }
}
