import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wei_dan_ci/pages/home_page.dart';
import 'package:wei_dan_ci/providers/study_progress_provider.dart';

void main() {
  group('HomePage Refresh Tests', () {
    testWidgets('HomePage should show loading indicator initially', (
      WidgetTester tester,
    ) async {
      // 构建HomePage并触发帧
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => StudyProgressProvider()),
          ],
          child: MaterialApp(home: HomePage()),
        ),
      );

      // 验证初始状态显示加载指示器
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('HomePage should refresh when check-in button is tapped', (
      WidgetTester tester,
    ) async {
      // 构建HomePage并触发帧
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => StudyProgressProvider()),
          ],
          child: MaterialApp(home: HomePage()),
        ),
      );

      // 等待加载完成
      await tester.pumpAndSettle(Duration(seconds: 2));

      // 查找签到按钮并点击
      final checkInButton = find.text('签到');
      if (findsOneWidget.matches(checkInButton, tester)) {
        await tester.tap(checkInButton);
        await tester.pumpAndSettle(Duration(seconds: 1));

        // 验证签到后界面应该更新（不应该再显示签到按钮）
        expect(find.text('签到'), findsNothing);
      }
    });

    testWidgets('HomePage should toggle calendar when study record card is tapped', (
      WidgetTester tester,
    ) async {
      // 构建HomePage并触发帧
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => StudyProgressProvider()),
          ],
          child: MaterialApp(home: HomePage()),
        ),
      );

      // 等待加载完成
      await tester.pumpAndSettle(Duration(seconds: 2));

      // 查找学习记录卡片并点击
      final studyRecordCard = find.text('学习记录');
      if (findsOneWidget.matches(studyRecordCard, tester)) {
        await tester.tap(studyRecordCard);
        await tester.pumpAndSettle(Duration(milliseconds: 500));

        // 验证日历视图应该显示
        expect(find.text('学习记录'), findsNothing);
        expect(find.byType(GridView), findsWidgets);
      }
    });

    testWidgets('HomePage should refresh when returning from other pages', (
      WidgetTester tester,
    ) async {
      // 构建HomePage并触发帧
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => StudyProgressProvider()),
          ],
          child: MaterialApp(home: HomePage()),
        ),
      );

      // 等待加载完成
      await tester.pumpAndSettle(Duration(seconds: 2));

      // 点击底部导航栏切换到其他页面
      final testPageButton = find.text('测试');
      await tester.tap(testPageButton);
      await tester.pumpAndSettle(Duration(milliseconds: 300));

      // 切换回学习页面
      final studyPageButton = find.text('学习');
      await tester.tap(studyPageButton);
      await tester.pumpAndSettle(Duration(milliseconds: 300));

      // 验证学习页面应该正确显示，没有加载指示器
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('学习中心'), findsOneWidget);
    });
  });
}
