import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dump_ui_tools/controllers/ui_analyzer_state.dart';
import 'package:dump_ui_tools/services/adb_service.dart';
import 'package:dump_ui_tools/services/xml_parser.dart';
import 'package:dump_ui_tools/services/file_manager.dart';
import 'package:dump_ui_tools/models/ui_element.dart';
import 'package:dump_ui_tools/models/android_device.dart';
import 'package:dump_ui_tools/models/filter_criteria.dart';
import 'package:dump_ui_tools/integration/app_integration.dart';

void main() {
  group('End-to-End Integration Tests', () {
    late UIAnalyzerState state;
    late AppIntegration appIntegration;

    setUp(() {
      state = UIAnalyzerState();
      appIntegration = AppIntegration();
    });

    tearDown(() {
      state.dispose();
    });

    test('Complete application workflow integration', () async {
      // Step 1: Initialize application
      await appIntegration.initialize(state);
      expect(appIntegration.getHealthStatus()['isInitialized'], true);

      // Step 2: Mock device discovery and selection
      final mockDevice = AndroidDevice(
        id: 'test-device-001',
        name: 'Test Android Device',
        status: DeviceStatus.device,
        model: 'Test Model',
        androidVersion: '12',
        apiLevel: 31,
      );

      state.setAvailableDevices([mockDevice]);
      state.selectDevice(mockDevice);

      expect(state.hasSelectedDevice, true);
      expect(state.selectedDevice?.id, 'test-device-001');

      // Step 3: Create mock UI hierarchy
      final mockRoot = _createComplexMockHierarchy();
      const mockXmlContent = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node class="android.widget.FrameLayout" package="com.test.app" bounds="[0,0][1080,1920]">
    <node class="android.widget.LinearLayout" package="com.test.app" bounds="[0,100][1080,800]">
      <node class="android.widget.TextView" text="Welcome" package="com.test.app" bounds="[100,200][980,250]" />
      <node class="android.widget.Button" text="Login" clickable="true" package="com.test.app" bounds="[400,300][680,380]" />
      <node class="android.widget.EditText" text="" clickable="true" package="com.test.app" bounds="[100,400][980,450]" />
    </node>
  </node>
</hierarchy>''';

      state.setUIHierarchy(mockRoot, xmlContent: mockXmlContent);

      expect(state.hasUIHierarchy, true);
      expect(state.totalElementCount, greaterThan(1));
      expect(state.hasXmlContent, true);

      // Step 4: Test search functionality
      final searchResults = await appIntegration.performSearch('Login');
      expect(searchResults.isNotEmpty, true);
      expect(searchResults.any((e) => e.text.contains('Login')), true);

      state.setSearchQuery('Login');
      expect(state.hasSearchResults, true);

      // Step 5: Test filter functionality
      final clickableFilter = FilterCriteria.empty.copyWithClickableFilter(true);
      final filteredElements = appIntegration.applyFilters(clickableFilter);
      
      state.setFilterCriteria(clickableFilter);
      expect(state.hasActiveFilters, true);
      expect(filteredElements.every((e) => e.clickable), true);

      // Step 6: Test element selection
      final loginButton = state.flatElements.firstWhere(
        (e) => e.text.contains('Login'),
        orElse: () => state.flatElements.first,
      );
      
      state.selectElement(loginButton);
      expect(state.hasSelectedElement, true);
      expect(state.selectedElement?.id, loginButton.id);

      // Step 7: Test XML viewer
      state.toggleXmlViewer();
      expect(state.isXmlViewerVisible, true);

      // Step 8: Test theme switching
      state.setThemeMode(ThemeMode.dark);
      expect(state.themeMode, ThemeMode.dark);
      expect(state.isDarkMode, true);

      // Step 9: Test statistics and health check
      final stats = state.getStatistics();
      expect(stats['totalElements'], greaterThan(0));
      expect(stats['selectedDevice'], contains('Test Android Device'));

      final healthStatus = appIntegration.getHealthStatus();
      expect(healthStatus['hasSelectedDevice'], true);
      expect(healthStatus['hasUIHierarchy'], true);
      expect(healthStatus['deviceConnected'], true);

      // Step 10: Test hierarchy validation
      final isValid = appIntegration.validateHierarchyIntegrity();
      expect(isValid, true);

      // Step 11: Test hierarchy statistics
      final hierarchyStats = appIntegration.getHierarchyStatistics();
      expect(hierarchyStats.isNotEmpty, true);
      expect(hierarchyStats['totalElements'], greaterThan(0));

      // Step 12: Test error handling
      state.setError('Test error for integration');
      expect(state.hasError, true);
      expect(state.errorMessage, 'Test error for integration');

      state.clearError();
      expect(state.hasError, false);

      // Step 13: Test loading states
      state.setLoading(true, 'Integration test loading...', 0.75);
      expect(state.isLoading, true);
      expect(state.loadingMessage, 'Integration test loading...');
      expect(state.loadingProgress, 0.75);

      state.setLoading(false);
      expect(state.isLoading, false);

      // Step 14: Test reset functionality
      await appIntegration.resetApplication();
      expect(state.hasUIHierarchy, false);
      expect(state.hasSelectedElement, false);
      expect(state.hasError, false);
    });

    test('Service integration and coordination', () async {
      // Test individual service functionality
      final adbService = ADBService();
      final xmlParser = XMLParser();
      final fileManager = FileManagerImpl();

      // Test ADB service
      expect(adbService, isNotNull);
      final isAdbAvailable = await adbService.isADBAvailable();
      // Note: ADB may not be available in test environment, so we just check the method works

      // Test XML parser with complex XML
      const complexXml = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node index="0" class="android.widget.FrameLayout" package="com.test.app" bounds="[0,0][1080,1920]">
    <node index="0" class="android.widget.LinearLayout" package="com.test.app" bounds="[0,100][1080,800]">
      <node index="0" text="Welcome to App" class="android.widget.TextView" package="com.test.app" bounds="[100,200][980,250]" />
      <node index="1" text="Login" clickable="true" class="android.widget.Button" package="com.test.app" bounds="[400,300][680,380]" />
      <node index="2" text="" clickable="true" class="android.widget.EditText" package="com.test.app" bounds="[100,400][980,450]" />
      <node index="3" class="android.widget.ScrollView" package="com.test.app" bounds="[0,500][1080,1500]">
        <node index="0" class="android.widget.LinearLayout" package="com.test.app" bounds="[0,500][1080,1200]">
          <node index="0" text="Item 1" class="android.widget.TextView" package="com.test.app" bounds="[50,520][1030,570]" />
          <node index="1" text="Item 2" class="android.widget.TextView" package="com.test.app" bounds="[50,580][1030,630]" />
        </node>
      </node>
    </node>
  </node>
</hierarchy>''';

      final parsedRoot = await xmlParser.parseXMLString(complexXml);
      expect(parsedRoot, isNotNull);
      expect(parsedRoot.children.isNotEmpty, true);

      // Verify hierarchy structure
      final allElements = [parsedRoot, ...parsedRoot.getAllDescendants()];
      expect(allElements.length, greaterThan(5));

      // Test hierarchy statistics
      final stats = xmlParser.getHierarchyStats(parsedRoot);
      expect(stats['totalElements'], allElements.length);
      expect(stats['maxDepth'], greaterThan(0));
      expect(stats['clickableElements'], greaterThan(0));

      // Test file manager (basic functionality)
      expect(fileManager, isNotNull);
      
      // Test XML content validation
      final isValidXml = xmlParser.validateXMLContent(complexXml);
      expect(isValidXml, true);

      // Test invalid XML
      const invalidXml = '<invalid>unclosed tag';
      final isInvalidXml = xmlParser.validateXMLContent(invalidXml);
      expect(isInvalidXml, false);
    });

    test('Complex filtering and search integration', () {
      // Create complex hierarchy for testing
      final root = _createComplexMockHierarchy();
      state.setUIHierarchy(root);

      final allElements = state.flatElements;
      expect(allElements.length, greaterThan(5));

      // Test multiple filter combinations
      final clickableFilter = FilterCriteria.empty.copyWithClickableFilter(true);
      final clickableElements = clickableFilter.filterElements(allElements);
      expect(clickableElements.every((e) => e.clickable), true);

      final textFilter = FilterCriteria.empty.copyWithTextFilter(true);
      final textElements = textFilter.filterElements(allElements);
      expect(textElements.every((e) => e.text.isNotEmpty || e.contentDesc.isNotEmpty), true);

      final enabledFilter = FilterCriteria.empty.copyWith(enabledOnly: true);
      final enabledElements = enabledFilter.filterElements(allElements);
      expect(enabledElements.every((e) => e.enabled), true);

      // Test combined filters
      final combinedFilter = FilterCriteria.empty
          .copyWithClickableFilter(true)
          .copyWithTextFilter(true);
      
      state.setFilterCriteria(combinedFilter);
      expect(state.hasActiveFilters, true);
      expect(state.filteredElements.every((e) => e.clickable && (e.text.isNotEmpty || e.contentDesc.isNotEmpty)), true);

      // Test search with filters
      state.setSearchQuery('Button');
      expect(state.hasSearchResults, true);
      
      final searchResults = state.searchResults;
      expect(searchResults.every((e) => 
        e.text.toLowerCase().contains('button') ||
        e.contentDesc.toLowerCase().contains('button') ||
        e.className.toLowerCase().contains('button')
      ), true);
    });

    test('Performance and memory integration', () {
      // Test with large hierarchy
      final largeRoot = _createLargeHierarchy(100);
      state.setUIHierarchy(largeRoot);

      final allElements = state.flatElements;
      expect(allElements.length, greaterThanOrEqualTo(80)); // Allow for some variation in tree generation

      // Test search performance
      final stopwatch = Stopwatch()..start();
      state.setSearchQuery('Element');
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should complete within 1 second
      expect(state.hasSearchResults, true);

      // Test filter performance
      stopwatch.reset();
      stopwatch.start();
      state.setFilterCriteria(FilterCriteria.empty.copyWithClickableFilter(true));
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(500)); // Should complete within 500ms

      // Test memory usage tracking
      final healthStatus = appIntegration.getHealthStatus();
      expect(healthStatus['totalElements'], greaterThanOrEqualTo(80));
      expect(healthStatus['filteredElements'], greaterThan(0));
      
      final memoryStats = healthStatus['memoryUsage'] as Map<String, dynamic>;
      expect(memoryStats['flatElements'], greaterThanOrEqualTo(80));
      expect(memoryStats['filteredElements'], greaterThan(0));
    });
  });
}

