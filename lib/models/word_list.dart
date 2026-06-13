/// 单词表数据模型
///
/// 功能：
/// - 表示应用中的单词表数据结构
/// - 包含单词表的基本信息（名称、创建时间等）
/// - 管理单词表与单词的关联关系
/// - 提供序列化和反序列化方法，用于本地存储
class WordList {
  /// 单词表的唯一标识符
  ///
  /// 用于区分不同的单词表，通常使用时间戳或数据库自增ID
  final int id;

  /// 单词表的名称
  ///
  /// 用户自定义的单词表名称，例如："高中英语"、"日常用语"等
  final String name;

  /// 单词表的创建时间
  ///
  /// 记录单词表的创建时间，用于排序和显示
  final DateTime createdAt;

  /// 单词表中包含的单词ID列表
  ///
  /// 存储该单词表中所有单词的ID，用于快速查询和管理
  /// 支持同一单词存在于多个单词表中
  List<int> wordIds;

  /// 单词表是否为当前学习内容
  ///
  /// 标记该单词表是否为用户当前正在学习的单词表
  bool isCurrent;

  /// 单词表的构造函数
  ///
  /// 参数：
  /// - id：单词表的唯一标识符
  /// - name：单词表的名称
  /// - createdAt：单词表的创建时间，默认为当前时间
  /// - wordIds：单词表中包含的单词ID列表，默认为空列表
  /// - isCurrent：单词表是否为当前学习内容，默认为false
  WordList({
    required this.id,
    required this.name,
    DateTime? createdAt,
    List<int>? wordIds,
    this.isCurrent = false,
  })  : this.createdAt = createdAt ?? DateTime.now(),
        this.wordIds = wordIds ?? [];

  /// 将WordList实例转换为JSON格式
  ///
  /// 功能：
  /// - 将WordList对象转换为JSON映射
  /// - 用于将WordList对象保存到本地存储或发送到网络
  ///
  /// 返回值：
  /// - Map<String, dynamic>：包含WordList数据的JSON映射
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch, // 将DateTime转换为毫秒时间戳保存
      'wordIds': wordIds,
      'isCurrent': isCurrent,
    };
  }

  /// 从JSON格式创建WordList实例
  ///
  /// 功能：
  /// - 将JSON映射转换为WordList对象
  /// - 用于从本地存储或网络加载WordList数据
  ///
  /// 参数：
  /// - json：包含WordList数据的JSON映射
  ///
  /// 返回值：
  /// - WordList：从JSON数据创建的WordList实例
  factory WordList.fromJson(Map<String, dynamic> json) {
    return WordList(
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int), // 将毫秒时间戳转换为DateTime
      wordIds: (json['wordIds'] as List<dynamic>).map((e) => e as int).toList(), // 将dynamic列表转换为int列表
      isCurrent: json['isCurrent'] as bool,
    );
  }

  /// 添加单词到单词表
  ///
  /// 功能：
  /// - 将单词ID添加到单词表的wordIds列表中
  /// - 支持重复添加同一单词（单词表允许重复包含单词）
  ///
  /// 参数：
  /// - wordId：要添加的单词的ID
  void addWord(int wordId) {
    wordIds.add(wordId);
  }

  /// 从单词表中移除单词
  ///
  /// 功能：
  /// - 从单词表的wordIds列表中移除指定的单词ID
  /// - 如果单词ID不存在于列表中，不执行任何操作
  ///
  /// 参数：
  /// - wordId：要移除的单词的ID
  void removeWord(int wordId) {
    wordIds.remove(wordId);
  }

  /// 检查单词表是否包含指定单词
  ///
  /// 功能：
  /// - 检查单词表的wordIds列表中是否包含指定的单词ID
  ///
  /// 参数：
  /// - wordId：要检查的单词的ID
  ///
  /// 返回值：
  /// - bool：如果单词表包含该单词，返回true；否则返回false
  bool containsWord(int wordId) {
    return wordIds.contains(wordId);
  }

  /// 获取单词表中单词的数量
  ///
  /// 功能：
  /// - 返回单词表中包含的单词数量
  ///
  /// 返回值：
  /// - int：单词表中单词的数量
  int get wordCount {
    return wordIds.length;
  }
}
