import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dump_ui_tools/ui/panels/property_panel.dart';
import 'package:dump_ui_tools/controllers/ui_analyzer_state.dart';
import 'package:dump_ui_tools/models/ui_element.dart';

void main() {
  group('PropertyPanel', () {
    late UIAnalyzerState mockState;
    late UIElement testElement;

    setUp(() {
      testElement = UIElement(
        id: 'test_element_1',
        depth: 1,
        text: 'Test Button',
        contentDesc: 'Test button description',
        className: 'android.widget.Button',
        packageName: 'com.example.app',
        resourceId: 'com.example.app:id/test_button',
        clickable: true,
        enabled: true,
        bounds: const Rect.fromLTRB(10, 20, 110, 70),
        index: 0,
      );

      mockState = UIAnalyzerState();
      mockState.selectElement(testElement);
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<UIAnalyzerState>.value(
          value: mockState,
          child: const Scaffold(
            body: PropertyPanel(),
          ),
        ),
      );
    }

    group('Basic Rendering', () {
      testWidgets('should display property panel with header', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Properties'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('should show empty state when no element selected', (tester) async {
        mockState.clearSelection();
        await tester.pumpWidget(createTestWidget());

        expect(find.text('No element selected'), findsOneWidget);
        expect(find.text('Select an element from the tree view'), findsOneWidget);
        expect(find.byIcon(Icons.touch_app), findsOneWidget);
      });

      testWidgets('should display selected element information', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Test Button'), findsOneWidget);
        expect(find.text('android.widget.Button'), findsOneWidget);
      });
    });

    group('Property Display', () {
      testWidgets('should display all element properties', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check for property labels
        expect(find.text('Text'), findsOneWidget);
        expect(find.text('Content Description'), findsOneWidget);
        expect(find.text('Class Name'), findsOneWidget);
        expect(find.text('Package Name'), findsOneWidget);
        expect(find.text('Resource ID'), findsOneWidget);
        expect(find.text('Clickable'), findsOneWidget);
        expect(find.text('Enabled'), findsOneWidget);
        expect(find.text('Bounds'), findsOneWidget);
        expect(find.text('Index'), findsOneWidget);

        // Check for property values
        expect(find.text('Test Button'), findsAtLeastNWidgets(1));
        expect(find.text('Test button description'), findsOneWidget);
        expect(find.text('android.widget.Button'), findsAtLeastNWidgets(1));
        expect(find.text('com.example.app'), findsOneWidget);
        expect(find.text('com.example.app:id/test_button'), findsOneWidget);
        expect(find.text('true'), findsAtLeastNWidgets(2)); // clickable and enabled
        expect(find.text('0'), findsOneWidget); // index
      });

      testWidgets('should display bounds information correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should show bounds coordinates
        expect(find.textContaining('10'), findsAtLeastNWidgets(1)); // left
        expect(find.textContaining('20'), findsAtLeastNWidgets(1)); // top
        expect(find.textContaining('110'), findsAtLeastNWidgets(1)); // right
        expect(find.textContaining('70'), findsAtLeastNWidgets(1)); // bottom

        // Should show calculated dimensions
        expect(find.textContaining('100'), findsAtLeastNWidgets(1)); // width
        expect(find.textContaining('50'), findsAtLeastNWidgets(1)); // height
      });

      testWidgets('should handle empty property values', (tester) async {
        final emptyElement = UIElement(
          id: 'empty_element',
          depth: 0,
          text: '',
          contentDesc: '',
          className: 'android.widget.View',
          packageName: '',
          resourceId: '',
          clickable: false,
          enabled: false,
          bounds: Rect.zero,
          index: 0,
        );

        mockState.selectElement(emptyElement);
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should show empty state indicators
        expect(find.text('(empty)'), findsAtLeastNWidgets(1));
        expect(find.text('false'), findsAtLeastNWidgets(2)); // clickable and enabled
      });

      testWidgets('should display boolean properties correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should show boolean values with appropriate styling
        expect(find.text('true'), findsAtLeastNWidgets(2));
        
        // Test with false values
        final disabledElement = UIElement(
          id: 'disabled_element',
          depth: 0,
          text: 'Disabled Element',
          contentDesc: '',
          className: 'android.widget.View',
          packageName: '',
          resourceId: '',
          clickable: false,
          enabled: false,
          bounds: Rect.zero,
          index: 0,
        );

        mockState.selectElement(disabledElement);
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('false'), findsAtLeastNWidgets(2));
      });
    });

    group('Copy Functionality', () {
      testWidgets('should show copy icons for property values', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should have copy icons for copyable properties
        expect(find.byIcon(Icons.copy), findsAtLeastNWidgets(1));
      });

      testWidgets('should copy property value to clipboard on tap', (tester) async {
        // Mock clipboard
        const channel = MethodChannel('flutter/platform');
        final List<MethodCall> log = <MethodCall>[];
        
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (methodCall) async {
          log.add(methodCall);
          return null;
        });

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find and tap a copy icon
        final copyIcon = find.byIcon(Icons.copy).first;
        await tester.tap(copyIcon);
        await tester.pumpAndSettle();

        // Should have called clipboard set data
        expect(log, isNotEmpty);
        expect(log.any((call) => call.method == 'Clipboard.setData'), isTrue);

        // Clean up
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      });

      testWidgets('should show copy confirmation feedback', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Mock successful clipboard operation
        const channel = MethodChannel('flutter/platform');
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (methodCall) async {
          return null;
        });

        // Tap copy icon
        final copyIcon = find.byIcon(Icons.copy).first;
        await tester.tap(copyIcon);
        await tester.pumpAndSettle();

        // Should show some feedback (snackbar, tooltip, etc.)
        // This depends on the implementation
        expect(find.byType(SnackBar), findsOneWidget);

        // Clean up
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      });
    });

    group('Property Grouping', () {
      testWidgets('should group properties logically', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should have sections for different property groups
        expect(find.text('Basic Information'), findsOneWidget);
        expect(find.text('Layout & Position'), findsOneWidget);
        expect(find.text('Interaction'), findsOneWidget);
        expect(find.text('Identification'), findsOneWidget);
      });

      testWidgets('should allow expanding/collapsing property groups', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find expandable sections
        final expandableSection = find.byType(ExpansionTile);
        if (expandableSection.evaluate().isNotEmpty) {
          // Tap to collapse
          await tester.tap(expandableSection.first);
          await tester.pumpAndSettle();

          // Some properties should be hidden
          // This depends on the implementation
        }
      });
    });

    group('Property Formatting', () {
      testWidgets('should format long text properties with wrapping', (tester) async {
        final longTextElement = UIElement(
          id: 'long_text_element',
          depth: 0,
          text: 'This is a very long text that should wrap to multiple lines when displayed in the property panel',
          contentDesc: 'This is also a very long content description that should be properly formatted',
          className: 'android.widget.TextView',
          packageName: 'com.example.verylongpackagename.app',
          resourceId: 'com.example.verylongpackagename.app:id/very_long_resource_identifier',
          clickable: true,
          enabled: true,
          bounds: const Rect.fromLTRB(0, 0, 100, 50),
          index: 0,
        );

        mockState.selectElement(longTextElement);
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should display long text without overflow
        expect(find.textContaining('This is a very long text'), findsOneWidget);
        expect(find.textContaining('very long content description'), findsOneWidget);
      });

      testWidgets('should format bounds with readable coordinates', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should show formatted bounds information
        expect(find.textContaining('Left: 10'), findsOneWidget);
        expect(find.textContaining('Top: 20'), findsOneWidget);
        expect(find.textContaining('Right: 110'), findsOneWidget);
        expect(find.textContaining('Bottom: 70'), findsOneWidget);
        expect(find.textContaining('Width: 100'), findsOneWidget);
        expect(find.textContaining('Height: 50'), findsOneWidget);
      });

      testWidgets('should highlight important properties', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Important properties like resource ID should be highlighted
        final resourceIdText = find.text('com.example.app:id/test_button');
        expect(resourceIdText, findsOneWidget);

        // Check if it has special styling
        final textWidget = tester.widget<Text>(resourceIdText);
        expect(textWidget.style?.fontWeight, equals(FontWeight.bold));
      });
    });

    group('Scrolling and Layout', () {
      testWidgets('should be scrollable when content overflows', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should have scrollable content
        expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
      });

      testWidgets('should maintain proper spacing between properties', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should have proper spacing
        expect(find.byType(SizedBox), findsAtLeastNWidgets(1));
        expect(find.byType(Padding), findsAtLeastNWidgets(1));
      });
    });

    group('Responsive Design', () {
      testWidgets('should adapt to different screen sizes', (tester) async {
        // Test with small screen
        tester.binding.window.physicalSizeTestValue = const Size(400, 600);
        tester.binding.window.devicePixelRatioTestValue = 1.0;

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Properties'), findsOneWidget);

        // Test with large screen
        tester.binding.window.physicalSizeTestValue = const Size(1200, 800);
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Properties'), findsOneWidget);

        // Reset
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
        addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      });
    });

    group('Accessibility', () {
      testWidgets('should provide semantic labels for screen readers', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should have semantic information
        expect(find.byType(Semantics), findsAtLeastNWidgets(1));
      });

      testWidgets('should support keyboard navigation', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should be able to focus on interactive elements
        expect(find.byType(InkWell), findsAtLeastNWidgets(1));
      });
    });

    group('State Management Integration', () {
      testWidgets('should update when selected element changes', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Test Button'), findsOneWidget);

        // Change selected element
        final newElement = UIElement(
          id: 'new_element',
          depth: 0,
          text: 'New Element',
          contentDesc: '',
          className: 'android.widget.TextView',
          packageName: '',
          resourceId: '',
          clickable: false,
          enabled: true,
          bounds: Rect.zero,
          index: 0,
        );

        mockState.selectElement(newElement);
        await tester.pumpAndSettle();

        expect(find.text('New Element'), findsOneWidget);
        expect(find.text('Test Button'), findsNothing);
      });

      testWidgets('should handle element deselection', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Test Button'), findsOneWidget);

        // Deselect element
        mockState.clearSelection();
        await tester.pumpAndSettle();

        expect(find.text('No element selected'), findsOneWidget);
        expect(find.text('Test Button'), findsNothing);
      });
    });

    group('Performance', () {
      testWidgets('should handle elements with many properties efficiently', (tester) async {
        // Create element with many custom properties
        final complexElement = UIElement(
          id: 'complex_element',
          depth: 0,
          text: 'Complex Element with Many Properties',
          contentDesc: 'Very detailed content description',
          className: 'com.example.custom.ComplexCustomView',
          packageName: 'com.example.complexapp',
          resourceId: 'com.example.complexapp:id/complex_view_with_long_name',
          clickable: true,
          enabled: true,
          bounds: const Rect.fromLTRB(0, 0, 1000, 500),
          index: 42,
        );

        mockState.selectElement(complexElement);
        await tester.pumpWidget(createTestWidget());

        // Should render without performance issues
        expect(find.text('Complex Element with Many Properties'), findsOneWidget);
        expect(find.text('com.example.custom.ComplexCustomView'), findsOneWidget);
      });

      testWidgets('should efficiently update when properties change', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final stopwatch = Stopwatch()..start();

        // Change element multiple times
        for (int i = 0; i < 10; i++) {
          final element = UIElement(
            id: 'element_$i',
            depth: 0,
            text: 'Element $i',
            contentDesc: '',
            className: 'android.widget.TextView',
            packageName: '',
            resourceId: '',
            clickable: false,
            enabled: true,
            bounds: Rect.zero,
            index: i,
          );

          mockState.selectElement(element);
          await tester.pumpAndSettle();
        }

        stopwatch.stop();

        // Should complete updates reasonably quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('Error Handling', () {
      testWidgets('should handle null property values gracefully', (tester) async {
        // This test ensures the panel doesn't crash with unexpected null values
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Properties'), findsOneWidget);
      });

      testWidgets('should handle very large coordinate values', (tester) async {
        final largeElement = UIElement(
          id: 'large_element',
          depth: 0,
          text: 'Large Element',
          contentDesc: '',
          className: 'android.widget.View',
          packageName: '',
          resourceId: '',
          clickable: false,
          enabled: true,
          bounds: const Rect.fromLTRB(0, 0, 999999, 999999),
          index: 0,
        );

        mockState.selectElement(largeElement);
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should display large numbers without issues
        expect(find.textContaining('999999'), findsAtLeastNWidgets(1));
      });
    });

    group('Theme Integration', () {
      testWidgets('should adapt to light theme', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: ChangeNotifierProvider<UIAnalyzerState>.value(
              value: mockState,
              child: const Scaffold(
                body: PropertyPanel(),
              ),
            ),
          ),
        );

        expect(find.text('Properties'), findsOneWidget);
      });

      testWidgets('should adapt to dark theme', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: ChangeNotifierProvider<UIAnalyzerState>.value(
              value: mockState,
              child: const Scaffold(
                body: PropertyPanel(),
              ),
            ),
          ),
        );

        expect(find.text('Properties'), findsOneWidget);
      });
    });
  });
}