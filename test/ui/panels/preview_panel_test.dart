import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dump_ui_tools/ui/panels/preview_panel.dart';
import 'package:dump_ui_tools/controllers/ui_analyzer_state.dart';
import 'package:dump_ui_tools/models/ui_element.dart';

void main() {
  group('PreviewPanel Tests', () {
    late UIAnalyzerState mockState;

    setUp(() {
      mockState = UIAnalyzerState();
    });

    testWidgets('should display empty state when no UI hierarchy is available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UIAnalyzerState>.value(
            value: mockState,
            child: const Scaffold(
              body: PreviewPanel(),
            ),
          ),
        ),
      );

      expect(find.text('No screen preview available'), findsOneWidget);
      expect(find.text('Capture UI to see screen layout'), findsOneWidget);
      expect(find.byIcon(Icons.phone_android), findsOneWidget);
    });

    testWidgets('should display preview content when UI hierarchy is available', (WidgetTester tester) async {
      // Create mock UI hierarchy
      final rootElement = UIElement(
        id: 'root',
        depth: 0,
        className: 'android.widget.FrameLayout',
        bounds: const Rect.fromLTWH(0, 0, 1080, 1920),
      );

      final childElement = UIElement(
        id: 'child',
        depth: 1,
        text: 'Test Button',
        className: 'android.widget.Button',
        bounds: const Rect.fromLTWH(100, 200, 200, 80),
        clickable: true,
      );

      rootElement.addChild(childElement);
      mockState.setUIHierarchy(rootElement);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UIAnalyzerState>.value(
            value: mockState,
            child: const Scaffold(
              body: PreviewPanel(),
            ),
          ),
        ),
      );

      // Should not show empty state
      expect(find.text('No screen preview available'), findsNothing);
      
      // Should show zoom controls
      expect(find.byIcon(Icons.zoom_in), findsOneWidget);
      expect(find.byIcon(Icons.zoom_out), findsOneWidget);
      expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
      
      // Should show InteractiveViewer for pan and zoom
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('should show zoom controls only when UI hierarchy is available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UIAnalyzerState>.value(
            value: mockState,
            child: const Scaffold(
              body: PreviewPanel(),
            ),
          ),
        ),
      );

      // Should not show zoom controls when no hierarchy
      expect(find.byIcon(Icons.zoom_in), findsNothing);
      expect(find.byIcon(Icons.zoom_out), findsNothing);
      expect(find.byIcon(Icons.center_focus_strong), findsNothing);
    });

    testWidgets('should handle element selection on tap', (WidgetTester tester) async {
      // Create mock UI hierarchy
      final rootElement = UIElement(
        id: 'root',
        depth: 0,
        className: 'android.widget.FrameLayout',
        bounds: const Rect.fromLTWH(0, 0, 1080, 1920),
      );

      final childElement = UIElement(
        id: 'child',
        depth: 1,
        text: 'Test Button',
        className: 'android.widget.Button',
        bounds: const Rect.fromLTWH(100, 200, 200, 80),
        clickable: true,
      );

      rootElement.addChild(childElement);
      mockState.setUIHierarchy(rootElement);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UIAnalyzerState>.value(
            value: mockState,
            child: const Scaffold(
              body: PreviewPanel(),
            ),
          ),
        ),
      );

      // Initially no element should be selected
      expect(mockState.selectedElement, isNull);

      // Find the preview panel and tap on it
      final previewPanel = find.byType(PreviewPanel);
      expect(previewPanel, findsOneWidget);

      // Tap in the center of the preview area
      await tester.tap(previewPanel);
      await tester.pump();

      // An element should be selected (either root or child depending on hit test)
      expect(mockState.selectedElement, isNotNull);
    });
  });

  group('UIElementsPainter Tests', () {
    testWidgets('should paint elements correctly', (WidgetTester tester) async {
      final rootElement = UIElement(
        id: 'root',
        depth: 0,
        className: 'android.widget.FrameLayout',
        bounds: const Rect.fromLTWH(0, 0, 1080, 1920),
      );

      final childElement = UIElement(
        id: 'child',
        depth: 1,
        text: 'Test Button',
        className: 'android.widget.Button',
        bounds: const Rect.fromLTWH(100, 200, 200, 80),
        clickable: true,
      );

      rootElement.addChild(childElement);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: UIElementsPainter(
                elements: [rootElement, childElement],
                selectedElement: childElement,
                hoveredElement: null,
                deviceBounds: const Rect.fromLTWH(0, 0, 1080, 1920),
                scale: 1.0,
                colorScheme: const ColorScheme.light(),
              ),
            ),
          ),
        ),
      );

      // The custom painter should be rendered
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}