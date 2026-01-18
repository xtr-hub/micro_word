/// 单词数据模型
///
/// 功能：
/// - 表示应用中的单词数据结构
/// - 包含单词的基本信息（英文、中文释义、音标、例句）
/// - 跟踪单词的学习状态和进度
/// - 支持收藏功能
/// - 提供序列化和反序列化方法，用于本地存储
class Word {
  /// 单词的唯一标识符
  ///
  /// 用于区分不同单词，通常使用时间戳或数据库自增ID
  final int id;

  /// 英文单词内容
  ///
  /// 例如："apple"、"banana"等
  final String word;

  /// 单词的中文释义
  ///
  /// 例如："苹果"、"香蕉"等
  final String meaning;

  /// 单词的音标
  ///
  /// 可为空，表示有些单词可能没有音标数据
  /// 例如："/'æpl/"、"/bəˈnɑːnə/"等
  final String? phonetic;

  /// 单词的例句
  ///
  /// 可为空，表示有些单词可能没有例句
  /// 例如："I eat an apple every day."等
  final String? example;

  /// 单词的学习状态
  ///
  /// 使用StudyStatus枚举表示，可取值：
  /// - StudyStatus.newWord：新单词
  /// - StudyStatus.learning：学习中
  /// - StudyStatus.familiar：熟悉
  /// - StudyStatus.mastered：已掌握
  /// - StudyStatus.reviewed：已复习
  StudyStatus status;

  /// 最后学习该单词的时间
  ///
  /// 用于跟踪单词的学习频率和间隔
  DateTime lastStudyTime;

  /// 记忆强度
  ///
  /// 用于间隔重复算法，值越高表示记忆越牢固
  /// 范围：0-5，默认值为0
  int memoryStrength;

  /// 是否将该单词收藏
  ///
  /// true表示已收藏，false表示未收藏
  bool isFavorite;

  /// 构造函数，用于创建Word实例
  ///
  /// 参数说明：
  /// - id：单词ID，必填
  /// - word：英文单词，必填
  /// - meaning：中文释义，必填
  /// - phonetic：音标，可选
  /// - example：例句，可选
  /// - status：学习状态，默认值为StudyStatus.newWord
  /// - lastStudyTime：最后学习时间，默认值为当前时间
  /// - memoryStrength：记忆强度，默认值为0
  /// - isFavorite：是否收藏，默认值为false
  Word({
    required this.id, // 必填：单词ID
    required this.word, // 必填：英文单词
    required this.meaning, // 必填：中文释义
    this.phonetic, // 可选：音标
    this.example, // 可选：例句
    this.status = StudyStatus.newWord, // 可选：学习状态，默认值为新单词
    DateTime? lastStudyTime, // 可选：最后学习时间
    this.memoryStrength = 0, // 可选：记忆强度，默认值为0
    this.isFavorite = false, // 可选：是否收藏，默认值为false
  }) : lastStudyTime =
           lastStudyTime ?? DateTime.now(); // 如果没有提供lastStudyTime，使用当前时间

  /// 工厂构造函数：从JSON数据创建Word实例
  ///
  /// 功能：
  /// - 将JSON格式的数据转换为Word对象
  /// - 用于从本地存储或网络获取数据后，实例化Word对象
  ///
  /// 参数：
  /// - json：包含单词数据的JSON映射
  ///
  /// 返回值：
  /// - Word：创建的Word实例
  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'], // 从JSON中获取ID
      word: json['word'], // 从JSON中获取单词
      meaning: json['meaning'], // 从JSON中获取释义
      phonetic: json['phonetic'], // 从JSON中获取音标
      example: json['example'], // 从JSON中获取例句
      status: StudyStatus.values[json['status']], // 将JSON中的数字转换为StudyStatus枚举
      lastStudyTime: DateTime.fromMillisecondsSinceEpoch(
        json['lastStudyTime'],
      ), // 将毫秒时间戳转换为DateTime对象
      memoryStrength: json['memoryStrength'], // 从JSON中获取记忆强度
      isFavorite: json['isFavorite'] ?? false, // 从JSON中获取收藏状态，默认为false
    );
  }

  /// 将Word实例转换为JSON格式
  ///
  /// 功能：
  /// - 将Word对象转换为JSON映射
  /// - 用于将Word对象保存到本地存储或发送到网络
  ///
  /// 返回值：
  /// - Map<String, dynamic>：包含Word数据的JSON映射
  Map<String, dynamic> toJson() {
    return {
      'id': id, // 保存ID
      'word': word, // 保存单词
      'meaning': meaning, // 保存释义
      'phonetic': phonetic, // 保存音标
      'example': example, // 保存例句
      'status': status.index, // 将StudyStatus枚举转换为数字保存
      'lastStudyTime':
          lastStudyTime.millisecondsSinceEpoch, // 将DateTime转换为毫秒时间戳保存
      'memoryStrength': memoryStrength, // 保存记忆强度
      'isFavorite': isFavorite, // 保存收藏状态
    };
  }

  /// 更新单词的学习状态
  ///
  /// 功能：
  /// - 更新单词的学习状态和最后学习时间
  /// - 根据新状态自动调整记忆强度
  ///
  /// 参数：
  /// - newStatus：新的学习状态
  void updateStatus(StudyStatus newStatus) {
    status = newStatus; // 更新学习状态
    lastStudyTime = DateTime.now(); // 更新最后学习时间为当前时间

    // 根据新状态更新记忆强度
    if (newStatus == StudyStatus.mastered) {
      memoryStrength = 5; // 已掌握状态，记忆强度为5（最高）
    } else if (newStatus == StudyStatus.familiar) {
      memoryStrength = 3; // 熟悉状态，记忆强度为3（中等）
    } else {
      memoryStrength = 1; // 其他状态，记忆强度为1（较低）
    }
  }

  /// 切换单词的收藏状态
  ///
  /// 功能：
  /// - 将单词的收藏状态取反
  /// - 用于实现收藏/取消收藏功能
  void toggleFavorite() {
    isFavorite = !isFavorite; // 取反收藏状态
  }
}

/// 学习状态枚举
///
/// 定义了单词可能的学习状态，用于跟踪学习进度
/// 枚举值从0开始编号，顺序依次为：
/// 0: newWord -> 1: learning -> 2: familiar -> 3: mastered -> 4: reviewed
enum StudyStatus {
  /// 新单词
  ///
  /// 刚添加的单词，尚未学习
  newWord,

  /// 学习中
  ///
  /// 正在学习的单词，尚未掌握
  learning,

  /// 熟悉
  ///
  /// 基本掌握，但还需要定期复习
  familiar,

  /// 已掌握
  ///
  /// 完全掌握，不需要频繁复习
  mastered,

  /// 已复习
  ///
  /// 最近刚复习过的单词
  reviewed,
}