/// Create a complex mock UI hierarchy for testing
UIElement _createComplexMockHierarchy() {
  final root = UIElement(
    id: 'root',
    depth: 0,
    text: '',
    contentDesc: 'Application root',
    className: 'android.widget.FrameLayout',
    packageName: 'com.test.app',
    resourceId: '',
    clickable: false,
    enabled: true,
    bounds: const Rect.fromLTWH(0, 0, 1080, 1920),
    index: 0,
  );

  final mainLayout = UIElement(
    id: 'main_layout',
    depth: 1,
    text: '',
    contentDesc: 'Main layout container',
    className: 'android.widget.LinearLayout',
    packageName: 'com.test.app',
    resourceId: 'com.test.app:id/main_layout',
    clickable: false,
    enabled: true,
    bounds: const Rect.fromLTWH(0, 100, 1080, 700),
    index: 0,
  );

  final welcomeText = UIElement(
    id: 'welcome_text',
    depth: 2,
    text: 'Welcome to Test App',
    contentDesc: 'Welcome message',
    className: 'android.widget.TextView',
    packageName: 'com.test.app',
    resourceId: 'com.test.app:id/welcome_text',
    clickable: false,
    enabled: true,
    bounds: const Rect.fromLTWH(100, 200, 880, 50),
    index: 0,
  );

  final loginButton = UIElement(
    id: 'login_button',
    depth: 2,
    text: 'Login',
    contentDesc: 'Login button',
    className: 'android.widget.Button',
    packageName: 'com.test.app',
    resourceId: 'com.test.app:id/login_button',
    clickable: true,
    enabled: true,
    bounds: const Rect.fromLTWH(400, 300, 280, 80),
    index: 1,
  );

  final usernameInput = UIElement(
    id: 'username_input',
    depth: 2,
    text: '',
    contentDesc: 'Username input field',
    className: 'android.widget.EditText',
    packageName: 'com.test.app',
    resourceId: 'com.test.app:id/username_input',
    clickable: true,
    enabled: true,
    bounds: const Rect.fromLTWH(100, 400, 880, 50),
    index: 2,
  );

  final passwordInput = UIElement(
    id: 'password_input',
    depth: 2,
    text: '',
    contentDesc: 'Password input field',
    className: 'android.widget.EditText',
    packageName: 'com.test.app',
    resourceId: 'com.test.app:id/password_input',
    clickable: true,
    enabled: true,
    bounds: const Rect.fromLTWH(100, 470, 880, 50),
    index: 3,
  );

  final scrollView = UIElement(
    id: 'scroll_view',
    depth: 2,
    text: '',
    contentDesc: 'Scrollable content',
    className: 'android.widget.ScrollView',
    packageName: 'com.test.app',
    resourceId: 'com.test.app:id/scroll_view',
    clickable: false,
    enabled: true,
    bounds: const Rect.fromLTWH(0, 540, 1080, 260),
    index: 4,
  );

  final scrollContent = UIElement(
    id: 'scroll_content',
    depth: 3,
    text: '',
    contentDesc: 'Scroll content container',
    className: 'android.widget.LinearLayout',
    packageName: 'com.test.app',
    resourceId: 'com.test.app:id/scroll_content',
    clickable: false,
    enabled: true,
    bounds: const Rect.fromLTWH(0, 540, 1080, 200),
    index: 0,
  );

  // Add some items to scroll content
  for (int i = 0; i < 3; i++) {
    final item = UIElement(
      id: 'scroll_item_$i',
      depth: 4,
      text: 'Scroll Item ${i + 1}',
      contentDesc: 'Scrollable item ${i + 1}',
      className: 'android.widget.TextView',
      packageName: 'com.test.app',
      resourceId: 'com.test.app:id/scroll_item_$i',
      clickable: false,
      enabled: true,
      bounds: Rect.fromLTWH(50, 560 + (i * 60), 980, 50),
      index: i,
    );
    scrollContent.addChild(item);
  }

  // Build hierarchy
  scrollView.addChild(scrollContent);
  mainLayout.addChild(welcomeText);
  mainLayout.addChild(loginButton);
  mainLayout.addChild(usernameInput);
  mainLayout.addChild(passwordInput);
  mainLayout.addChild(scrollView);
  root.addChild(mainLayout);

  return root;
}

