import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wei_dan_ci/pages/new_home_page.dart';

void main() {
  group('NewHomePage tests', () {
    testWidgets('NewHomePage should render correctly with all elements', (
      WidgetTester tester,
    ) async {
      // 构建NewHomePage并触发帧
      await tester.pumpWidget(MaterialApp(home: NewHomePage()));

      // 验证页面标题是否正确显示
      expect(find.text('不背单词'), findsOneWidget);

      // 验证功能入口是否存在
      expect(find.text('开始学习'), findsOneWidget);
      expect(find.text('自我测试'), findsOneWidget);
      expect(find.text('我的单词本'), findsOneWidget);
      expect(find.text('生词本'), findsOneWidget);

      // 验证学习数据部分是否存在
      expect(find.text('学习数据'), findsOneWidget);
      expect(find.text('总单词数'), findsOneWidget);
      expect(find.text('已掌握'), findsOneWidget);
      expect(find.text('连续学习'), findsOneWidget);

      // 验证设置按钮是否存在
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('NewHomePage should have correct layout structure', (
      WidgetTester tester,
    ) async {
      // 构建NewHomePage并触发帧
      await tester.pumpWidget(MaterialApp(home: NewHomePage()));

      // 验证布局结构
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('NewHomePage should display correct app title style', (
      WidgetTester tester,
    ) async {
      // 构建NewHomePage并触发帧
      await tester.pumpWidget(MaterialApp(home: NewHomePage()));

      // 获取标题文本组件
      final titleFinder = find.text('不背单词');
      expect(titleFinder, findsOneWidget);

      // 验证标题是否为白色
      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.style?.color, equals(Colors.white));
      expect(titleWidget.style?.fontSize, equals(32.0));
      expect(titleWidget.style?.fontWeight, equals(FontWeight.bold));
    });

    testWidgets('NewHomePage should have feature cards', (
      WidgetTester tester,
    ) async {
      // 构建NewHomePage并触发帧
      await tester.pumpWidget(MaterialApp(home: NewHomePage()));

      // 验证功能卡片是否存在
      expect(find.byType(GestureDetector), findsWidgets);
    });
  });
}
