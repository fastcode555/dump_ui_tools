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
  group('Simple Integration Tests', () {
    test('Core services integration', () async {
      // Test ADB Service
      final adbService = ADBService();
      expect(adbService, isNotNull);

      // Test XML Parser
      final xmlParser = XMLParser();
      expect(xmlParser, isNotNull);

      // Test File Manager
      final fileManager = FileManagerImpl();
      expect(fileManager, isNotNull);

      // Test basic XML parsing
      const testXml = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node class="android.widget.FrameLayout" package="com.test" text="Test" clickable="true" bounds="[0,0][100,100]" />
</hierarchy>''';

      final rootElement = await xmlParser.parseXMLString(testXml);
      expect(rootElement, isNotNull);
      expect(rootElement.children.length, 1);
      expect(rootElement.children.first.text, 'Test');
    });

    test('State management integration', () {
      final state = UIAnalyzerState();

      // Test initial state
      expect(state.hasUIHierarchy, false);
      expect(state.hasSelectedDevice, false);
      expect(state.isLoading, false);

      // Test device management
      final mockDevice = AndroidDevice(
        id: 'test-device',
        name: 'Test Device',
        status: DeviceStatus.device,
      );

      state.setAvailableDevices([mockDevice]);
      state.selectDevice(mockDevice);

      expect(state.hasSelectedDevice, true);
      expect(state.selectedDevice?.id, 'test-device');

      // Test UI hierarchy management
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

      state.setUIHierarchy(mockRoot);
      expect(state.hasUIHierarchy, true);
      expect(state.totalElementCount, 1);

      // Test search and filter
      state.setSearchQuery('test');
      state.setFilterCriteria(FilterCriteria.empty.copyWithClickableFilter(true));

      expect(state.searchQuery, 'test');
      expect(state.filterCriteria.showOnlyClickable, true);

      state.dispose();
    });

    test('App integration manager', () async {
      final state = UIAnalyzerState();
      final appIntegration = AppIntegration();

      await appIntegration.initialize(state);

      // Test health status
      final healthStatus = appIntegration.getHealthStatus();
      expect(healthStatus['isInitialized'], true);
      expect(healthStatus, containsPair('hasSelectedDevice', false));
      expect(healthStatus, containsPair('hasUIHierarchy', false));

      // Test integration status
      final integrationStatus = appIntegration.getIntegrationStatus();
      expect(integrationStatus['initialized'], true);
      expect(integrationStatus['stateValid'], true);

      state.dispose();
    });

    test('Filter criteria integration', () {
      final criteria = FilterCriteria.empty;
      expect(criteria.hasActiveFilters, false);

      final clickableFilter = criteria.copyWithClickableFilter(true);
      expect(clickableFilter.hasActiveFilters, true);
      expect(clickableFilter.showOnlyClickable, true);

      final inputFilter = clickableFilter.copyWithInputFilter(true);
      expect(inputFilter.showOnlyInputs, true);
      expect(inputFilter.showOnlyClickable, true);

      // Test filtering with mock elements
      final elements = [
        UIElement(
          id: 'clickable',
          depth: 0,
          text: 'Button',
          contentDesc: '',
          className: 'android.widget.Button',
          packageName: 'com.test',
          resourceId: '',
          clickable: true,
          enabled: true,
          bounds: Rect.zero,
          index: 0,
        ),
        UIElement(
          id: 'non_clickable',
          depth: 0,
          text: 'Text',
          contentDesc: '',
          className: 'android.widget.TextView',
          packageName: 'com.test',
          resourceId: '',
          clickable: false,
          enabled: true,
          bounds: Rect.zero,
          index: 1,
        ),
      ];

      final filteredElements = clickableFilter.filterElements(elements);
      expect(filteredElements.length, 1);
      expect(filteredElements.first.clickable, true);
    });

    test('UI element hierarchy integration', () {
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
        bounds: const Rect.fromLTWH(0, 0, 100, 100),
        index: 0,
      );

      final child1 = UIElement(
        id: 'child1',
        depth: 1,
        text: 'Child 1',
        contentDesc: '',
        className: 'TextView',
        packageName: 'com.test',
        resourceId: '',
        clickable: false,
        enabled: true,
        bounds: const Rect.fromLTWH(10, 10, 80, 20),
        index: 0,
      );

      final child2 = UIElement(
        id: 'child2',
        depth: 1,
        text: 'Child 2',
        contentDesc: '',
        className: 'Button',
        packageName: 'com.test',
        resourceId: '',
        clickable: true,
        enabled: true,
        bounds: const Rect.fromLTWH(10, 40, 80, 30),
        index: 1,
      );

      root.addChild(child1);
      root.addChild(child2);

      expect(root.hasChildren, true);
      expect(root.childCount, 2);
      expect(root.children.length, 2);

      final allDescendants = root.getAllDescendants();
      expect(allDescendants.length, 2);

      final pathFromRoot = child2.getPathFromRoot();
      expect(pathFromRoot.length, 2);
      expect(pathFromRoot.first, root);
      expect(pathFromRoot.last, child2);
    });

    test('Error handling integration', () {
      final state = UIAnalyzerState();

      // Test error state management
      const testError = 'Test error message';
      state.setError(testError);

      expect(state.hasError, true);
      expect(state.errorMessage, testError);
      expect(state.isLoading, false);

      // Test error clearing
      state.clearError();
      expect(state.hasError, false);
      expect(state.errorMessage, null);

      // Test exception handling
      state.setErrorFromException(Exception('Test exception'));
      expect(state.hasError, true);
      expect(state.errorMessage, contains('Test exception'));

      state.dispose();
    });

    test('Loading state integration', () {
      final state = UIAnalyzerState();

      // Test loading state
      state.setLoading(true, 'Loading test data...', 0.5);
      expect(state.isLoading, true);
      expect(state.loadingMessage, 'Loading test data...');
      expect(state.loadingProgress, 0.5);

      // Test progress update
      state.updateProgress(0.8, 'Almost done...');
      expect(state.loadingProgress, 0.8);
      expect(state.loadingMessage, 'Almost done...');

      // Test step update
      state.updateStep(3, 5, 'Step 3');
      expect(state.currentStep, 3);
      expect(state.totalSteps, 5);
      expect(state.currentStepName, 'Step 3');

      // Clear loading state
      state.setLoading(false);
      expect(state.isLoading, false);
      expect(state.loadingProgress, null);

      state.dispose();
    });

    test('Theme integration', () {
      final state = UIAnalyzerState();

      // Test initial theme
      expect(state.themeMode, ThemeMode.system);

      // Test theme switching
      state.setThemeMode(ThemeMode.dark);
      expect(state.themeMode, ThemeMode.dark);
      expect(state.isDarkMode, true);

      state.setThemeMode(ThemeMode.light);
      expect(state.themeMode, ThemeMode.light);
      expect(state.isDarkMode, false);

      // Test dark mode toggle
      state.toggleDarkMode();
      expect(state.isDarkMode, true);
      expect(state.themeMode, ThemeMode.dark);

      state.dispose();
    });

    test('Statistics integration', () {
      final state = UIAnalyzerState();

      // Create mock hierarchy
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

      final child = UIElement(
        id: 'child',
        depth: 1,
        text: 'Child',
        contentDesc: '',
        className: 'Button',
        packageName: 'com.test',
        resourceId: '',
        clickable: true,
        enabled: true,
        bounds: Rect.zero,
        index: 0,
      );

      root.addChild(child);
      state.setUIHierarchy(root);

      // Test statistics
      final stats = state.getStatistics();
      expect(stats['totalElements'], 2);
      expect(stats['filteredElements'], 2);
      expect(stats['hasActiveFilters'], false);
      expect(stats['isSearchActive'], false);

      state.dispose();
    });
  });
}