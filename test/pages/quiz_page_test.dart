import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wei_dan_ci/pages/quiz_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('QuizPage tests', () {
    testWidgets('QuizPage should show loading indicator initially', (
      WidgetTester tester,
    ) async {
      // 构建QuizPage并触发帧
      await tester.pumpWidget(MaterialApp(home: QuizPage()));

      // 验证加载指示器是否显示
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'QuizPage should maintain loading state when loading takes time',
      (WidgetTester tester) async {
        // 构建QuizPage并触发帧
        await tester.pumpWidget(MaterialApp(home: QuizPage()));

        // 验证初始加载状态
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // 再次触发帧，验证加载状态保持不变
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });
}
