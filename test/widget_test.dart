// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dump_ui_tools/main.dart';

void main() {
  testWidgets('UI Analyzer app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const UIAnalyzerApp());

    // Verify that our app content is displayed.
    expect(find.text('Ready to analyze Android UI hierarchy'), findsOneWidget);
    expect(find.byIcon(Icons.android), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
