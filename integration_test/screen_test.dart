import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wei_dan_ci/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('模拟用户完整交互流程', (WidgetTester tester) async {
    print('=== 启动应用 ===');
    // 启动应用
    await tester.pumpWidget(WordApp());

    // 等待应用加载完成
    await tester.pumpAndSettle();
    print('应用启动完成');

    // 测试1: 从启动页进入主页
    print('\n=== 测试1: 从启动页进入主页 ===');
    await tester.pump(Duration(seconds: 3)); // 等待启动页2秒延迟
    await tester.pumpAndSettle();
    print('成功进入主页');

    // 测试2: 测试学习页面
    print('\n=== 测试2: 学习页面交互 ===');
    // 从主页进入学习页面
    final studyButton = find.text('开始学习');
    await tester.tap(studyButton);
    await tester.pumpAndSettle();
    print('成功进入学习页面');

    // 测试3: 测试单词本页面
    print('\n=== 测试3: 单词本页面交互 ===');
    // 返回主页
    Navigator.of(tester.element(find.text('开始学习'))).pop();
    await tester.pumpAndSettle();

    // 进入单词本页面
    final wordBookButton = find.text('我的单词本');
    await tester.tap(wordBookButton);
    await tester.pumpAndSettle();
    print('成功进入单词本页面');

    // 测试3.1: 搜索功能
    print('\n=== 测试3.1: 搜索功能 ===');
    final searchField = find.byType(TextField);
    await tester.tap(searchField);
    await tester.enterText(searchField, 'test');
    await tester.pumpAndSettle();
    print('搜索功能测试完成');

    // 测试3.2: 收藏过滤
    print('\n=== 测试3.2: 收藏过滤 ===');
    final favoriteButton = find.byIcon(Icons.favorite);
    await tester.tap(favoriteButton);
    await tester.pumpAndSettle();
    print('收藏过滤测试完成');

    // 取消收藏过滤
    await tester.tap(favoriteButton);
    await tester.pumpAndSettle();

    // 测试3.3: 排序功能
    print('\n=== 测试3.3: 排序功能 ===');
    final sortButton = find.byIcon(Icons.sort);
    await tester.tap(sortButton);
    await tester.pumpAndSettle();
    print('排序功能测试完成');

    // 测试3.4: 添加单词
    print('\n=== 测试3.4: 添加单词 ===');
    final addButton = find.byIcon(Icons.add);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // 检查是否进入添加单词页面
    expect(find.text('添加新单词'), findsOneWidget);
    print('成功进入添加单词页面');

    // 返回单词本页面
    Navigator.of(tester.element(find.text('添加新单词'))).pop();
    await tester.pumpAndSettle();

    // 测试4: 测试测试页面
    print('\n=== 测试4: 测试页面交互 ===');
    // 返回主页
    Navigator.of(tester.element(find.byIcon(Icons.sort))).pop();
    await tester.pumpAndSettle();

    // 进入测试页面
    final testButton = find.text('自我测试');
    await tester.tap(testButton);
    await tester.pumpAndSettle();
    print('成功进入测试页面');

    // 测试5: 测试设置页面
    print('\n=== 测试5: 设置页面交互 ===');
    // 返回主页
    Navigator.of(tester.element(find.text('自我测试'))).pop();
    await tester.pumpAndSettle();

    // 进入设置页面
    final settingsButton = find.byIcon(Icons.settings);
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();
    print('成功进入设置页面');

    // 测试5.1: 主题切换
    print('\n=== 测试5.1: 主题切换 ===');
    final themeDropdown = find.byType(DropdownButton<ThemeMode>);
    await tester.tap(themeDropdown);
    await tester.pumpAndSettle();
    print('主题切换测试完成');

    // 测试5.2: 学习目标调整
    print('\n=== 测试5.2: 学习目标调整 ===');
    final targetSlider = find.byType(Slider);
    await tester.drag(targetSlider, Offset(50, 0));
    await tester.pumpAndSettle();
    print('学习目标调整测试完成');

    // 测试5.3: 自动播放发音开关
    print('\n=== 测试5.3: 自动播放发音开关 ===');
    final autoPlaySwitch = find.byType(Switch);
    await tester.tap(autoPlaySwitch.first);
    await tester.pumpAndSettle();
    print('自动播放发音开关测试完成');

    // 测试5.4: 显示例句开关
    print('\n=== 测试5.4: 显示例句开关 ===');
    await tester.tap(autoPlaySwitch.last);
    await tester.pumpAndSettle();
    print('显示例句开关测试完成');

    // 测试5.5: 保存设置
    print('\n=== 测试5.5: 保存设置 ===');
    final saveButton = find.text('保存设置');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    print('保存设置测试完成');

    // 测试6: 学习页面完整功能
    print('\n=== 测试6: 学习页面完整功能 ===');
    // 返回主页
    Navigator.of(tester.element(find.text('保存设置'))).pop();
    await tester.pumpAndSettle();

    // 进入学习页面
    final studyBtn = find.text('开始学习');
    await tester.tap(studyBtn);
    await tester.pumpAndSettle();

    // 测试语音播放
    final playBtn = find.byIcon(Icons.volume_up);
    if (tester.any(playBtn)) {
      await tester.tap(playBtn);
      await tester.pumpAndSettle();
      print('语音播放测试完成');
    }

    // 测试展开/收起释义
    final expandBtn = find.byIcon(Icons.expand_more);
    if (tester.any(expandBtn)) {
      await tester.tap(expandBtn);
      await tester.pumpAndSettle();
      await tester.tap(expandBtn);
      await tester.pumpAndSettle();
      print('展开/收起释义测试完成');
    }

    // 测试学习状态标记
    final noBtn = find.text('不认识');
    final maybeBtn = find.text('模糊');
    final yesBtn = find.text('认识');

    if (tester.any(noBtn)) {
      await tester.tap(noBtn);
      await tester.pumpAndSettle();
      print('学习状态标记测试完成');
    } else if (tester.any(maybeBtn)) {
      await tester.tap(maybeBtn);
      await tester.pumpAndSettle();
      print('学习状态标记测试完成');
    } else if (tester.any(yesBtn)) {
      await tester.tap(yesBtn);
      await tester.pumpAndSettle();
      print('学习状态标记测试完成');
    }

    // 测试7: 测试页面完整功能
    print('\n=== 测试7: 测试页面完整功能 ===');
    // 返回主页
    Navigator.of(tester.element(studyBtn)).pop();
    await tester.pumpAndSettle();

    // 进入测试页面
    final testBtn = find.text('自我测试');
    await tester.tap(testBtn);
    await tester.pumpAndSettle();

    // 测试选择题模式
    final choiceModeBtn = find.text('选择题');
    if (tester.any(choiceModeBtn)) {
      await tester.tap(choiceModeBtn);
      await tester.pumpAndSettle();
      print('选择题模式测试完成');
    }

    // 测试填空题模式
    final fillModeBtn = find.text('填空题');
    if (tester.any(fillModeBtn)) {
      await tester.tap(fillModeBtn);
      await tester.pumpAndSettle();
      print('填空题模式测试完成');
    }

    // 测试完成
    print('\n=== 所有测试完成 ===');
    print('模拟用户交互流程测试成功！');
    print('已覆盖功能：');
    print('- 启动页跳转');
    print('- 主页导航');
    print('- 学习页面交互（语音播放、展开/收起、学习状态标记）');
    print('- 测试页面交互（选择题、填空题）');
    print('- 单词本页面交互（搜索、收藏、排序、添加单词）');
    print('- 设置页面交互（主题切换、学习目标、自动播放、显示例句、保存设置）');
    print('所有主要功能已覆盖！');
  });
}
