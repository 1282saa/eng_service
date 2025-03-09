// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_english_app/main.dart';

void main() {
  testWidgets('App starts with login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp()); // MyEnglishLearningApp을 MyApp으로 변경

    // Verify that login screen elements are present
    expect(find.text('EnglishBoost'), findsOneWidget);
    expect(find.text('비즈니스 영어와 토익을 한번에'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('Google로 계속하기'), findsOneWidget);
  });
}