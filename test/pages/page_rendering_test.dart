import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wei_dan_ci/pages/new_home_page.dart';
import 'package:wei_dan_ci/pages/study_page.dart';
import 'package:wei_dan_ci/pages/quiz_page.dart';
import 'package:wei_dan_ci/pages/word_book_page.dart';
import 'package:wei_dan_ci/pages/settings_page.dart';
import 'package:wei_dan_ci/providers/study_progress_provider.dart';
import 'package:wei_dan_ci/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => StudyProgressProvider()),
      ],
      child: MaterialApp(home: child),
    );
  }

  // 测试NewHomePage
  testWidgets('NewHomePage should render correctly', (
    WidgetTester tester,
  ) async {
    // 构建NewHomePage并触发帧
    await tester.pumpWidget(buildTestApp(NewHomePage()));

    // 验证底部导航入口是否存在
    expect(find.text('学习'), findsOneWidget);
    expect(find.text('单词本'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
  });

  // 测试StudyPage
  testWidgets('StudyPage should render correctly', (WidgetTester tester) async {
    // 构建StudyPage并触发帧
    await tester.pumpWidget(buildTestApp(StudyPage()));

    // 验证页面是否加载
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 只触发一帧，不等待异步加载完成
    await tester.pump();
  });

  // 测试QuizPage
  testWidgets('QuizPage should render correctly', (WidgetTester tester) async {
    // 构建QuizPage并触发帧
    await tester.pumpWidget(buildTestApp(QuizPage()));

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
    await tester.pumpWidget(buildTestApp(WordBookPage()));

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
    await tester.pumpWidget(buildTestApp(SettingsPage()));

    // 验证页面是否加载
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 只触发一帧，不等待异步加载完成
    await tester.pump();
  });
}
