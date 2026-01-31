/// JSON编码解码库，用于将单词表列表转换为JSON字符串和从JSON字符串转换为单词表列表
import 'dart:convert';

/// Flutter调试库，用于输出调试信息
import 'package:flutter/foundation.dart';

/// 跨平台存储服务
import '../services/platform_storage.dart';

/// WordList模型类，定义了单词表的数据结构
import 'word_list.dart';

/// 单词表存储服务类
///
/// 功能：
/// - 管理单词表数据的持久化存储（保存到本地文件）
/// - 提供CRUD操作（创建、读取、更新、删除）
/// - 支持默认单词表
/// - 管理当前学习的单词表
///
/// 技术说明：
/// - 使用静态方法，不需要创建实例即可使用
/// - 数据存储在应用文档目录下的word_list_data.json文件中
/// - 使用JSON格式进行数据序列化和反序列化
class WordListStorage {
  /// 保存单词表数据的文件名
  ///
  /// 文件路径：应用文档目录/word_list_data.json
  static const String _fileName = 'word_list_data.json';

  /// 保存单词表列表到本地文件
  ///
  /// 功能：
  /// - 将单词表列表序列化为JSON字符串
  /// - 将JSON字符串写入到本地文件
  /// - 用于持久化保存所有单词表数据
  ///
  /// 参数：
  /// - wordLists：要保存的单词表列表
  ///
  /// 返回值：
  /// - Future<void>：异步操作，无返回值
  static Future<void> saveWordLists(List<WordList> wordLists) async {
    try {
      /// 将单词表列表转换为JSON格式
      ///
      /// 转换步骤：
      /// 1. 使用map方法遍历单词表列表，将每个WordList对象转换为JSON Map（调用wordList.toJson()）
      /// 2. 使用toList方法将结果转换为List<Map<String, dynamic>>
      /// 3. 使用json.encode将List转换为JSON字符串
      final jsonList = wordLists.map((wordList) => wordList.toJson()).toList();
      final jsonString = json.encode(jsonList);

      /// 使用跨平台存储服务保存数据
      await PlatformStorage.saveData('word_list_data', jsonString);
    } catch (e) {
      /// 如果保存失败，打印错误信息
      ///
      /// 在实际应用中，可能需要更完善的错误处理（如显示错误提示给用户）
      debugPrint('保存单词表数据失败: $e');
    }
  }

  /// 从本地文件加载单词表列表
  ///
  /// 功能：
  /// - 从本地文件读取JSON字符串
  /// - 将JSON字符串反序列化为单词表列表
  /// - 如果文件不存在或加载失败，返回默认单词表列表
  ///
  /// 返回值：
  /// - Future<List<WordList>>：异步操作，返回包含所有单词表的列表
  static Future<List<WordList>> loadWordLists() async {
    try {
      /// 使用跨平台存储服务加载数据
      final jsonString = await PlatformStorage.loadData('word_list_data');

      /// 检查数据是否存在
      if (jsonString == null) {
        /// 如果数据不存在，返回默认单词表列表
        ///
        /// 首次使用应用时，会返回包含一个默认单词表的列表
        return _getDefaultWordLists();
      }

      /// 解析JSON数据
      ///
      /// 解析步骤：
      /// 1. 使用json.decode将JSON字符串转换为List<dynamic>
      /// 2. 使用map方法遍历列表，将每个JSON Map转换为WordList对象（调用WordList.fromJson(json)）
      /// 3. 使用toList方法将结果转换为List<WordList>
      final jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList.map((json) => WordList.fromJson(json)).toList();
    } catch (e) {
      /// 如果加载失败，打印错误信息
      debugPrint('加载单词表数据失败: $e');

      /// 失败时返回默认单词表列表
      return _getDefaultWordLists();
    }
  }

