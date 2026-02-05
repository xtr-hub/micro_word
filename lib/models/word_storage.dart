/// JSON编码解码库，用于将单词列表转换为JSON字符串和从JSON字符串转换为单词列表
import 'dart:convert';

/// Flutter调试库，用于输出调试信息
import 'package:flutter/foundation.dart';

/// 跨平台存储服务
import '../services/platform_storage.dart';

/// Word模型类，定义了单词的数据结构
import 'word.dart';

/// WordList模型类，定义了单词表的数据结构
import 'word_list.dart';

/// 单词表存储服务类
import 'word_list_storage.dart';

/// 数据管理服务
import '../services/data_manager.dart';

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
      /// 使用DataManager保存单词数据
      await DataManager.instance.initialize();
      await DataManager.instance.saveWords(words);
    } catch (e) {
      /// 如果保存失败，打印错误信息
      ///
      /// 在实际应用中，可能需要更完善的错误处理（如显示错误提示给用户）
      debugPrint('保存单词数据失败: $e');
    }
  }

  /// 从数据库加载单词列表
  ///
  /// 功能：
  /// - 从数据库读取单词数据
  /// - 如果数据库中没有数据，返回默认单词列表
  ///
  /// 返回值：
  /// - Future<List<Word>>：异步操作，返回包含所有单词的列表
  static Future<List<Word>> loadWords() async {
    try {
      /// 使用DataManager加载单词数据
      await DataManager.instance.initialize();
      final words = await DataManager.instance.getAllWords();

      /// 如果数据库中没有数据，返回默认单词列表
      if (words.isEmpty) {
        final defaultWords = _getDefaultWords();

        /// 保存默认单词到数据库
        await DataManager.instance.saveWords(defaultWords);
        return defaultWords;
      }

      return words;
    } catch (e) {
      /// 如果加载失败，打印错误信息
      debugPrint('加载单词数据失败: $e');

      /// 失败时返回默认单词列表
      return _getDefaultWords();
    }
  }

  /// 重置单词数据为默认的50个单词
  ///
  /// 功能：
  /// - 删除现有的单词数据
  /// - 保存新的50个默认单词到数据库中
  /// - 用于强制更新为最新的默认单词列表
  ///
  /// 返回值：
  /// - Future<List<Word>>：异步操作，返回重置后的单词列表
  static Future<List<Word>> resetToDefaultWords() async {
    try {
      /// 初始化DataManager
      await DataManager.instance.initialize();

      /// 获取新的默认单词列表
      final defaultWords = _getDefaultWords();

      /// 保存到数据库
      await DataManager.instance.saveWords(defaultWords);

      /// 提取默认单词的ID列表
      final defaultWordIds = defaultWords.map((word) => word.id).toList();

      /// 加载所有单词表
      final wordLists = await WordListStorage.loadWordLists();

      /// 查找或创建默认单词表
      WordList defaultWordList;

      /// 尝试查找名为"默认单词表"的单词表
      final existingIndex = wordLists.indexWhere(
        (list) => list.name == '默认单词表',
      );

      if (existingIndex != -1) {
        /// 如果默认单词表存在，更新其wordIds列表为所有默认单词的ID
        defaultWordList = wordLists[existingIndex];
        defaultWordList.wordIds = defaultWordIds;

        /// 确保默认单词表被设置为当前学习内容
        defaultWordList.isCurrent = true;
      } else {
        /// 如果默认单词表不存在，创建一个新的
        defaultWordList = WordList(
          id: DateTime.now().millisecondsSinceEpoch,
          name: '默认单词表',
          isCurrent: true,
          wordIds: defaultWordIds,
        );

        /// 添加到列表中
        wordLists.add(defaultWordList);
      }

      /// 确保只有默认单词表被设置为当前学习内容
      for (final wordList in wordLists) {
        if (wordList.id != defaultWordList.id) {
          wordList.isCurrent = false;
        }
      }

      /// 保存更新后的单词表列表
      await WordListStorage.saveWordLists(wordLists);

      debugPrint('已重置为新的50个默认单词');
      debugPrint('已将所有默认单词添加到默认单词表中');
      return defaultWords;
    } catch (e) {
      /// 如果重置失败，打印错误信息
      debugPrint('重置单词数据失败: $e');
      return _getDefaultWords();
    }
  }

  /// 从JSON字符串解析单词列表
  ///
  /// 功能：
  /// - 将JSON字符串解析为单词列表
  /// - 用于从自定义单词表文件中加载单词
  ///
  /// 参数：
  /// - jsonString：包含单词数据的JSON字符串
  ///
  /// 返回值：
  /// - List<Word>：解析后的单词列表
  static List<Word> parseWordsFromJson(String jsonString) {
    try {
      final jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList.map((json) => Word.fromJson(json)).toList();
    } catch (e) {
      debugPrint('解析单词数据失败: $e');
      return [];
    }
  }

  /// 获取默认单词列表
  ///
  /// 功能：
  /// - 当没有保存的单词数据时，返回这个默认列表
  /// - 包含50个常用英文单词，用于演示和首次使用
  ///
  /// 返回值：
  /// - List<Word>：包含50个默认单词的列表
  static List<Word> _getDefaultWords() {
    /// 返回一个包含50个默认单词的列表
    return [
      // A
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
        word: 'ant',
        meaning: '蚂蚁',
        phonetic: '/ænt/',
        example: 'The ant is carrying a piece of food.',
        exampleMeaning: '蚂蚁正在搬运一块食物。',
      ),
      Word(
        id: 3,
        word: 'air',
        meaning: '空气',
        phonetic: '/er/',
        example: 'We need clean air to breathe.',
        exampleMeaning: '我们需要清洁的空气来呼吸。',
      ),
      Word(
        id: 4,
        word: 'art',
        meaning: '艺术',
        phonetic: '/ɑːrt/',
        example: 'She studies art at university.',
        exampleMeaning: '她在大学学习艺术。',
      ),
      Word(
        id: 5,
        word: 'animal',
        meaning: '动物',
        phonetic: '/ˈænɪml/',
        example: 'There are many animals in the zoo.',
        exampleMeaning: '动物园里有很多动物。',
      ),

      // B
      Word(
        id: 6,
        word: 'banana',
        meaning: '香蕉',
        phonetic: '/bəˈnɑːnə/',
        example: 'Bananas are rich in potassium.',
        exampleMeaning: '香蕉富含钾元素。',
      ),
      Word(
        id: 7,
        word: 'book',
        meaning: '书',
        phonetic: '/bʊk/',
        example: 'I read a book every night.',
        exampleMeaning: '我每天晚上读一本书。',
      ),
      Word(
        id: 8,
        word: 'bird',
        meaning: '鸟',
        phonetic: '/bɜːrd/',
        example: 'The bird is singing in the tree.',
        exampleMeaning: '鸟在树上唱歌。',
      ),
      Word(
        id: 9,
        word: 'blue',
        meaning: '蓝色的',
        phonetic: '/bluː/',
        example: 'The sky is blue today.',
        exampleMeaning: '今天的天空是蓝色的。',
      ),
      Word(
        id: 10,
        word: 'box',
        meaning: '盒子',
        phonetic: '/bɑːks/',
        example: 'Put the toys in the box.',
        exampleMeaning: '把玩具放进盒子里。',
      ),

      // C
      Word(
        id: 11,
        word: 'cherry',
        meaning: '樱桃',
        phonetic: '/ˈtʃeri/',
        example: 'The cherries are ripe now.',
        exampleMeaning: '樱桃现在成熟了。',
      ),
      Word(
        id: 12,
        word: 'cat',
        meaning: '猫',
        phonetic: '/kæt/',
        example: 'The cat is sleeping on the sofa.',
        exampleMeaning: '猫正在沙发上睡觉。',
      ),
      Word(
        id: 13,
        word: 'car',
        meaning: '汽车',
        phonetic: '/kɑːr/',
        example: 'My father drives a red car.',
        exampleMeaning: '我爸爸开一辆红色的汽车。',
      ),
      Word(
        id: 14,
        word: 'cake',
        meaning: '蛋糕',
        phonetic: '/keɪk/',
        example: 'We ate cake at the party.',
        exampleMeaning: '我们在派对上吃了蛋糕。',
      ),
      Word(
        id: 15,
        word: 'city',
        meaning: '城市',
        phonetic: '/ˈsɪti/',
        example: 'I live in a big city.',
        exampleMeaning: '我住在一个大城市里。',
      ),

      // D
      Word(
        id: 16,
        word: 'date',
        meaning: '日期；枣',
        phonetic: '/deɪt/',
        example: 'What is the date today?',
        exampleMeaning: '今天是几号？',
      ),
      Word(
        id: 17,
        word: 'dog',
        meaning: '狗',
        phonetic: '/dɔːɡ/',
        example: 'The dog is barking at the stranger.',
        exampleMeaning: '狗正在对着陌生人叫。',
      ),
      Word(
        id: 18,
        word: 'door',
        meaning: '门',
        phonetic: '/dɔːr/',
        example: 'Please close the door.',
        exampleMeaning: '请把门关上。',
      ),
      Word(
        id: 19,
        word: 'duck',
        meaning: '鸭子',
        phonetic: '/dʌk/',
        example: 'The duck is swimming in the pond.',
        exampleMeaning: '鸭子在池塘里游泳。',
      ),
      Word(
        id: 20,
        word: 'desk',
        meaning: '书桌',
        phonetic: '/desk/',
        example: 'I do my homework on the desk.',
        exampleMeaning: '我在书桌上做作业。',
      ),

      // E
      Word(
        id: 21,
        word: 'elephant',
        meaning: '大象',
        phonetic: '/ˈelɪfənt/',
        example: 'Elephants are the largest land animals.',
        exampleMeaning: '大象是最大的陆地动物。',
      ),
      Word(
        id: 22,
        word: 'egg',
        meaning: '鸡蛋',
        phonetic: '/eɡ/',
        example: 'I eat an egg for breakfast.',
        exampleMeaning: '我早餐吃一个鸡蛋。',
      ),
      Word(
        id: 23,
        word: 'eye',
        meaning: '眼睛',
        phonetic: '/aɪ/',
        example: 'He has blue eyes.',
        exampleMeaning: '他有蓝色的眼睛。',
      ),
      Word(
        id: 24,
        word: 'ear',
        meaning: '耳朵',
        phonetic: '/ɪr/',
        example: 'She has big ears.',
        exampleMeaning: '她有大耳朵。',
      ),
      Word(
        id: 25,
        word: 'eat',
        meaning: '吃',
        phonetic: '/iːt/',
        example: 'We eat dinner at 7 oclock.',
        exampleMeaning: '我们7点吃晚饭。',
      ),

      // F
      Word(
        id: 26,
        word: 'friend',
        meaning: '朋友',
        phonetic: '/frend/',
        example: 'He is my best friend.',
        exampleMeaning: '他是我最好的朋友。',
      ),
      Word(
        id: 27,
        word: 'fish',
        meaning: '鱼',
        phonetic: '/fɪʃ/',
        example: 'I like to eat fish.',
        exampleMeaning: '我喜欢吃鱼。',
      ),
      Word(
        id: 28,
        word: 'flower',
        meaning: '花',
        phonetic: '/ˈflaʊər/',
        example: 'The garden has many colorful flowers.',
        exampleMeaning: '花园里有许多五颜六色的花。',
      ),
      Word(
        id: 29,
        word: 'food',
        meaning: '食物',
        phonetic: '/fuːd/',
        example: 'We need food to live.',
        exampleMeaning: '我们需要食物来生存。',
      ),
      Word(
        id: 30,
        word: 'fly',
        meaning: '飞',
        phonetic: '/flaɪ/',
        example: 'Birds can fly in the sky.',
        exampleMeaning: '鸟能在天空中飞翔。',
      ),

      // G
      Word(
        id: 31,
        word: 'guitar',
        meaning: '吉他',
        phonetic: '/ɡɪˈtɑːr/',
        example: 'She plays the guitar very well.',
        exampleMeaning: '她吉他弹得非常好。',
      ),
      Word(
        id: 32,
        word: 'goat',
        meaning: '山羊',
        phonetic: '/ɡoʊt/',
        example: 'The goat is eating grass.',
        exampleMeaning: '山羊正在吃草。',
      ),
      Word(
        id: 33,
        word: 'green',
        meaning: '绿色的',
        phonetic: '/ɡriːn/',
        example: 'The grass is green in spring.',
        exampleMeaning: '春天的草是绿色的。',
      ),
      Word(
        id: 34,
        word: 'girl',
        meaning: '女孩',
        phonetic: '/ɡɜːrl/',
        example: 'The little girl is playing with a doll.',
        exampleMeaning: '小女孩正在玩洋娃娃。',
      ),
      Word(
        id: 35,
        word: 'glass',
        meaning: '玻璃；玻璃杯',
        phonetic: '/ɡlæs/',
        example: 'Please give me a glass of water.',
        exampleMeaning: '请给我一杯水。',
      ),

      // H
      Word(
        id: 36,
        word: 'happy',
        meaning: '快乐的',
        phonetic: '/ˈhæpi/',
        example: 'I feel happy today.',
        exampleMeaning: '我今天感到很开心。',
      ),
      Word(
        id: 37,
        word: 'house',
        meaning: '房子',
        phonetic: '/haʊs/',
        example: 'We live in a big house.',
        exampleMeaning: '我们住在一所大房子里。',
      ),
      Word(
        id: 38,
        word: 'horse',
        meaning: '马',
        phonetic: '/hɔːrs/',
        example: 'The horse can run very fast.',
        exampleMeaning: '马能跑得很快。',
      ),
      Word(
        id: 39,
        word: 'hand',
        meaning: '手',
        phonetic: '/hænd/',
        example: 'She has small hands.',
        exampleMeaning: '她有一双小手。',
      ),
      Word(
        id: 40,
        word: 'hat',
        meaning: '帽子',
        phonetic: '/hæt/',
        example: 'He is wearing a red hat.',
        exampleMeaning: '他戴着一顶红色的帽子。',
      ),

      // I-J-K
      Word(
        id: 41,
        word: 'ice',
        meaning: '冰',
        phonetic: '/aɪs/',
        example: 'The ice is melting in the sun.',
        exampleMeaning: '冰在阳光下融化。',
      ),
      Word(
        id: 42,
        word: 'jump',
        meaning: '跳',
        phonetic: '/dʒʌmp/',
        example: 'The cat can jump very high.',
        exampleMeaning: '这只猫能跳得很高。',
      ),
      Word(
        id: 43,
        word: 'king',
        meaning: '国王',
        phonetic: '/kɪŋ/',
        example: 'The king lived in a castle.',
        exampleMeaning: '国王住在城堡里。',
      ),

      // L-M-N
      Word(
        id: 44,
        word: 'lion',
        meaning: '狮子',
        phonetic: '/ˈlaɪən/',
        example: 'The lion is the king of the jungle.',
        exampleMeaning: '狮子是丛林之王。',
      ),
      Word(
        id: 45,
        word: 'moon',
        meaning: '月亮',
        phonetic: '/muːn/',
        example: 'The moon is bright tonight.',
        exampleMeaning: '今晚的月亮很明亮。',
      ),
      Word(
        id: 46,
        word: 'nose',
        meaning: '鼻子',
        phonetic: '/noʊz/',
        example: 'She has a small nose.',
        exampleMeaning: '她有一个小鼻子。',
      ),

      // O-P-Q
      Word(
        id: 47,
        word: 'orange',
        meaning: '橙子；橙色的',
        phonetic: '/ˈɔːrɪndʒ/',
        example: 'I eat an orange every morning.',
        exampleMeaning: '我每天早上吃一个橙子。',
      ),
      Word(
        id: 48,
        word: 'pencil',
        meaning: '铅笔',
        phonetic: '/ˈpensl/',
        example: 'I write with a pencil.',
        exampleMeaning: '我用铅笔写字。',
      ),
      Word(
        id: 49,
        word: 'queen',
        meaning: '女王',
        phonetic: '/kwiːn/',
        example: 'The queen lives in a palace.',
        exampleMeaning: '女王住在宫殿里。',
      ),

      // R-S-T
      Word(
        id: 50,
        word: 'rabbit',
        meaning: '兔子',
        phonetic: '/ˈræbɪt/',
        example: 'The rabbit has long ears.',
        exampleMeaning: '兔子有长长的耳朵。',
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
