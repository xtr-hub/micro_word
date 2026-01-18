import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wei_dan_ci/pages/test_page.dart';

void main() {
  group('TestPage tests', () {
    testWidgets('TestPage should show loading indicator initially', (
      WidgetTester tester,
    ) async {
      // 构建TestPage并触发帧
      await tester.pumpWidget(MaterialApp(home: TestPage()));

      // 验证加载指示器是否显示
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'TestPage should maintain loading state when loading takes time',
      (WidgetTester tester) async {
        // 构建TestPage并触发帧
        await tester.pumpWidget(MaterialApp(home: TestPage()));

        // 验证初始加载状态
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // 再次触发帧，验证加载状态保持不变
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });
}
