import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dump_ui_tools/main.dart';
import 'package:dump_ui_tools/controllers/ui_analyzer_state.dart';
import 'package:dump_ui_tools/models/ui_element.dart';
import 'package:dump_ui_tools/models/android_device.dart';
import 'package:dump_ui_tools/models/filter_criteria.dart';

void main() {
  group('App Integration Tests', () {
    late UIAnalyzerState state;

    setUp(() {
      state = UIAnalyzerState();
    });

    tearDown(() {
      state.dispose();
    });

    testWidgets('App should start with correct initial state', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const UIAnalyzerApp(),
        ),
      );

      // Verify initial state
      expect(state.hasUIHierarchy, false);
      expect(state.hasSelectedDevice, false);
      expect(state.isLoading, false);
      expect(state.hasError, false);

      // Verify UI elements are present
      expect(find.text('Android UI Analyzer'), findsOneWidget);
      expect(find.text('Select Device'), findsOneWidget);
      expect(find.text('No UI hierarchy loaded'), findsOneWidget);
    });

    testWidgets('Device selection workflow', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const UIAnalyzerApp(),
        ),
      );

      // Mock device data
      final mockDevice = AndroidDevice(
        id: 'test-device',
        name: 'Test Device',
        status: DeviceStatus.device,
      );

      // Add mock device to state
      state.setAvailableDevices([mockDevice]);
      await tester.pump();

      // Select device
      state.selectDevice(mockDevice);
      await tester.pump();

      // Verify device selection
      expect(state.hasSelectedDevice, true);
      expect(state.selectedDevice?.id, 'test-device');
    });

    testWidgets('UI hierarchy loading and display', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const UIAnalyzerApp(),
        ),
      );

      // Create mock UI hierarchy
      final mockRoot = UIElement(
        id: 'root',
        depth: 0,
        text: '',
        contentDesc: 'Root element',
        className: 'android.widget.FrameLayout',
        packageName: 'com.test.app',
        resourceId: '',
        clickable: false,
        enabled: true,
        bounds: const Rect.fromLTWH(0, 0, 1080, 1920),
        index: 0,
      );

      final mockChild = UIElement(
        id: 'child1',
        depth: 1,
        text: 'Test Button',
        contentDesc: 'Test button',
        className: 'android.widget.Button',
        packageName: 'com.test.app',
        resourceId: 'com.test.app:id/test_button',
        clickable: true,
        enabled: true,
        bounds: const Rect.fromLTWH(100, 200, 200, 80),
        index: 0,
      );

      mockRoot.addChild(mockChild);

      // Set UI hierarchy
      state.setUIHierarchy(mockRoot);
      await tester.pump();

      // Verify hierarchy is loaded
      expect(state.hasUIHierarchy, true);
      expect(state.totalElementCount, 2);
      expect(state.filteredElementCount, 2);
    });

    testWidgets('Search functionality integration', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const UIAnalyzerApp(),
        ),
      );

      // Create mock UI hierarchy with searchable elements
      final mockRoot = UIElement(
        id: 'root',
        depth: 0,
        text: '',
        contentDesc: 'Root element',
        className: 'android.widget.FrameLayout',
        packageName: 'com.test.app',
        resourceId: '',
        clickable: false,
        enabled: true,
        bounds: const Rect.fromLTWH(0, 0, 1080, 1920),
        index: 0,
      );

      final searchableChild = UIElement(
        id: 'searchable',
        depth: 1,
        text: 'Login Button',
        contentDesc: 'Login button',
        className: 'android.widget.Button',
        packageName: 'com.test.app',
        resourceId: 'com.test.app:id/login_button',
        clickable: true,
        enabled: true,
        bounds: const Rect.fromLTWH(100, 200, 200, 80),
        index: 0,
      );

      mockRoot.addChild(searchableChild);
      state.setUIHierarchy(mockRoot);
      await tester.pump();

      // Perform search
      state.setSearchQuery('Login');
      await tester.pump();

      // Verify search results
      expect(state.hasSearchResults, true);
      expect(state.searchResults.length, 1);
      expect(state.searchResults.first.text, 'Login Button');
    });

    testWidgets('Filter functionality integration', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const UIAnalyzerApp(),
        ),
      );

      // Create mock UI hierarchy with filterable elements
      final mockRoot = UIElement(
        id: 'root',
        depth: 0,
        text: '',
        contentDesc: 'Root element',
        className: 'android.widget.FrameLayout',
        packageName: 'com.test.app',
        resourceId: '',
        clickable: false,
        enabled: true,
        bounds: const Rect.fromLTWH(0, 0, 1080, 1920),
        index: 0,
      );

      final clickableChild = UIElement(
        id: 'clickable',
        depth: 1,
        text: 'Click Me',
        contentDesc: 'Clickable button',
        className: 'android.widget.Button',
        packageName: 'com.test.app',
        resourceId: 'com.test.app:id/clickable_button',
        clickable: true,
        enabled: true,
        bounds: const Rect.fromLTWH(100, 200, 200, 80),
        index: 0,
      );

      final nonClickableChild = UIElement(
        id: 'non_clickable',
        depth: 1,
        text: 'Static Text',
        contentDesc: 'Static text',
        className: 'android.widget.TextView',
        packageName: 'com.test.app',
        resourceId: 'com.test.app:id/static_text',
        clickable: false,
        enabled: true,
        bounds: const Rect.fromLTWH(100, 300, 200, 40),
        index: 1,
      );

      mockRoot.addChild(clickableChild);
      mockRoot.addChild(nonClickableChild);
      state.setUIHierarchy(mockRoot);
      await tester.pump();

      // Apply clickable filter
      final filterCriteria = FilterCriteria.empty.copyWithClickableFilter(true);
      state.setFilterCriteria(filterCriteria);
      await tester.pump();

      // Verify filter results
      expect(state.hasActiveFilters, true);
      expect(state.filteredElementCount, 1); // Only clickable elements
    });

    testWidgets('Element selection integration', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const UIAnalyzerApp(),
        ),
      );

      // Create mock UI hierarchy
      final mockRoot = UIElement(
        id: 'root',
        depth: 0,
        text: '',
        contentDesc: 'Root element',
        className: 'android.widget.FrameLayout',
        packageName: 'com.test.app',
        resourceId: '',
        clickable: false,
        enabled: true,
        bounds: const Rect.fromLTWH(0, 0, 1080, 1920),
        index: 0,
      );

      final selectableChild = UIElement(
        id: 'selectable',
        depth: 1,
        text: 'Selectable Element',
        contentDesc: 'Selectable element',
        className: 'android.widget.Button',
        packageName: 'com.test.app',
        resourceId: 'com.test.app:id/selectable',
        clickable: true,
        enabled: true,
        bounds: const Rect.fromLTWH(100, 200, 200, 80),
        index: 0,
      );

      mockRoot.addChild(selectableChild);
      state.setUIHierarchy(mockRoot);
      await tester.pump();

      // Select element
      state.selectElement(selectableChild);
      await tester.pump();

      // Verify element selection
      expect(state.hasSelectedElement, true);
      expect(state.selectedElement?.id, 'selectable');
      expect(state.selectedElement?.text, 'Selectable Element');
    });

    testWidgets('Theme switching integration', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const UIAnalyzerApp(),
        ),
      );

      // Verify initial theme
      expect(state.themeMode, ThemeMode.system);

      // Switch to dark theme
      state.setThemeMode(ThemeMode.dark);
      await tester.pump();

      // Verify theme change
      expect(state.themeMode, ThemeMode.dark);
      expect(state.isDarkMode, true);

      // Switch to light theme
      state.setThemeMode(ThemeMode.light);
      await tester.pump();

      // Verify theme change
      expect(state.themeMode, ThemeMode.light);
      expect(state.isDarkMode, false);
    });

    testWidgets('XML viewer integration', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const UIAnalyzerApp(),
        ),
      );

      // Create mock UI hierarchy with XML content
      final mockRoot = UIElement(
        id: 'root',
        depth: 0,
        text: '',
        contentDesc: 'Root element',
        className: 'android.widget.FrameLayout',
        packageName: 'com.test.app',
        resourceId: '',
        clickable: false,
        enabled: true,
        bounds: const Rect.fromLTWH(0, 0, 1080, 1920),
        index: 0,
      );

      const mockXmlContent = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node class="android.widget.FrameLayout" package="com.test.app" />