  /// 获取默认单词表列表
  ///
  /// 功能：
  /// - 当没有保存的单词表数据时，返回这个默认列表
  /// - 包含一个默认单词表，名为"默认单词表"
  ///
  /// 返回值：
  /// - List<WordList>：包含一个默认单词表的列表
  static List<WordList> _getDefaultWordLists() {
    /// 创建一个默认单词表
    final defaultWordList = WordList(
      id: DateTime.now().millisecondsSinceEpoch,
      name: '默认单词表',
      isCurrent: true, // 默认单词表设为当前学习内容
    );

    /// 返回包含默认单词表的列表
    return [defaultWordList];
  }

  /// 添加新单词表到存储中
  ///
  /// 功能：
  /// - 加载现有单词表列表
  /// - 将新单词表添加到列表中
  /// - 如果新单词表被标记为当前学习内容，将其他单词表的isCurrent设置为false
  /// - 保存更新后的列表到本地文件
  ///
  /// 参数：
  /// - newWordList：要添加的新单词表对象
  ///
  /// 返回值：
  /// - Future<void>：异步操作，无返回值
  static Future<void> addWordList(WordList newWordList) async {
    /// 先加载现有单词表列表
    final wordLists = await loadWordLists();

    /// 如果新单词表被标记为当前学习内容，将其他单词表的isCurrent设置为false
    if (newWordList.isCurrent) {
      for (final wordList in wordLists) {
        wordList.isCurrent = false;
      }
    }

    /// 将新单词表添加到列表末尾
    wordLists.add(newWordList);

    /// 将更新后的列表保存到文件
    await saveWordLists(wordLists);
  }

  /// 更新存储中的单词表
  ///
  /// 功能：
  /// - 加载现有单词表列表
  /// - 查找并替换指定ID的单词表
  /// - 如果更新后的单词表被标记为当前学习内容，将其他单词表的isCurrent设置为false
  /// - 保存更新后的列表到本地文件
  ///
  /// 参数：
  /// - updatedWordList：更新后的单词表对象（包含最新数据）
  ///
  /// 返回值：
  /// - Future<void>：异步操作，无返回值
  static Future<void> updateWordList(WordList updatedWordList) async {
    /// 先加载现有单词表列表
    final wordLists = await loadWordLists();

    /// 查找要更新的单词表在列表中的索引
    ///
    /// 使用indexWhere方法查找ID匹配的单词表
    /// 如果找到，返回单词表在列表中的索引
    /// 如果没找到，返回-1
    final index = wordLists.indexWhere(
      (wordList) => wordList.id == updatedWordList.id,
    );

    /// 如果找到了对应的单词表（索引不等于-1）
    if (index != -1) {
      /// 如果更新后的单词表被标记为当前学习内容，将其他单词表的isCurrent设置为false
      if (updatedWordList.isCurrent) {
        for (final wordList in wordLists) {
          wordList.isCurrent = false;
        }
      }

      /// 替换列表中指定索引处的单词表
      wordLists[index] = updatedWordList;

      /// 将更新后的列表保存到文件
      await saveWordLists(wordLists);
    }

    /// 如果没有找到，不执行任何操作
  }

  /// 从存储中删除单词表
  ///
  /// 功能：
  /// - 加载现有单词表列表
  /// - 删除指定ID的单词表
  /// - 如果删除的是当前学习的单词表，将第一个单词表设为当前学习内容
  /// - 保存更新后的列表到本地文件
  ///
  /// 参数：
  /// - wordListId：要删除的单词表的ID
  ///
  /// 返回值：
  /// - Future<void>：异步操作，无返回值
  static Future<void> deleteWordList(int wordListId) async {
    /// 先加载现有单词表列表
    final wordLists = await loadWordLists();

    /// 检查要删除的单词表是否为当前学习的单词表
    final isCurrentWordList = wordLists.any(
      (wordList) => wordList.id == wordListId && wordList.isCurrent,
    );

    /// 从列表中移除ID匹配的单词表
    ///
    /// 使用removeWhere方法删除所有ID匹配的单词表
    /// 理论上应该只有一个匹配项，因为ID是唯一的
    wordLists.removeWhere((wordList) => wordList.id == wordListId);

    /// 如果删除的是当前学习的单词表，且列表不为空，将第一个单词表设为当前学习内容
    if (isCurrentWordList && wordLists.isNotEmpty) {
      wordLists[0].isCurrent = true;
    }

    /// 将更新后的列表保存到文件
    await saveWordLists(wordLists);
  }

