import 'package:flutter_test/flutter_test.dart';
import 'package:wei_dan_ci/models/study_progress.dart';

void main() {
  group('StudyProgress tests', () {
    test('StudyProgress should initialize correctly', () async {
      final progress = StudyProgress();

      expect(progress.totalWordsStudied, equals(0));
      expect(progress.masteredWords, equals(0));
      expect(progress.consecutiveDays, equals(0));
      expect(progress.totalStudyTime, equals(0));
      expect(progress.todayWordsStudied, equals(0));
      expect(progress.todayStudyTime, equals(0));
      expect(progress.dailyGoal, equals(20));
    });

    test('StudyProgress should update words studied correctly', () {
      final progress = StudyProgress();

      // 更新学习单词数（未掌握）
      progress.updateWordsStudied(5, false);
      expect(progress.totalWordsStudied, equals(5));
      expect(progress.masteredWords, equals(0));
      expect(progress.todayWordsStudied, equals(5));

      // 更新学习单词数（掌握）
      progress.updateWordsStudied(3, true);
      expect(progress.totalWordsStudied, equals(8));
      expect(progress.masteredWords, equals(3));
      expect(progress.todayWordsStudied, equals(8));
    });

    test('StudyProgress should update study time correctly', () {
      final progress = StudyProgress();

      // 更新学习时间
      progress.updateStudyTime(60); // 1分钟
      expect(progress.totalStudyTime, equals(60));
      expect(progress.todayStudyTime, equals(60));

      // 再次更新学习时间
      progress.updateStudyTime(120); // 2分钟
      expect(progress.totalStudyTime, equals(180));
      expect(progress.todayStudyTime, equals(180));
    });

    test('StudyProgress should update daily goal correctly', () {
      final progress = StudyProgress();

      // 默认目标应该是20
      expect(progress.dailyGoal, equals(20));

      // 更新目标
      progress.dailyGoal = 30;
      expect(progress.dailyGoal, equals(30));
    });

    test('StudyProgress should save and load correctly', () async {
      final progress1 = StudyProgress();

      // 更新一些数据
      progress1.updateWordsStudied(10, true);
      progress1.updateStudyTime(180);
      progress1.dailyGoal = 25;

      // 保存数据
      await progress1.save();

      // 加载数据
      final progress2 = await StudyProgress.load();

      // 验证数据是否一致
      expect(progress2.totalWordsStudied, equals(10));
      expect(progress2.masteredWords, equals(10));
      expect(progress2.totalStudyTime, equals(180));
      expect(progress2.todayWordsStudied, equals(10));
      expect(progress2.todayStudyTime, equals(180));
      expect(progress2.dailyGoal, equals(25));
    });

    test(
      'StudyProgress should reset today\'s progress when date changes',
      () async {
        final progress = StudyProgress();

        // 更新今天的进度
        progress.updateWordsStudied(5, false);
        progress.updateStudyTime(60);

        // 模拟第二天的日期（通过修改lastStudyDate）
        // 注意：这里我们需要修改内部变量，这在实际代码中可能不允许
        // 但为了测试，我们可以这样做
        final now = DateTime.now();
        final yesterday = now.subtract(Duration(days: 1));
        progress.lastStudyDate = yesterday;

        // 再次更新进度，应该重置今天的进度
        progress.updateWordsStudied(3, true);

        expect(progress.totalWordsStudied, equals(8));
        expect(progress.masteredWords, equals(3));
        expect(progress.todayWordsStudied, equals(3));
        expect(progress.consecutiveDays, equals(1)); // 连续学习天数应该增加
      },
    );
  });
}
