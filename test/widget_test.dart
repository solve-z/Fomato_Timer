// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fomato_timer/main.dart';

void main() {
  testWidgets('Fomato app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: FomatoApp()));

    // Verify that the app loads with bottom navigation
    expect(find.text('Fomato Timer'), findsOneWidget);
    expect(find.text('타이머'), findsOneWidget);
    expect(find.text('농장'), findsOneWidget);
    expect(find.text('통계'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
  });
}
