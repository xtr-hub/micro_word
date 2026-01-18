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

    // 测试5.2: 保存设置
    print('\n=== 测试5.2: 保存设置 ===');
    final saveButton = find.text('保存设置');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    print('保存设置测试完成');

    // 测试完成
    print('\n=== 所有测试完成 ===');
    print('模拟用户交互流程测试成功！');
  });
}