</hierarchy>''';

      state.setUIHierarchy(mockRoot, xmlContent: mockXmlContent);
      await tester.pump();

      // Verify XML content is available
      expect(state.hasXmlContent, true);
      expect(state.xmlContent.contains('hierarchy'), true);

      // Toggle XML viewer
      state.toggleXmlViewer();
      await tester.pump();

      // Verify XML viewer visibility
      expect(state.isXmlViewerVisible, true);
    });

    testWidgets('Error handling integration', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const UIAnalyzerApp(),
        ),
      );

      // Simulate error
      const errorMessage = 'Test error message';
      state.setError(errorMessage);
      await tester.pump();

      // Verify error state
      expect(state.hasError, true);
      expect(state.errorMessage, errorMessage);
      expect(state.isLoading, false);

      // Clear error
      state.clearError();
      await tester.pump();

      // Verify error is cleared
      expect(state.hasError, false);
      expect(state.errorMessage, null);
    });

    testWidgets('Loading state integration', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const UIAnalyzerApp(),
        ),
      );

      // Set loading state
      state.setLoading(true, 'Loading test data...', 0.5);
      await tester.pump();

      // Verify loading state
      expect(state.isLoading, true);
      expect(state.loadingMessage, 'Loading test data...');
      expect(state.loadingProgress, 0.5);

      // Clear loading state
      state.setLoading(false);
      await tester.pump();

      // Verify loading is cleared
      expect(state.isLoading, false);
      expect(state.loadingProgress, null);
    });

    test('State management integration', () {
      // Test state transitions
      expect(state.hasUIHierarchy, false);
      expect(state.hasSelectedDevice, false);
      expect(state.hasSelectedElement, false);

      // Add device
      final device = AndroidDevice(
        id: 'test-device',
        name: 'Test Device',
        status: DeviceStatus.device,
      );
      state.setAvailableDevices([device]);
      state.selectDevice(device);

      expect(state.hasSelectedDevice, true);
      expect(state.selectedDevice?.id, 'test-device');

      // Add UI hierarchy
      final root = UIElement(
        id: 'root',
        depth: 0,
        text: '',
        contentDesc: 'Root',
        className: 'FrameLayout',
        packageName: 'com.test',
        resourceId: '',
        clickable: false,
        enabled: true,
        bounds: Rect.zero,
        index: 0,
      );

      state.setUIHierarchy(root);
      expect(state.hasUIHierarchy, true);
      expect(state.totalElementCount, 1);

      // Select element
      state.selectElement(root);
      expect(state.hasSelectedElement, true);
      expect(state.selectedElement?.id, 'root');

      // Test statistics
      final stats = state.getStatistics();
      expect(stats['totalElements'], 1);
      expect(stats['selectedDevice'], contains('Test Device'));
      expect(stats['availableDevices'], 1);
    });
  });
}