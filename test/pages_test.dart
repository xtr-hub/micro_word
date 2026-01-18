import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wei_dan_ci/pages/new_home_page.dart';
import 'package:wei_dan_ci/pages/study_page.dart';
import 'package:wei_dan_ci/pages/test_page.dart';
import 'package:wei_dan_ci/pages/word_book_page.dart';
import 'package:wei_dan_ci/pages/settings_page.dart';

void main() {
  // 测试NewHomePage
  testWidgets('NewHomePage should render correctly', (
    WidgetTester tester,
  ) async {
    // 构建NewHomePage并触发帧
    await tester.pumpWidget(MaterialApp(home: NewHomePage()));

    // 验证页面标题是否正确
    expect(find.text('不背单词'), findsOneWidget);

    // 验证功能入口是否存在
    expect(find.text('开始学习'), findsOneWidget);
    expect(find.text('自我测试'), findsOneWidget);
    expect(find.text('我的单词本'), findsOneWidget);
    expect(find.text('生词本'), findsOneWidget);

    // 验证学习数据部分是否存在
    expect(find.text('学习数据'), findsOneWidget);
  });

  // 测试StudyPage
  testWidgets('StudyPage should render correctly', (WidgetTester tester) async {
    // 构建StudyPage并触发帧
    await tester.pumpWidget(MaterialApp(home: StudyPage()));

    // 验证页面是否加载
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 只触发一帧，不等待异步加载完成
    await tester.pump();
  });

  // 测试TestPage
  testWidgets('TestPage should render correctly', (WidgetTester tester) async {
    // 构建TestPage并触发帧
    await tester.pumpWidget(MaterialApp(home: TestPage()));

    // 验证页面是否加载
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 只触发一帧，不等待异步加载完成
    await tester.pump();
  });

  // 测试WordBookPage
  testWidgets('WordBookPage should render correctly', (
    WidgetTester tester,
  ) async {
    // 构建WordBookPage并触发帧
    await tester.pumpWidget(MaterialApp(home: WordBookPage()));

    // 验证页面是否加载
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 只触发一帧，不等待异步加载完成
    await tester.pump();
  });

  // 测试SettingsPage
  testWidgets('SettingsPage should render correctly', (
    WidgetTester tester,
  ) async {
    // 构建SettingsPage并触发帧
    await tester.pumpWidget(MaterialApp(home: SettingsPage()));

    // 验证页面是否加载
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 只触发一帧，不等待异步加载完成
    await tester.pump();
  });
}
