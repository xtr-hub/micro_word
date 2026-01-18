import 'package:flutter_test/flutter_test.dart';
import 'package:wei_dan_ci/models/word.dart';

void main() {
  group('Word model tests', () {
    test('Word should be created with correct properties', () {
      final word = Word(
        id: 1,
        word: 'test',
        meaning: '测试',
        phonetic: '/test/',
        example: 'This is a test.',
        isFavorite: true,
      );

      expect(word.id, equals(1));
      expect(word.word, equals('test'));
      expect(word.meaning, equals('测试'));
      expect(word.phonetic, equals('/test/'));
      expect(word.example, equals('This is a test.'));
      expect(word.isFavorite, equals(true));
      expect(word.status, equals(StudyStatus.newWord));
      expect(word.lastStudyTime, isNotNull);
      expect(word.memoryStrength, equals(0.0));
    });

    test('Word should update status correctly', () {
      final word = Word(id: 1, word: 'test', meaning: '测试');

      // 初始状态应该是newWord
      expect(word.status, equals(StudyStatus.newWord));

      // 更新为learning状态
      word.updateStatus(StudyStatus.learning);
      expect(word.status, equals(StudyStatus.learning));

      // 更新为familiar状态
      word.updateStatus(StudyStatus.familiar);
      expect(word.status, equals(StudyStatus.familiar));

      // 更新为mastered状态
      word.updateStatus(StudyStatus.mastered);
      expect(word.status, equals(StudyStatus.mastered));
    });

    test('Word should update memory strength correctly', () {
      final word = Word(id: 1, word: 'test', meaning: '测试');

      // 初始记忆强度应该是0.0
      expect(word.memoryStrength, equals(0.0));

      // 更新为mastered状态，记忆强度应该增加
      word.updateStatus(StudyStatus.mastered);
      expect(word.memoryStrength, greaterThan(0.0));

      // 更新为learning状态，记忆强度应该减少
      final previousStrength = word.memoryStrength;
      word.updateStatus(StudyStatus.learning);
      expect(word.memoryStrength, lessThan(previousStrength));
    });

    test('Word should update last study time when status changes', () async {
      final word = Word(id: 1, word: 'test', meaning: '测试');

      final initialTime = word.lastStudyTime;

      // 等待100毫秒，确保时间不同
      await Future.delayed(Duration(milliseconds: 100));

      // 更新状态，检查时间是否更新
      word.updateStatus(StudyStatus.learning);
      expect(word.lastStudyTime, greaterThan(initialTime));
    });
  });
}
