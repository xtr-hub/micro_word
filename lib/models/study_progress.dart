/// JSON编码解码库，用于将对象转换为JSON字符串和从JSON字符串转换为对象
import 'dart:convert';

/// IO库，用于文件操作（读写文件）
import 'dart:io';

/// path_provider库，用于获取应用程序文档目录（存储数据文件的位置）
import 'package:path_provider/path_provider.dart';

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
    this.totalWordsStudied = 0, // 总学习单词数，默认值为0
    this.masteredWords = 0, // 已掌握单词数，默认值为0
    this.todayWordsStudied = 0, // 今日学习单词数，默认值为0
    this.consecutiveDays = 0, // 连续学习天数，默认值为0
    this.totalStudyTime = 0, // 总学习时长，默认值为0
    this.dailyGoal = 20, // 每日学习目标，默认值为20个单词
    this.dailyReviewGoal = 50, // 每日复习目标，默认值为50个单词
    DateTime? lastStudyDate, // 上次学习日期，可选参数
    this.todayStudyTime = 0, // 今日学习时长，默认值为0
    this.todayWordsReviewed = 0, // 今日已复习单词数，默认值为0
    this.reviewWords = 0, // 待复习单词数，默认值为0个单词
    DateTime? lastCheckInDate, // 上次签到日期，可选参数
    Map<String, bool>? checkInHistory, // 签到记录，可选参数
  }) : lastStudyDate = lastStudyDate ?? DateTime.now(),
       lastCheckInDate =
           lastCheckInDate ?? DateTime.now().subtract(Duration(days: 1)),
       checkInHistory = checkInHistory ?? {};

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
      totalWordsStudied: json['totalWordsStudied'], // 从JSON获取总学习单词数
      masteredWords: json['masteredWords'], // 从JSON获取已掌握单词数
      todayWordsStudied: json['todayWordsStudied'], // 从JSON获取今日学习单词数
      consecutiveDays: json['consecutiveDays'], // 从JSON获取连续学习天数
      totalStudyTime: json['totalStudyTime'], // 从JSON获取总学习时长
      dailyGoal: json['dailyGoal'], // 从JSON获取每日学习目标
      dailyReviewGoal: json['dailyReviewGoal'] ?? 50, // 从JSON获取每日复习目标，默认值为50
      lastStudyDate: DateTime.fromMillisecondsSinceEpoch(
        json['lastStudyDate'],
      ), // 将毫秒时间戳转换为DateTime对象
      todayStudyTime: json['todayStudyTime'], // 从JSON获取今日学习时长
      todayWordsReviewed:
          json['todayWordsReviewed'] ?? 0, // 从JSON获取今日已复习单词数，默认值为0
      reviewWords: json['reviewWords'] ?? 0, // 从JSON获取待复习单词数，默认值为0
      lastCheckInDate: DateTime.fromMillisecondsSinceEpoch(
        json['lastCheckInDate'] ??
            DateTime.now().subtract(Duration(days: 1)).millisecondsSinceEpoch,
      ), // 将毫秒时间戳转换为DateTime对象
      checkInHistory: Map<String, bool>.from(
        json['checkInHistory'] ?? {},
      ), // 从JSON获取签到记录
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
      'totalWordsStudied': totalWordsStudied, // 保存总学习单词数
      'masteredWords': masteredWords, // 保存已掌握单词数
      'todayWordsStudied': todayWordsStudied, // 保存今日学习单词数
      'consecutiveDays': consecutiveDays, // 保存连续学习天数
      'totalStudyTime': totalStudyTime, // 保存总学习时长
      'dailyGoal': dailyGoal, // 保存每日学习目标
      'dailyReviewGoal': dailyReviewGoal, // 保存每日复习目标
      'lastStudyDate': lastStudyDate.millisecondsSinceEpoch, // 保存上次学习日期为毫秒时间戳
      'todayStudyTime': todayStudyTime, // 保存今日学习时长
      'todayWordsReviewed': todayWordsReviewed, // 保存今日已复习单词数
      'reviewWords': reviewWords, // 保存待复习单词数
      'lastCheckInDate':
          lastCheckInDate.millisecondsSinceEpoch, // 保存上次签到日期为毫秒时间戳
      'checkInHistory': checkInHistory, // 保存签到记录
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
      /// 获取应用程序文档目录
      ///
      /// 应用文档目录是应用专用的存储区域，只有应用本身可以访问
      /// 数据会永久保存，直到用户卸载应用或手动清除数据
      final directory = await getApplicationDocumentsDirectory();

      /// 创建或打开学习进度文件
      ///
      /// 文件路径：应用文档目录/study_progress.json
      final file = File('${directory.path}/study_progress.json');

      /// 将StudyProgress实例转换为JSON字符串
      final jsonString = json.encode(toJson());

      /// 将JSON字符串写入文件
      await file.writeAsString(jsonString);
    } catch (e) {
      /// 如果保存失败，打印错误信息
      ///
      /// 在实际应用中，可能需要更完善的错误处理（如显示错误提示给用户）
      print('保存学习进度失败: $e');
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
      /// 获取应用程序文档目录
      final directory = await getApplicationDocumentsDirectory();

      /// 创建或打开学习进度文件
      final file = File('${directory.path}/study_progress.json');

      /// 如果文件不存在，返回默认的StudyProgress实例
      if (!file.existsSync()) {
        return StudyProgress();
      }

      /// 读取文件内容（JSON字符串）
      final jsonString = await file.readAsString();

      /// 将JSON字符串解码为Map对象
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      /// 从JSON数据创建StudyProgress实例
      final progress = StudyProgress.fromJson(jsonData);

      /// 检查是否跨天，重置今日数据
      ///
      /// 如果上次学习日期和今天不是同一天，需要：
      /// 1. 重置今日学习单词数和今日学习时长
      /// 2. 重置今日已复习单词数
      /// 3. 更新连续学习天数
      /// 4. 更新上次学习日期为今天
      if (!isSameDay(progress.lastStudyDate, DateTime.now())) {
        /// 重置今日学习单词数为0
        progress.todayWordsStudied = 0;

        /// 重置今日学习时长为0
        progress.todayStudyTime = 0;

        /// 重置今日已复习单词数为0
        progress.todayWordsReviewed = 0;

        /// 计算昨天的日期
        final yesterday = DateTime.now().subtract(Duration(days: 1));
        if (isSameDay(progress.lastStudyDate, yesterday)) {
          /// 如果昨天学习过，连续天数+1
          progress.consecutiveDays++;
        } else {
          /// 如果昨天没学习，连续天数重置为1
          progress.consecutiveDays = 1;
        }

        /// 更新上次学习日期为当前日期
        progress.lastStudyDate = DateTime.now();
      }

      /// 返回加载后的学习进度
      return progress;
    } catch (e) {
      /// 如果加载失败，打印错误信息并返回默认实例
      print('加载学习进度失败: $e');
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
    totalWordsStudied += count; // 增加总学习单词数
    todayWordsStudied += count; // 增加今日学习单词数
    if (isMastered) {
      masteredWords += count; // 如果是掌握的单词，增加已掌握单词数
    }
    save(); // 保存更新后的进度到本地文件
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
    todayWordsReviewed += count; // 增加今日已复习单词数
    reviewWords = (reviewWords - count).clamp(
      0,
      reviewWords,
    ); // 减少待复习单词数，确保不小于0
    save(); // 保存更新后的进度到本地文件
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
    totalStudyTime += seconds; // 增加总学习时长
    todayStudyTime += seconds; // 增加今日学习时长
    save(); // 保存更新后的进度到本地文件
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
    dailyGoal = newGoal; // 更新每日学习目标
    save(); // 保存更新后的进度到本地文件
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
    dailyReviewGoal = newGoal; // 更新每日复习目标
    save(); // 保存更新后的进度到本地文件
  }

  /// 检查是否完成每日学习目标
  ///
  /// 功能：
  /// - 判断今日学习单词数是否达到或超过每日学习目标
  ///
  /// 返回值：
  /// - bool：true表示已完成目标，false表示未完成
  bool isDailyGoalAchieved() {
    return todayWordsStudied >= dailyGoal; // 如果今日学习单词数大于等于每日目标，返回true
  }

  /// 检查是否完成每日复习目标
  ///
  /// 功能：
  /// - 判断今日复习单词数是否达到或超过每日复习目标
  ///
  /// 返回值：
  /// - bool：true表示已完成目标，false表示未完成
  bool isDailyReviewGoalAchieved() {
    return todayWordsReviewed >= dailyReviewGoal; // 如果今日复习单词数大于等于每日复习目标，返回true
  }

  /// 计算每日学习目标完成进度（百分比）
  ///
  /// 功能：
  /// - 计算今日学习单词数占每日学习目标的百分比
  /// - 返回值范围：0.0（未开始）到1.0（已完成）
  ///
  /// 返回值：
  /// - double：完成进度，范围0.0-1.0
  double getDailyGoalProgress() {
    if (dailyGoal == 0) return 0.0; // 如果每日目标为0，返回0.0
    /// 计算进度并限制在0.0到1.0之间
    ///
    /// 使用clamp方法确保返回值不会小于0.0或大于1.0
    return (todayWordsStudied / dailyGoal).clamp(0.0, 1.0);
  }

  /// 计算每日复习目标完成进度（百分比）
  ///
  /// 功能：
  /// - 计算今日复习单词数占每日复习目标的百分比
  /// - 返回值范围：0.0（未开始）到1.0（已完成）
  ///
  /// 返回值：
  /// - double：完成进度，范围0.0-1.0
  double getDailyReviewGoalProgress() {
    if (dailyReviewGoal == 0) return 0.0; // 如果每日复习目标为0，返回0.0
    /// 计算进度并限制在0.0到1.0之间
    ///
    /// 使用clamp方法确保返回值不会小于0.0或大于1.0
    return (todayWordsReviewed / dailyReviewGoal).clamp(0.0, 1.0);
  }

  /// 格式化日期为字符串（yyyy-MM-dd）
  ///
  /// 功能：
  /// - 将DateTime对象格式化为指定格式的字符串
  /// - 用于签到记录的键名
  ///
  /// 参数：
  /// - date：要格式化的日期
  ///
  /// 返回值：
  /// - String：格式化后的日期字符串
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 检查今天是否已经签到
  ///
  /// 功能：
  /// - 判断用户今天是否已经执行过签到操作
  ///
  /// 返回值：
  /// - bool：true表示今天已签到，false表示今天未签到
  bool isTodayCheckedIn() {
    return isSameDay(lastCheckInDate, DateTime.now());
  }

  /// 执行签到操作
  ///
  /// 功能：
  /// - 记录用户的签到行为
  /// - 更新签到日期和签到记录
  /// - 保存更新后的进度到本地文件
  ///
  /// 返回值：
  /// - bool：true表示签到成功，false表示今天已签到
  bool checkIn() {
    if (isTodayCheckedIn()) {
      return false; // 今天已签到，返回false
    }

    final today = DateTime.now();
    lastCheckInDate = today;
    checkInHistory[formatDate(today)] = true;
    save(); // 保存更新后的进度到本地文件
    return true;
  }

  /// 获取指定月份的签到记录
  ///
  /// 功能：
  /// - 获取用户在指定月份的所有签到记录
  /// - 用于生成学习日历
  ///
  /// 参数：
  /// - year：年份
  /// - month：月份（1-12）
  ///
  /// 返回值：
  /// - Map<int, bool>：键为日期（1-31），值为签到状态
  Map<int, bool> getCheckInRecordsForMonth(int year, int month) {
    final records = <int, bool>{};
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(year, month, day);
      final dateStr = formatDate(date);
      records[day] = checkInHistory[dateStr] ?? false;
    }

    return records;
  }

  /// 辅助方法：检查两个日期是否为同一天
  ///
  /// 功能：
  /// - 比较两个DateTime对象是否为同一天
  /// - 只比较年、月、日，不比较时、分、秒
  ///
  /// 参数：
  /// - date1：第一个日期
  /// - date2：第二个日期
  ///
  /// 返回值：
  /// - bool：true表示是同一天，false表示不是同一天
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && // 检查年份是否相同
        date1.month == date2.month && // 检查月份是否相同
        date1.day == date2.day; // 检查日期是否相同
  }
}
