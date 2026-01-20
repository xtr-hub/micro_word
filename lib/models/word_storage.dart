/// JSON编码解码库，用于将单词列表转换为JSON字符串和从JSON字符串转换为单词列表
import 'dart:convert';

/// IO库，用于文件操作（读写文件）
import 'dart:io';

/// path_provider库，用于获取应用程序文档目录（存储数据文件的位置）
import 'package:path_provider/path_provider.dart';

/// Word模型类，定义了单词的数据结构
import 'word.dart';

/// 单词存储服务类
///
/// 功能：
/// - 管理单词数据的持久化存储（保存到本地文件）
/// - 提供CRUD操作（创建、读取、更新、删除）
/// - 支持默认单词列表
///
/// 技术说明：
/// - 使用静态方法，不需要创建实例即可使用
/// - 数据存储在应用文档目录下的word_data.json文件中
/// - 使用JSON格式进行数据序列化和反序列化
class WordStorage {
  /// 保存单词数据的文件名
  ///
  /// 文件路径：应用文档目录/word_data.json
  static const String _fileName = 'word_data.json';

  /// 保存单词列表到本地文件
  ///
  /// 功能：
  /// - 将单词列表序列化为JSON字符串
  /// - 将JSON字符串写入到本地文件
  /// - 用于持久化保存所有单词数据
  ///
  /// 参数：
  /// - words：要保存的单词列表
  ///
  /// 返回值：
  /// - Future<void>：异步操作，无返回值
  static Future<void> saveWords(List<Word> words) async {
    try {
      /// 获取应用程序文档目录
      ///
      /// 应用文档目录是应用专用的存储区域，只有应用本身可以访问
      /// 数据会永久保存，直到用户卸载应用或手动清除数据
      final directory = await getApplicationDocumentsDirectory();

      /// 创建或打开单词数据文件
      final file = File('${directory.path}/$_fileName');

      /// 将单词列表转换为JSON格式
      ///
      /// 转换步骤：
      /// 1. 使用map方法遍历单词列表，将每个Word对象转换为JSON Map（调用word.toJson()）
      /// 2. 使用toList方法将结果转换为List<Map<String, dynamic>>
      /// 3. 使用json.encode将List转换为JSON字符串
      final jsonList = words.map((word) => word.toJson()).toList();
      final jsonString = json.encode(jsonList);

      /// 将JSON字符串写入文件
      await file.writeAsString(jsonString);
    } catch (e) {
      /// 如果保存失败，打印错误信息
      ///
      /// 在实际应用中，可能需要更完善的错误处理（如显示错误提示给用户）
      print('保存单词数据失败: $e');
    }
  }

  /// 从本地文件加载单词列表
  ///
  /// 功能：
  /// - 从本地文件读取JSON字符串
  /// - 将JSON字符串反序列化为单词列表
  /// - 如果文件不存在或加载失败，返回默认单词列表
  ///
  /// 返回值：
  /// - Future<List<Word>>：异步操作，返回包含所有单词的列表
  static Future<List<Word>> loadWords() async {
    try {
      /// 获取应用程序文档目录
      final directory = await getApplicationDocumentsDirectory();

      /// 创建或打开单词数据文件
      final file = File('${directory.path}/$_fileName');

      /// 检查文件是否存在
      if (!file.existsSync()) {
        /// 如果文件不存在，返回默认单词列表
        ///
        /// 首次使用应用时，会返回包含10个默认单词的列表
        return _getDefaultWords();
      }

      /// 读取文件内容，获取JSON字符串
      final jsonString = await file.readAsString();

      /// 解析JSON数据
      ///
      /// 解析步骤：
      /// 1. 使用json.decode将JSON字符串转换为List<dynamic>
      /// 2. 使用map方法遍历列表，将每个JSON Map转换为Word对象（调用Word.fromJson(json)）
      /// 3. 使用toList方法将结果转换为List<Word>
      final jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList.map((json) => Word.fromJson(json)).toList();
    } catch (e) {
      /// 如果加载失败，打印错误信息
      print('加载单词数据失败: $e');

      /// 失败时返回默认单词列表
      return _getDefaultWords();
    }
  }

