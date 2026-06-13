import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wei_dan_ci/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('简单测试: 启动应用并检查主页', (WidgetTester tester) async {
    print('=== 启动应用 ===');
    await tester.pumpWidget(WordApp());
    await tester.pumpAndSettle();

    print('=== 等待启动页 ===');
    await tester.pump(Duration(seconds: 3));
    await tester.pumpAndSettle();

    print('=== 检查主页元素 ===');
    // 检查主页是否有'开始学习'按钮
    final studyButton = find.text('开始学习');
    expect(studyButton, findsOneWidget);
    print('成功找到主页按钮: 开始学习');

    print('=== 测试完成 ===');
  });
}