  /// 获取当前学习的单词表
  ///
  /// 功能：
  /// - 加载现有单词表列表
  /// - 查找isCurrent为true的单词表
  /// - 如果没有找到，返回第一个单词表
  ///
  /// 返回值：
  /// - Future<WordList>：异步操作，返回当前学习的单词表
  static Future<WordList> getCurrentWordList() async {
    /// 加载现有单词表列表
    final wordLists = await loadWordLists();

    /// 查找isCurrent为true的单词表
    final currentWordList = wordLists.firstWhere(
      (wordList) => wordList.isCurrent,
      orElse: () =>
          wordLists.isNotEmpty ? wordLists[0] : _getDefaultWordLists()[0],
    );

    /// 返回当前学习的单词表
    return currentWordList;
  }

  /// 设置当前学习的单词表
  ///
  /// 功能：
  /// - 加载现有单词表列表
  /// - 将指定ID的单词表的isCurrent设置为true
  /// - 将其他单词表的isCurrent设置为false
  /// - 保存更新后的列表到本地文件
  ///
  /// 参数：
  /// - wordListId：要设置为当前学习内容的单词表的ID
  ///
  /// 返回值：
  /// - Future<void>：异步操作，无返回值
  static Future<void> setCurrentWordList(int wordListId) async {
    /// 先加载现有单词表列表
    final wordLists = await loadWordLists();

    /// 遍历单词表列表，更新isCurrent状态
    for (final wordList in wordLists) {
      wordList.isCurrent = wordList.id == wordListId;
    }

    /// 将更新后的列表保存到文件
    await saveWordLists(wordLists);
  }

  /// 向单词表中添加单词
  ///
  /// 功能：
  /// - 加载现有单词表列表
  /// - 查找指定ID的单词表
  /// - 将单词ID添加到单词表的wordIds列表中
  /// - 保存更新后的列表到本地文件
  ///
  /// 参数：
  /// - wordListId：单词表的ID
  /// - wordId：要添加的单词的ID
  ///
  /// 返回值：
  /// - Future<void>：异步操作，无返回值
  static Future<void> addWordToWordList(int wordListId, int wordId) async {
    /// 先加载现有单词表列表
    final wordLists = await loadWordLists();

    /// 查找指定ID的单词表
    final wordList = wordLists.firstWhere(
      (wordList) => wordList.id == wordListId,
      orElse: () => WordList(id: -1, name: '默认列表'),
    );

    /// 如果找到了对应的单词表
    if (wordList.id != -1) {
      /// 将单词ID添加到单词表的wordIds列表中
      wordList.addWord(wordId);

      /// 将更新后的列表保存到文件
      await saveWordLists(wordLists);
    }
  }

  /// 从单词表中移除单词
  ///
  /// 功能：
  /// - 加载现有单词表列表
  /// - 查找指定ID的单词表
  /// - 从单词表的wordIds列表中移除指定的单词ID
  /// - 保存更新后的列表到本地文件
  ///
  /// 参数：
  /// - wordListId：单词表的ID
  /// - wordId：要移除的单词的ID
  ///
  /// 返回值：
  /// - Future<void>：异步操作，无返回值
  static Future<void> removeWordFromWordList(int wordListId, int wordId) async {
    /// 先加载现有单词表列表
    final wordLists = await loadWordLists();

    /// 查找指定ID的单词表
    final wordList = wordLists.firstWhere(
      (wordList) => wordList.id == wordListId,
      orElse: () => WordList(id: -1, name: '默认列表'),
    );

    /// 如果找到了对应的单词表
    if (wordList.id != -1) {
      /// 从单词表的wordIds列表中移除指定的单词ID
      wordList.removeWord(wordId);

      /// 将更新后的列表保存到文件
      await saveWordLists(wordLists);
    }
  }
}
