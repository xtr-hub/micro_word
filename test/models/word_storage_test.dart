import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wei_dan_ci/models/word.dart';
import 'package:wei_dan_ci/services/word_storage.dart';

void main() {
  // 初始化Flutter绑定
  WidgetsFlutterBinding.ensureInitialized();

  group('WordStorage tests', () {
    test('Verify test words were added successfully', () async {
      // 加载当前单词列表
      final words = await WordStorage.loadWords();

      // 打印单词数量
      print('Current total words: ${words.length}');

      // 检查是否有至少50个单词
      expect(words.length, greaterThanOrEqualTo(50));

      // 检查是否包含特定测试单词
      final testWords = ['apple', 'banana', 'cherry', 'dog', 'cat', 'elephant'];
      for (final testWord in testWords) {
        final found = words.any((word) => word.word.toLowerCase() == testWord);
        expect(found, isTrue, reason: 'Test word "$testWord" not found');
        print('✓ Found test word: $testWord');
      }

      print('All test words found successfully! Total words: ${words.length}');
    });

    test('WordStorage should add and save words correctly', () async {
      // 创建一个测试单词
      final testWord = Word(
        id: 1,
        word: 'test',
        meaning: '测试',
        phonetic: '/test/',
        example: 'This is a test.',
      );

      // 添加单词
      await WordStorage.addWord(testWord);

      // 加载单词列表
      final words = await WordStorage.loadWords();

      // 验证单词是否添加成功
      expect(words.isNotEmpty, isTrue);
      expect(words.any((word) => word.word == 'test'), isTrue);
    });

    test('WordStorage should save words correctly', () async {
      // 创建多个测试单词
      final testWords = [
        Word(id: 1, word: 'test1', meaning: '测试1'),
        Word(id: 2, word: 'test2', meaning: '测试2'),
      ];

      // 保存单词列表
      await WordStorage.saveWords(testWords);

      // 加载单词列表
      final loadedWords = await WordStorage.loadWords();

      // 验证单词是否保存成功
      expect(loadedWords.length, equals(2));
      expect(loadedWords[0].word, equals('test1'));
      expect(loadedWords[1].word, equals('test2'));
    });

    test('WordStorage should load words correctly', () async {
      // 首先保存一些单词
      final testWords = [Word(id: 1, word: 'load_test', meaning: '加载测试')];
      await WordStorage.saveWords(testWords);

      // 然后加载单词
      final loadedWords = await WordStorage.loadWords();

      // 验证加载结果
      expect(loadedWords.isNotEmpty, isTrue);
      expect(loadedWords[0].word, equals('load_test'));
      expect(loadedWords[0].meaning, equals('加载测试'));
    });

    test('WordStorage should handle empty word list correctly', () async {
      // 保存空列表
      await WordStorage.saveWords([]);

      // 加载单词列表
      final words = await WordStorage.loadWords();

      // 验证列表是否为空
      expect(words.isEmpty, isTrue);
    });

    test('WordStorage should update existing words correctly', () async {
      // 首先添加一个单词
      final initialWord = Word(id: 1, word: 'update_test', meaning: '初始含义');
      await WordStorage.saveWords([initialWord]);

      // 然后加载并更新这个单词
      final words = await WordStorage.loadWords();
      final updatedWord = Word(
        id: words[0].id,
        word: words[0].word,
        meaning: '更新后的含义',
        phonetic: '/update/',
      );
      words[0] = updatedWord;
      await WordStorage.saveWords(words);

      // 最后加载并验证更新结果
      final finalWords = await WordStorage.loadWords();
      expect(finalWords[0].meaning, equals('更新后的含义'));
      expect(finalWords[0].phonetic, equals('/update/'));
    });
  });
}
