/// JSON编码解码库，用于将对象转换为JSON字符串和从JSON字符串转换为对象
import 'dart:convert';

/// Flutter调试库，用于输出调试信息
import 'package:flutter/foundation.dart';

/// 跨平台存储服务
import '../services/platform_storage.dart';

/// 单词模型，用于获取StudyStatus枚举
import 'word.dart';

/// 复习记录类
///
/// 用于记录每次复习的详细信息
class ReviewRecord {
  /// 复习时间
  final DateTime timestamp;

  /// 复习结果（是否正确）
  final bool isCorrect;

  /// 复习时单词的状态
  final StudyStatus status;

  ReviewRecord({
    required this.timestamp,
    required this.isCorrect,
    required this.status,
  });

  factory ReviewRecord.fromJson(Map<String, dynamic> json) {
    return ReviewRecord(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      isCorrect: json['isCorrect'],
      status: StudyStatus.values[json['status']],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isCorrect': isCorrect,
      'status': status.index,
    };
  }
}

/// 学习记录类
///
/// 用于记录每次学习的详细信息
class StudyRecord {
  /// 学习时间
  final DateTime timestamp;

  /// 学习结果（是否掌握）
  final bool isMastered;

  /// 学习时单词的状态
  final StudyStatus status;

  StudyRecord({
    required this.timestamp,
    required this.isMastered,
    required this.status,
  });

  factory StudyRecord.fromJson(Map<String, dynamic> json) {
    return StudyRecord(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      isMastered: json['isMastered'],
      status: StudyStatus.values[json['status']],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isMastered': isMastered,
      'status': status.index,
    };
  }
}

/// 学习进度模型类
///
/// 功能：
/// - 跟踪用户的学习数据和统计信息
/// - 管理每日学习目标和进度
/// - 计算连续学习天数
/// - 提供签到功能和签到记录
/// - 提供数据持久化（保存到本地文件和从本地文件加载）
class StudyProgress {
  /// 总学习单词数
  ///
  /// 统计用户从开始使用应用以来学习的所有单词数量
  int totalWordsStudied;

  /// 已掌握单词数
  ///
  /// 统计用户已经掌握的单词数量
  /// 掌握标准：学习状态为StudyStatus.mastered的单词
  int masteredWords;

  /// 今日学习单词数
  ///
  /// 统计用户当天学习的单词数量
  /// 每天0点自动重置
  int todayWordsStudied;

  /// 连续学习天数
  ///
  /// 统计用户连续学习的天数
  /// - 如果今天学习过，且昨天也学习过，连续天数+1
  /// - 如果今天学习过，但昨天没学习，连续天数重置为1
  int consecutiveDays;

  /// 总学习时长（秒）
  ///
  /// 统计用户从开始使用应用以来的总学习时长
  int totalStudyTime;

  /// 学习目标（每天学习单词数）
  ///
  /// 用户设置的每日学习目标，默认值为20个单词
  /// 可通过设置页面修改
  int dailyGoal;

  /// 复习目标（每天复习单词数）
  ///
  /// 用户设置的每日复习目标，默认值为50个单词
  /// 可通过设置页面修改
  int dailyReviewGoal;

  /// 上次学习日期
  ///
  /// 记录用户上次学习的日期
  /// 用于计算连续学习天数和判断是否需要重置今日数据
  DateTime lastStudyDate;

  /// 今日学习时长（秒）
  ///
  /// 统计用户当天的学习时长
  /// 每天0点自动重置
  int todayStudyTime;

  /// 今日已复习单词数
  ///
  /// 统计用户当天复习的单词数量
  /// 每天0点自动重置
  int todayWordsReviewed;

  /// 待复习单词数
  ///
  /// 统计用户需要复习的单词数量
  int reviewWords;

  /// 上次签到日期
  ///
  /// 记录用户上次签到的日期
  /// 用于判断今天是否已经签到
  DateTime lastCheckInDate;

  /// 签到记录
  ///
  /// 存储用户的签到历史记录
  /// 键：日期字符串（格式：yyyy-MM-dd）
  /// 值：签到状态（true：已签到，false：未签到）
  Map<String, bool> checkInHistory;

