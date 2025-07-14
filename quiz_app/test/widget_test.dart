// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:quiz_app/main.dart';

void main() {
  testWidgets('Quiz app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QuizApp());

    // Verify that our home screen loads with the welcome text.
    expect(find.text('مرحبًا بك'), findsOneWidget);
    expect(find.text('ابدأ الاختبار'), findsOneWidget);

    // Tap the start quiz button and trigger a frame.
    await tester.tap(find.text('ابدأ الاختبار'));
    await tester.pumpAndSettle();

    // Verify that the quiz screen loads.
    expect(find.text('السؤال 1'), findsOneWidget);
  });
}