/// Create a large hierarchy for performance testing
UIElement _createLargeHierarchy(int elementCount) {
  final root = UIElement(
    id: 'large_root',
    depth: 0,
    text: '',
    contentDesc: 'Large hierarchy root',
    className: 'android.widget.FrameLayout',
    packageName: 'com.test.app',
    resourceId: '',
    clickable: false,
    enabled: true,
    bounds: const Rect.fromLTWH(0, 0, 1080, 1920),
    index: 0,
  );

  // Create a balanced tree structure
  _addChildrenRecursively(root, elementCount - 1, 1, 5);
  return root;
}

/// Recursively add children to create large hierarchy
void _addChildrenRecursively(UIElement parent, int remainingElements, int currentDepth, int maxChildren) {
  if (remainingElements <= 0 || currentDepth > 8) return;

  final childrenCount = (remainingElements < maxChildren) ? remainingElements : maxChildren;
  final elementsPerChild = (remainingElements - childrenCount) ~/ childrenCount;

  for (int i = 0; i < childrenCount; i++) {
    final child = UIElement(
      id: 'large_element_${currentDepth}_$i',
      depth: currentDepth,
      text: 'Element $i at depth $currentDepth',
      contentDesc: 'Large hierarchy element $i',
      className: i % 2 == 0 ? 'android.widget.TextView' : 'android.widget.Button',
      packageName: 'com.test.app',
      resourceId: 'com.test.app:id/large_element_${currentDepth}_$i',
      clickable: i % 2 == 1, // Every other element is clickable
      enabled: true,
      bounds: Rect.fromLTWH(i * 50.0, currentDepth * 50.0, 100, 50),
      index: i,
    );

    parent.addChild(child);

    if (elementsPerChild > 0) {
      _addChildrenRecursively(child, elementsPerChild, currentDepth + 1, maxChildren);
    }
  }
}