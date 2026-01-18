import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wei_dan_ci/pages/study_page.dart';

void main() {
  group('StudyPage tests', () {
    testWidgets('StudyPage should show loading indicator initially', (
      WidgetTester tester,
    ) async {
      // 构建StudyPage并触发帧
      await tester.pumpWidget(MaterialApp(home: StudyPage()));

      // 验证加载指示器是否显示
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'StudyPage should maintain loading state when loading takes time',
      (WidgetTester tester) async {
        // 构建StudyPage并触发帧
        await tester.pumpWidget(MaterialApp(home: StudyPage()));

        // 验证初始加载状态
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // 再次触发帧，验证加载状态保持不变
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });
}