  /// 获取默认单词列表
  ///
  /// 功能：
  /// - 当没有保存的单词数据时，返回这个默认列表
  /// - 包含10个常用英文单词，用于演示和首次使用
  ///
  /// 返回值：
  /// - List<Word>：包含10个默认单词的列表
  static List<Word> _getDefaultWords() {
    /// 返回一个包含10个默认单词的列表
    return [
      Word(
        id: 1,
        word: 'apple',
        meaning: '苹果',
        phonetic: '/ˈæpl/',
        example: 'I eat an apple every day.',
        exampleMeaning: '我每天吃一个苹果。',
      ),
      Word(
        id: 2,
        word: 'banana',
        meaning: '香蕉',
        phonetic: '/bəˈnɑːnə/',
        example: 'Bananas are rich in potassium.',
        exampleMeaning: '香蕉富含钾元素。',
      ),
      Word(
        id: 3,
        word: 'cherry',
        meaning: '樱桃',
        phonetic: '/ˈtʃeri/',
        example: 'The cherries are ripe now.',
        exampleMeaning: '樱桃现在成熟了。',
      ),
      Word(
        id: 4,
        word: 'date',
        meaning: '日期；枣',
        phonetic: '/deɪt/',
        example: 'What is the date today?',
        exampleMeaning: '今天是几号？',
      ),
      Word(
        id: 5,
        word: 'elephant',
        meaning: '大象',
        phonetic: '/ˈelɪfənt/',
        example: 'Elephants are the largest land animals.',
        exampleMeaning: '大象是最大的陆地动物。',
      ),
      Word(
        id: 6,
        word: 'friend',
        meaning: '朋友',
        phonetic: '/frend/',
        example: 'He is my best friend.',
        exampleMeaning: '他是我最好的朋友。',
      ),
      Word(
        id: 7,
        word: 'guitar',
        meaning: '吉他',
        phonetic: '/ɡɪˈtɑːr/',
        example: 'She plays the guitar very well.',
        exampleMeaning: '她吉他弹得非常好。',
      ),
      Word(
        id: 8,
        word: 'happy',
        meaning: '快乐的',
        phonetic: '/ˈhæpi/',
        example: 'I feel very happy today.',
        exampleMeaning: '我今天感到非常开心。',
      ),
      Word(
        id: 9,
        word: 'internet',
        meaning: '互联网',
        phonetic: '/ˈɪntərnet/',
        example: 'I use the internet every day.',
        exampleMeaning: '我每天使用互联网。',
      ),
      Word(
        id: 10,
        word: 'jungle',
        meaning: '丛林',
        phonetic: '/ˈdʒʌŋɡl/',
        example: 'Tigers live in the jungle.',
        exampleMeaning: '老虎生活在丛林中。',
      ),
    ];
  }

  /// 添加新单词到存储中
  ///
  /// 功能：
  /// - 加载现有单词列表
  /// - 将新单词添加到列表中
  /// - 保存更新后的列表到本地文件
  ///
  /// 参数：
  /// - newWord：要添加的新单词对象
  ///
  /// 返回值：
  /// - Future<void>：异步操作，无返回值
  static Future<void> addWord(Word newWord) async {
    /// 先加载现有单词列表
    final words = await loadWords();

    /// 将新单词添加到列表末尾
    words.add(newWord);

    /// 将更新后的列表保存到文件
    await saveWords(words);
  }

  /// 更新存储中的单词
  ///
  /// 功能：
  /// - 加载现有单词列表
  /// - 查找并替换指定ID的单词
  /// - 保存更新后的列表到本地文件
  ///
  /// 参数：
  /// - updatedWord：更新后的单词对象（包含最新数据）
  ///
  /// 返回值：
  /// - Future<void>：异步操作，无返回值
  static Future<void> updateWord(Word updatedWord) async {
    /// 先加载现有单词列表
    final words = await loadWords();

    /// 查找要更新的单词在列表中的索引
    ///
    /// 使用indexWhere方法查找ID匹配的单词
    /// 如果找到，返回单词在列表中的索引
    /// 如果没找到，返回-1
    final index = words.indexWhere((word) => word.id == updatedWord.id);

    /// 如果找到了对应的单词（索引不等于-1）
    if (index != -1) {
      /// 替换列表中指定索引处的单词
      words[index] = updatedWord;

      /// 将更新后的列表保存到文件
      await saveWords(words);
    }

    /// 如果没有找到，不执行任何操作
  }

  /// 从存储中删除单词
  ///
  /// 功能：
  /// - 加载现有单词列表
  /// - 删除指定ID的单词
  /// - 保存更新后的列表到本地文件
  ///
  /// 参数：
  /// - wordId：要删除的单词的ID
  ///
  /// 返回值：
  /// - Future<void>：异步操作，无返回值
  static Future<void> deleteWord(int wordId) async {
    /// 先加载现有单词列表
    final words = await loadWords();

    /// 从列表中移除ID匹配的单词
    ///
    /// 使用removeWhere方法删除所有ID匹配的单词
    /// 理论上应该只有一个匹配项，因为ID是唯一的
    words.removeWhere((word) => word.id == wordId);

    /// 将更新后的列表保存到文件
    await saveWords(words);
  }
}
