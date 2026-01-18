import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wei_dan_ci/pages/settings_page.dart';

void main() {
  group('SettingsPage tests', () {
    testWidgets('SettingsPage should show loading indicator initially', (
      WidgetTester tester,
    ) async {
      // 构建SettingsPage并触发帧
      await tester.pumpWidget(MaterialApp(home: SettingsPage()));

      // 验证加载指示器是否显示
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'SettingsPage should maintain loading state when loading takes time',
      (WidgetTester tester) async {
        // 构建SettingsPage并触发帧
        await tester.pumpWidget(MaterialApp(home: SettingsPage()));

        // 验证初始加载状态
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // 再次触发帧，验证加载状态保持不变
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });
}