  /// 上次应用关闭时间
  ///
  /// 记录用户上次关闭应用的时间
  /// 用于计算应用不活动时间，调整复习量
  DateTime lastAppCloseTime;

  /// 复习进度记录
  ///
  /// 存储每次复习的详细信息
  /// 键：单词ID
  /// 值：复习记录（包含时间戳和结果）
  Map<int, List<ReviewRecord>> reviewRecords;

  /// 学习进度记录
  ///
  /// 存储每次学习的详细信息
  /// 键：单词ID
  /// 值：学习记录（包含时间戳和结果）
  Map<int, List<StudyRecord>> studyRecords;

  /// 构造函数，用于创建StudyProgress实例
  ///
  /// 参数说明：
  /// - totalWordsStudied：总学习单词数，默认值为0
  /// - masteredWords：已掌握单词数，默认值为0
  /// - todayWordsStudied：今日学习单词数，默认值为0
  /// - consecutiveDays：连续学习天数，默认值为0
  /// - totalStudyTime：总学习时长，默认值为0
  /// - dailyGoal：每日学习目标，默认值为20个单词
  /// - lastStudyDate：上次学习日期，默认值为当前时间
  /// - todayStudyTime：今日学习时长，默认值为0
  StudyProgress({
    this.totalWordsStudied = 0,
    this.masteredWords = 0,
    this.todayWordsStudied = 0,
    this.consecutiveDays = 0,
    this.totalStudyTime = 0,
    this.dailyGoal = 20,
    this.dailyReviewGoal = 50,
    DateTime? lastStudyDate,
    this.todayStudyTime = 0,
    this.todayWordsReviewed = 0,
    this.reviewWords = 0,
    DateTime? lastCheckInDate,
    Map<String, bool>? checkInHistory,
    DateTime? lastAppCloseTime,
    Map<int, List<ReviewRecord>>? reviewRecords,
    Map<int, List<StudyRecord>>? studyRecords,
  }) : lastStudyDate = lastStudyDate ?? DateTime.now(),
       lastCheckInDate =
           lastCheckInDate ?? DateTime.now().subtract(Duration(days: 1)),
       checkInHistory = checkInHistory ?? {},
       lastAppCloseTime = lastAppCloseTime ?? DateTime.now(),
       reviewRecords = reviewRecords ?? {},
       studyRecords = studyRecords ?? {};

