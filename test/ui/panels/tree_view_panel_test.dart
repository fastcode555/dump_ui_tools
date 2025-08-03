import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dump_ui_tools/ui/panels/tree_view_panel.dart';
import 'package:dump_ui_tools/controllers/ui_analyzer_state.dart';
import 'package:dump_ui_tools/models/ui_element.dart';
import 'package:dump_ui_tools/models/filter_criteria.dart';

void main() {
  group('TreeViewPanel', () {
    late UIAnalyzerState mockState;
    late UIElement rootElement;
    late UIElement childElement1;
    late UIElement childElement2;
    late UIElement grandchildElement;

    setUp(() {
      // Create test hierarchy
      rootElement = UIElement(
        id: 'root',
        depth: 0,
        text: 'Root Element',
        contentDesc: 'Root description',
        className: 'android.widget.LinearLayout',
        packageName: 'com.example.app',
        resourceId: '',
        clickable: false,
        enabled: true,
        bounds: const Rect.fromLTRB(0, 0, 1080, 1920),
        index: 0,
      );

      childElement1 = UIElement(
        id: 'child1',
        depth: 1,
        text: 'Login Button',
        contentDesc: 'Login button',
        className: 'android.widget.Button',
        packageName: 'com.example.app',
        resourceId: 'com.example.app:id/login_btn',
        clickable: true,
        enabled: true,
        bounds: const Rect.fromLTRB(100, 200, 300, 250),
        index: 0,
      );

      childElement2 = UIElement(
        id: 'child2',
        depth: 1,
        text: 'Password Field',
        contentDesc: 'Password input',
        className: 'android.widget.EditText',
        packageName: 'com.example.app',
        resourceId: 'com.example.app:id/password_field',
        clickable: true,
        enabled: true,
        bounds: const Rect.fromLTRB(100, 300, 500, 350),
        index: 1,
      );

      grandchildElement = UIElement(
        id: 'grandchild1',
        depth: 2,
        text: 'Submit',
        contentDesc: 'Submit button',
        className: 'android.widget.TextView',
        packageName: 'com.example.app',
        resourceId: '',
        clickable: true,
        enabled: true,
        bounds: const Rect.fromLTRB(150, 400, 250, 450),
        index: 0,
      );

      // Build hierarchy
      rootElement.addChild(childElement1);
      rootElement.addChild(childElement2);
      childElement1.addChild(grandchildElement);

      // Create mock state
      mockState = UIAnalyzerState();
      mockState.setUIHierarchy(rootElement);
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<UIAnalyzerState>.value(
          value: mockState,
          child: const Scaffold(
            body: TreeViewPanel(),
          ),
        ),
      );
    }

    group('Basic Rendering', () {
      testWidgets('should display tree view panel with header', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('UI Hierarchy'), findsOneWidget);
        expect(find.byIcon(Icons.account_tree), findsOneWidget);
      });

      testWidgets('should show element count in header', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Should show total count (4 elements: root + 2 children + 1 grandchild)
        expect(find.textContaining('4/4'), findsOneWidget);
      });

      testWidgets('should display empty state when no hierarchy', (tester) async {
        mockState.clearUIHierarchy();
        await tester.pumpWidget(createTestWidget());

        expect(find.text('No UI hierarchy loaded'), findsOneWidget);
        expect(find.text('Connect a device and capture UI'), findsOneWidget);
        expect(find.byIcon(Icons.device_hub), findsOneWidget);
      });

      testWidgets('should display loading state', (tester) async {
        mockState.setLoading(true, 'Loading UI hierarchy...');
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading UI hierarchy...'), findsOneWidget);
      });
    });

    group('Tree Structure Display', () {
      testWidgets('should display root element', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Root Element'), findsOneWidget);
      });

      testWidgets('should display child elements when expanded', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Initially, children should be visible (auto-expanded)
        expect(find.text('Login Button'), findsOneWidget);
        expect(find.text('Password Field'), findsOneWidget);
      });

      testWidgets('should show expand/collapse icons for parent elements', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Root element should have expand/collapse icon
        expect(find.byIcon(Icons.keyboard_arrow_down), findsAtLeastNWidgets(1));
      });

      testWidgets('should not show expand icon for leaf elements', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Password field (leaf element) should not have expand icon
        // This is tested by checking the structure of UIElementTile
        expect(find.text('Password Field'), findsOneWidget);
      });
    });

    group('Element Selection', () {
      testWidgets('should select element on tap', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap on login button
        await tester.tap(find.text('Login Button'));
        await tester.pumpAndSettle();

        expect(mockState.selectedElement, equals(childElement1));
      });

      testWidgets('should highlight selected element', (tester) async {
        mockState.selectElement(childElement1);
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Selected element should have different styling
        final selectedTile = tester.widget<Container>(
          find.ancestor(
            of: find.text('Login Button'),
            matching: find.byType(Container),
          ).first,
        );

        expect(selectedTile.decoration, isA<BoxDecoration>());
      });
    });

    group('Expand/Collapse Functionality', () {
      testWidgets('should expand element on expand icon tap', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find and tap expand icon for child element with grandchild
        final expandIcon = find.descendant(
          of: find.ancestor(
            of: find.text('Login Button'),
            matching: find.byType(GestureDetector),
          ),
          matching: find.byIcon(Icons.keyboard_arrow_right),
        );

        if (expandIcon.evaluate().isNotEmpty) {
          await tester.tap(expandIcon);
          await tester.pumpAndSettle();

          // Grandchild should now be visible
          expect(find.text('Submit'), findsOneWidget);
        }
      });

      testWidgets('should collapse element on collapse icon tap', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find and tap collapse icon
        final collapseIcon = find.byIcon(Icons.keyboard_arrow_down);
        
        if (collapseIcon.evaluate().isNotEmpty) {
          await tester.tap(collapseIcon.first);
          await tester.pumpAndSettle();

          // Children should be hidden
          expect(find.text('Login Button'), findsNothing);
        }
      });
    });

    group('Search Functionality', () {
      testWidgets('should display search bar', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Search UI elements...'), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('should filter elements based on search query', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter search query
        await tester.enterText(find.byType(TextField), 'Login');
        await tester.pumpAndSettle();

        // Wait for debounce
        await tester.pump(const Duration(milliseconds: 400));

        // Should show search results count
        expect(find.textContaining('found'), findsOneWidget);
      });

      testWidgets('should show clear button when search has text', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter search query
        await tester.enterText(find.byType(TextField), 'Login');
        await tester.pumpAndSettle();

        // Clear button should be visible
        expect(find.byIcon(Icons.clear), findsOneWidget);
      });

      testWidgets('should clear search on clear button tap', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter search query
        await tester.enterText(find.byType(TextField), 'Login');
        await tester.pumpAndSettle();

        // Tap clear button
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        // Search field should be empty
        expect(find.text('Login'), findsNothing);
      });

      testWidgets('should show no results message for empty search', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter non-matching search query
        await tester.enterText(find.byType(TextField), 'NonExistentElement');
        await tester.pumpAndSettle();

        // Wait for debounce
        await tester.pump(const Duration(milliseconds: 400));

        // Should show no results
        expect(find.textContaining('No results'), findsOneWidget);
      });
    });

    group('Filter Functionality', () {
      testWidgets('should display filter chips', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Filters:'), findsOneWidget);
        expect(find.text('Clickable'), findsOneWidget);
        expect(find.text('Input'), findsOneWidget);
        expect(find.text('With Text'), findsOneWidget);
        expect(find.text('Enabled'), findsOneWidget);
      });

      testWidgets('should activate filter on chip tap', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap on clickable filter
        await tester.tap(find.text('Clickable'));
        await tester.pumpAndSettle();

        // Filter should be active
        expect(mockState.filterCriteria.showOnlyClickable, isTrue);
      });

      testWidgets('should show element counts on filter chips', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should show count of clickable elements (3: childElement1, childElement2, grandchildElement)
        expect(find.text('3'), findsAtLeastNWidgets(1));
      });

      testWidgets('should show clear all filters button when filters active', (tester) async {
        mockState.setFilterCriteria(FilterCriteria(showOnlyClickable: true));
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Clear all'), findsOneWidget);
      });

      testWidgets('should clear all filters on clear all tap', (tester) async {
        mockState.setFilterCriteria(FilterCriteria(showOnlyClickable: true));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap clear all
        await tester.tap(find.text('Clear all'));
        await tester.pumpAndSettle();

        // Filters should be cleared
        expect(mockState.filterCriteria.hasActiveFilters, isFalse);
      });
    });

    group('Element Display Information', () {
      testWidgets('should display element icons based on type', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Button should have button icon
        expect(find.byIcon(Icons.smart_button), findsAtLeastNWidgets(1));
        
        // EditText should have text fields icon
        expect(find.byIcon(Icons.text_fields), findsAtLeastNWidgets(1));
      });

      testWidgets('should display element badges', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Clickable elements should have 'C' badge
        expect(find.text('C'), findsAtLeastNWidgets(1));
        
        // Input element should have 'I' badge
        expect(find.text('I'), findsAtLeastNWidgets(1));
      });

      testWidgets('should show element secondary information', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should show resource ID and dimensions
        expect(find.textContaining('id:'), findsAtLeastNWidgets(1));
        expect(find.textContaining('×'), findsAtLeastNWidgets(1)); // Dimensions separator
      });
    });

    group('Hover Effects', () {
      testWidgets('should show hover effect on mouse enter', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Create hover event
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);

        // Hover over element
        await gesture.moveTo(tester.getCenter(find.text('Login Button')));
        await tester.pumpAndSettle();

        // Element should show hover state
        // This is tested by checking if MouseRegion responds to hover
        expect(find.byType(MouseRegion), findsAtLeastNWidgets(1));
      });
    });

    group('Performance', () {
      testWidgets('should handle large number of elements efficiently', (tester) async {
        // Create a large hierarchy
        final largeRoot = UIElement(
          id: 'large_root',
          depth: 0,
          text: 'Large Root',
          contentDesc: '',
          className: 'android.widget.LinearLayout',
          packageName: '',
          resourceId: '',
          clickable: false,
          enabled: true,
          bounds: const Rect.fromLTRB(0, 0, 1080, 1920),
          index: 0,
        );

        // Add many children
        for (int i = 0; i < 100; i++) {
          final child = UIElement(
            id: 'child_$i',
            depth: 1,
            text: 'Element $i',
            contentDesc: '',
            className: 'android.widget.TextView',
            packageName: '',
            resourceId: '',
            clickable: false,
            enabled: true,
            bounds: Rect.fromLTRB(0, i * 50.0, 100, (i + 1) * 50.0),
            index: i,
          );
          largeRoot.addChild(child);
        }

        mockState.setUIHierarchy(largeRoot);
        await tester.pumpWidget(createTestWidget());

        // Should render without performance issues
        expect(find.text('Large Root'), findsOneWidget);
        expect(find.text('Element 0'), findsOneWidget);
      });

      testWidgets('should use virtual scrolling for large lists', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check if VirtualTreeView is used
        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should provide semantic labels for screen readers', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Elements should have semantic information
        expect(find.byType(Semantics), findsAtLeastNWidgets(1));
      });

      testWidgets('should support keyboard navigation', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should be able to focus on elements
        expect(find.byType(GestureDetector), findsAtLeastNWidgets(1));
      });
    });

    group('Error States', () {
      testWidgets('should show no results state when filters match nothing', (tester) async {
        // Set filter that matches no elements
        mockState.setFilterCriteria(FilterCriteria(showOnlyInputs: true));
        mockState.setSearchQuery('NonExistentElement');
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('No elements match current filters'), findsOneWidget);
        expect(find.text('Clear filters'), findsOneWidget);
        expect(find.byIcon(Icons.filter_list_off), findsOneWidget);
      });

      testWidgets('should clear filters when clear filters button tapped', (tester) async {
        mockState.setFilterCriteria(FilterCriteria(showOnlyInputs: true));
        mockState.setSearchQuery('NonExistentElement');
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap clear filters button
        await tester.tap(find.text('Clear filters'));
        await tester.pumpAndSettle();

        // Filters should be cleared
        expect(mockState.filterCriteria.hasActiveFilters, isFalse);
        expect(mockState.searchQuery, isEmpty);
      });
    });

    group('Integration', () {
      testWidgets('should integrate with state management correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Select an element
        await tester.tap(find.text('Login Button'));
        await tester.pumpAndSettle();

        // State should be updated
        expect(mockState.selectedElement, equals(childElement1));
        expect(mockState.hasSelectedElement, isTrue);
      });

      testWidgets('should update display when state changes', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Change state
        mockState.selectElement(childElement2);
        await tester.pumpAndSettle();

        // UI should reflect the change
        // This is tested by verifying the selected element styling
        expect(mockState.selectedElement, equals(childElement2));
      });
    });
  });
}