  /// 工厂构造函数：从JSON数据创建StudyProgress实例
  ///
  /// 功能：
  /// - 将JSON格式的数据转换为StudyProgress对象
  /// - 用于从本地文件加载数据后，实例化StudyProgress对象
  ///
  /// 参数：
  /// - json：包含学习进度数据的JSON映射
  ///
  /// 返回值：
  /// - StudyProgress：创建的StudyProgress实例
  factory StudyProgress.fromJson(Map<String, dynamic> json) {
    return StudyProgress(
      totalWordsStudied: json['totalWordsStudied'],
      masteredWords: json['masteredWords'],
      todayWordsStudied: json['todayWordsStudied'],
      consecutiveDays: json['consecutiveDays'],
      totalStudyTime: json['totalStudyTime'],
      dailyGoal: json['dailyGoal'],
      dailyReviewGoal: json['dailyReviewGoal'] ?? 50,
      lastStudyDate: DateTime.fromMillisecondsSinceEpoch(json['lastStudyDate']),
      todayStudyTime: json['todayStudyTime'],
      todayWordsReviewed: json['todayWordsReviewed'] ?? 0,
      reviewWords: json['reviewWords'] ?? 0,
      lastCheckInDate: DateTime.fromMillisecondsSinceEpoch(
        json['lastCheckInDate'] ??
            DateTime.now().subtract(Duration(days: 1)).millisecondsSinceEpoch,
      ),
      checkInHistory: Map<String, bool>.from(json['checkInHistory'] ?? {}),
      lastAppCloseTime: json['lastAppCloseTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastAppCloseTime'])
          : null,
      reviewRecords: json['reviewRecords'] != null
          ? Map<int, List<ReviewRecord>>.from(
              json['reviewRecords'].map(
                (key, value) => MapEntry(
                  int.parse(key),
                  (value as List)
                      .map((item) => ReviewRecord.fromJson(item))
                      .toList(),
                ),
              ),
            )
          : null,
      studyRecords: json['studyRecords'] != null
          ? Map<int, List<StudyRecord>>.from(
              json['studyRecords'].map(
                (key, value) => MapEntry(
                  int.parse(key),
                  (value as List)
                      .map((item) => StudyRecord.fromJson(item))
                      .toList(),
                ),
              ),
            )
          : null,
    );
  }

  /// 将StudyProgress实例转换为JSON格式
  ///
  /// 功能：
  /// - 将StudyProgress对象转换为JSON映射
  /// - 用于将StudyProgress对象保存到本地文件
  ///
  /// 返回值：
  /// - Map<String, dynamic>：包含学习进度数据的JSON映射
  Map<String, dynamic> toJson() {
    return {
      'totalWordsStudied': totalWordsStudied,
      'masteredWords': masteredWords,
      'todayWordsStudied': todayWordsStudied,
      'consecutiveDays': consecutiveDays,
      'totalStudyTime': totalStudyTime,
      'dailyGoal': dailyGoal,
      'dailyReviewGoal': dailyReviewGoal,
      'lastStudyDate': lastStudyDate.millisecondsSinceEpoch,
      'todayStudyTime': todayStudyTime,
      'todayWordsReviewed': todayWordsReviewed,
      'reviewWords': reviewWords,
      'lastCheckInDate': lastCheckInDate.millisecondsSinceEpoch,
      'checkInHistory': checkInHistory,
      'lastAppCloseTime': lastAppCloseTime?.millisecondsSinceEpoch,
      'reviewRecords': reviewRecords?.map(
        (key, value) => MapEntry(
          key.toString(),
          value.map((record) => record.toJson()).toList(),
        ),
      ),
      'studyRecords': studyRecords?.map(
        (key, value) => MapEntry(
          key.toString(),
          value.map((record) => record.toJson()).toList(),
        ),
      ),
    };
  }

  /// 保存学习进度到本地文件
  ///
  /// 功能：
  /// - 将StudyProgress对象转换为JSON字符串
  /// - 将JSON字符串写入到应用文档目录下的study_progress.json文件
  /// - 用于持久化保存学习进度数据
  ///
  /// 返回值：
  /// - Future<void>：异步操作，无返回值
  Future<void> save() async {
    try {
      final jsonString = json.encode(toJson());
      await PlatformStorage.saveData('study_progress', jsonString);
    } catch (e) {
      debugPrint('保存学习进度失败: $e');
    }
  }

  /// 从本地文件加载学习进度
  ///
  /// 功能：
  /// - 从应用文档目录下的study_progress.json文件读取JSON字符串
  /// - 将JSON字符串转换为StudyProgress对象
  /// - 检查是否跨天，更新今日数据和连续学习天数
  ///
  /// 返回值：
  /// - Future<StudyProgress>：异步操作，返回StudyProgress实例
  static Future<StudyProgress> load() async {
    try {
      final jsonString = await PlatformStorage.loadData('study_progress');

      if (jsonString == null) {
        return StudyProgress();
      }

      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final progress = StudyProgress.fromJson(jsonData);

      if (!isSameDay(progress.lastStudyDate, DateTime.now())) {
        progress.todayWordsStudied = 0;
        progress.todayStudyTime = 0;
        progress.todayWordsReviewed = 0;

        final yesterday = DateTime.now().subtract(Duration(days: 1));
        if (isSameDay(progress.lastStudyDate, yesterday)) {
          progress.consecutiveDays++;
        } else {
          progress.consecutiveDays = 1;
        }

        progress.lastStudyDate = DateTime.now();
      }

      return progress;
    } catch (e) {
      debugPrint('加载学习进度失败: $e');
      return StudyProgress();
    }
  }

  /// 更新学习单词数
  ///
  /// 功能：
  /// - 增加总学习单词数和今日学习单词数
  /// - 如果是掌握的单词，增加已掌握单词数
  /// - 自动保存更新后的进度到本地文件
  ///
  /// 参数：
  /// - count：本次学习的单词数量
  /// - isMastered：本次学习的单词是否已掌握
  void updateWordsStudied(int count, bool isMastered) {
    totalWordsStudied += count;
    todayWordsStudied += count;
    if (isMastered) {
      masteredWords += count;
    }
    save();
  }

  /// 更新复习单词数
  ///
  /// 功能：
  /// - 增加今日已复习单词数
  /// - 减少待复习单词数
  /// - 自动保存更新后的进度到本地文件
  ///
  /// 参数：
  /// - count：本次复习的单词数量
  void updateWordsReviewed(int count) {
    todayWordsReviewed += count;
    reviewWords = (reviewWords - count).clamp(0, reviewWords);
    save();
  }

  /// 更新学习时长
  ///
  /// 功能：
  /// - 增加总学习时长和今日学习时长
  /// - 自动保存更新后的进度到本地文件
  ///
  /// 参数：
  /// - seconds：本次学习的时长（秒）
  void updateStudyTime(int seconds) {
    totalStudyTime += seconds;
    todayStudyTime += seconds;
    save();
  }

  /// 更新每日学习目标
  ///
  /// 功能：
  /// - 更新每日学习目标
  /// - 自动保存更新后的进度到本地文件
  ///
  /// 参数：
  /// - newGoal：新的每日学习目标（单词数）
  void updateDailyGoal(int newGoal) {
    dailyGoal = newGoal;
    save();
  }

  /// 更新每日复习目标
  ///
  /// 功能：
  /// - 更新每日复习目标
  /// - 自动保存更新后的进度到本地文件
  ///
  /// 参数：
  /// - newGoal：新的每日复习目标（单词数）
  void updateDailyReviewGoal(int newGoal) {
    dailyReviewGoal = newGoal;
    save();
  }

  /// 记录单词学习
  ///
  /// 功能：
  /// - 记录单词的学习详细信息
  /// - 自动保存更新后的进度到本地文件
  ///
  /// 参数：
  /// - wordId：单词ID
  /// - isMastered：是否掌握
  /// - status：学习状态
  void recordStudy(int wordId, bool isMastered, StudyStatus status) {
    if (!studyRecords.containsKey(wordId)) {
      studyRecords[wordId] = [];
    }
    studyRecords[wordId]!.add(
      StudyRecord(
        timestamp: DateTime.now(),
        isMastered: isMastered,
        status: status,
      ),
    );
    save();
  }

  /// 记录单词复习
  ///
  /// 功能：
  /// - 记录单词的复习详细信息
  /// - 自动保存更新后的进度到本地文件
  ///
  /// 参数：
  /// - wordId：单词ID
  /// - isCorrect：是否正确
  /// - status：学习状态
  void recordReview(int wordId, bool isCorrect, StudyStatus status) {
    if (!reviewRecords.containsKey(wordId)) {
      reviewRecords[wordId] = [];
    }
    reviewRecords[wordId]!.add(
      ReviewRecord(
        timestamp: DateTime.now(),
        isCorrect: isCorrect,
        status: status,
      ),
    );
    save();
  }

  /// 记录应用关闭时间
  ///
  /// 功能：
  /// - 记录应用关闭的时间
  /// - 自动保存更新后的进度到本地文件
  ///
  /// 参数：
  /// - closeTime：关闭时间
  void recordAppCloseTime(DateTime closeTime) {
    lastAppCloseTime = closeTime;
    save();
  }

  /// 计算应用不活动时间
  ///
  /// 功能：
  /// - 计算应用上次关闭到现在的时长
  /// - 用于复习算法调整复习量
  ///
  /// 返回值：
  /// - Duration：不活动时长
  Duration calculateInactiveTime() {
    final now = DateTime.now();
    return now.difference(lastAppCloseTime);
  }

  /// 计算需要增加的复习量
  ///
  /// 功能：
  /// - 根据应用不活动时间计算需要增加的复习量
  /// - 不活动时间越长，需要复习的单词越多
  ///
  /// 返回值：
  /// - int：需要增加的复习单词数
  int calculateAdditionalReviewVolume() {
    final inactiveTime = calculateInactiveTime();
    final daysInactive = inactiveTime.inDays;

    if (daysInactive < 1) {
      return 0;
    } else if (daysInactive < 3) {
      return 5;
    } else if (daysInactive < 7) {
      return 10;
    } else if (daysInactive < 14) {
      return 20;
    } else {
      return 30;
    }
  }

  /// 判断是否达成今日学习目标
  ///
  /// 功能：
  /// - 检查今日学习单词数是否达到每日学习目标
  ///
  /// 返回值：
  /// - bool：true表示已达成目标，false表示未达成
  bool isDailyGoalAchieved() {
    return todayWordsStudied >= dailyGoal;
  }

  /// 判断是否达成今日复习目标
  ///
  /// 功能：
  /// - 检查今日复习单词数是否达到每日复习目标
  ///
  /// 返回值：
  /// - bool：true表示已达成目标，false表示未达成
  bool isDailyReviewGoalAchieved() {
    return todayWordsReviewed >= dailyReviewGoal;
  }

  /// 获取学习进度百分比
  ///
  /// 功能：
  /// - 计算今日学习进度相对于每日目标的百分比
  ///
  /// 返回值：
  /// - double：进度百分比（0-100）
  double getDailyProgressPercentage() {
    if (dailyGoal == 0) return 100;
    return (todayWordsStudied / dailyGoal * 100).clamp(0, 100);
  }

  /// 获取复习进度百分比
  ///
  /// 功能：
  /// - 计算今日复习进度相对于每日复习目标的百分比
  ///
  /// 返回值：
  /// - double：进度百分比（0-100）
  double getDailyReviewProgressPercentage() {
    if (dailyReviewGoal == 0) return 100;
    return (todayWordsReviewed / dailyReviewGoal * 100).clamp(0, 100);
  }

  /// 格式化学习时长
  ///
  /// 功能：
  /// - 将秒数转换为易读的时间格式
  ///
  /// 参数：
  /// - seconds：总秒数
  ///
  /// 返回值：
  /// - String：格式化后的时间字符串
  static String formatStudyTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}小时${minutes}分钟';
    } else if (minutes > 0) {
      return '${minutes}分钟${secs}秒';
    } else {
      return '${secs}秒';
    }
  }

  /// 格式化日期
  ///
  /// 功能：
  /// - 将日期格式化为易读的字符串
  ///
  /// 参数：
  /// - date：要格式化的日期
  ///
  /// 返回值：
  /// - String：格式化后的日期字符串
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 判断两个日期是否是同一天
  ///
  /// 功能：
  /// - 比较两个日期的年、月、日是否相同
  ///
  /// 参数：
  /// - date1：第一个日期
  /// - date2：第二个日期
  ///
  /// 返回值：
  /// - bool：true表示是同一天，false表示不是同一天
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 判断今天是否已签到
  ///
  /// 功能：
  /// - 检查用户今天是否已经签到
  ///
  /// 返回值：
  /// - bool：true表示今天已签到，false表示今天未签到
  bool isTodayCheckedIn() {
    final todayKey = formatDate(DateTime.now());
    return checkInHistory[todayKey] ?? false;
  }

  /// 执行签到
  ///
  /// 功能：
  /// - 记录用户今天的签到状态
  /// - 更新连续签到天数
  /// - 自动保存更新后的进度到本地文件
  ///
  /// 返回值：
  /// - bool：true表示签到成功，false表示今天已经签到过了
  bool checkIn() {
    final today = DateTime.now();
    final todayKey = formatDate(today);

    if (checkInHistory[todayKey] ?? false) {
      return false;
    }

    checkInHistory[todayKey] = true;

    final yesterday = today.subtract(Duration(days: 1));
    final yesterdayKey = formatDate(yesterday);

    if (checkInHistory[yesterdayKey] ?? false) {
      consecutiveDays++;
    } else {
      consecutiveDays = 1;
    }

    lastCheckInDate = today;
    save();
    return true;
  }

  /// 获取指定月份的签到记录
  ///
  /// 功能：
  /// - 获取指定年月的签到记录
  /// - 返回该月份每一天的签到状态
  ///
  /// 参数：
  /// - year：年份
  /// - month：月份（1-12）
  ///
  /// 返回值：
  /// - Map<int, bool>：键为日期（1-31），值为签到状态
  Map<int, bool> getCheckInRecordsForMonth(int year, int month) {
    Map<int, bool> records = {};
    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final dateKey =
          '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      records[day] = checkInHistory[dateKey] ?? false;
    }

    return records;
  }
}
