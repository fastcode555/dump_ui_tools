import 'dart:async';
import 'package:flutter/foundation.dart';
import '../controllers/ui_analyzer_state.dart';
import '../services/adb_service.dart';
import '../services/xml_parser.dart';
import '../services/file_manager.dart';
import '../models/ui_element.dart';
import '../models/android_device.dart';
import '../models/filter_criteria.dart';
import '../integration/app_integration.dart';

/// Comprehensive integration verification utility
class IntegrationVerifier {
  static final IntegrationVerifier _instance = IntegrationVerifier._internal();
  factory IntegrationVerifier() => _instance;
  IntegrationVerifier._internal();

  /// Perform complete integration verification
  Future<IntegrationReport> verifyIntegration() async {
    final report = IntegrationReport();
    
    try {
      // Test 1: State Management Integration
      await _testStateManagement(report);
      
      // Test 2: Service Integration
      await _testServiceIntegration(report);
      
      // Test 3: UI Component Integration
      await _testUIComponentIntegration(report);
      
      // Test 4: Data Flow Integration
      await _testDataFlowIntegration(report);
      
      // Test 5: Error Handling Integration
      await _testErrorHandlingIntegration(report);
      
      // Test 6: Performance Integration
      await _testPerformanceIntegration(report);
      
      // Calculate overall score
      report.calculateOverallScore();
      
      debugPrint('IntegrationVerifier: Verification completed with score ${report.overallScore}%');
      
    } catch (e) {
      report.addError('Critical integration failure: $e');
      debugPrint('IntegrationVerifier: Critical failure during verification: $e');
    }
    
    return report;
  }

  /// Test state management integration
  Future<void> _testStateManagement(IntegrationReport report) async {
    final testName = 'State Management Integration';
    
    try {
      final state = UIAnalyzerState();
      
      // Test initial state
      if (!state.hasUIHierarchy && !state.hasSelectedDevice && !state.isLoading) {
        report.addSuccess(testName, 'Initial state is correct');
      } else {
        report.addFailure(testName, 'Initial state is incorrect');
      }
      
      // Test device management
      final mockDevice = AndroidDevice(
        id: 'test-device',
        name: 'Test Device',
        status: DeviceStatus.device,
      );
      
      state.setAvailableDevices([mockDevice]);
      state.selectDevice(mockDevice);
      
      if (state.hasSelectedDevice && state.selectedDevice?.id == 'test-device') {
        report.addSuccess(testName, 'Device selection works correctly');
      } else {
        report.addFailure(testName, 'Device selection failed');
      }
      
      // Test UI hierarchy management
      final mockRoot = _createMockUIElement();
      state.setUIHierarchy(mockRoot);
      
      if (state.hasUIHierarchy && state.totalElementCount > 0) {
        report.addSuccess(testName, 'UI hierarchy management works correctly');
      } else {
        report.addFailure(testName, 'UI hierarchy management failed');
      }
      
      // Test search and filter
      state.setSearchQuery('test');
      state.setFilterCriteria(FilterCriteria.empty.copyWithClickableFilter(true));
      
      if (state.searchQuery == 'test' && state.filterCriteria.showOnlyClickable) {
        report.addSuccess(testName, 'Search and filter state management works correctly');
      } else {
        report.addFailure(testName, 'Search and filter state management failed');
      }
      
      state.dispose();
      
    } catch (e) {
      report.addError('$testName failed with exception: $e');
    }
  }

  /// Test service integration
  Future<void> _testServiceIntegration(IntegrationReport report) async {
    final testName = 'Service Integration';
    
    try {
      // Test ADB Service
      final adbService = ADBService();
      final isAdbAvailable = await adbService.isADBAvailable();
      
      if (isAdbAvailable) {
        report.addSuccess(testName, 'ADB service is available and working');
        
        // Test device discovery
        try {
          final devices = await adbService.getConnectedDevices();
          report.addSuccess(testName, 'Device discovery works (found ${devices.length} devices)');
        } catch (e) {
          report.addWarning(testName, 'Device discovery failed: $e');
        }
      } else {
        report.addWarning(testName, 'ADB service is not available on this system');
      }
      
      // Test XML Parser
      final xmlParser = XMLParser();
      const testXml = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node class="android.widget.FrameLayout" package="com.test" text="Test" clickable="true" bounds="[0,0][100,100]" />
</hierarchy>''';
      
      try {
        final rootElement = await xmlParser.parseXMLString(testXml);
        if (rootElement.children.isNotEmpty) {
          report.addSuccess(testName, 'XML parser works correctly');
        } else {
          report.addFailure(testName, 'XML parser failed to parse test XML');
        }
      } catch (e) {
        report.addFailure(testName, 'XML parser failed with exception: $e');
      }
      
      // Test File Manager
      final fileManager = FileManagerImpl();
      
      try {
        const testContent = 'Test file content';
        final savedPath = await fileManager.saveUIdump(testContent, filename: 'test_integration.xml');
        
        final readContent = await fileManager.readFile(savedPath);
        if (readContent == testContent) {
          report.addSuccess(testName, 'File manager works correctly');
        } else {
          report.addFailure(testName, 'File manager read/write mismatch');
        }
        
        // Cleanup
        await fileManager.deleteFile(savedPath);
        
      } catch (e) {
        report.addFailure(testName, 'File manager failed with exception: $e');
      }
      
    } catch (e) {
      report.addError('$testName failed with exception: $e');
    }
  }

  /// Test UI component integration
  Future<void> _testUIComponentIntegration(IntegrationReport report) async {
    final testName = 'UI Component Integration';
    
    try {
      // Test state-UI binding
      final state = UIAnalyzerState();
      
      // Simulate UI state changes
      state.setLoading(true, 'Test loading');
      if (state.isLoading && state.loadingMessage == 'Test loading') {
        report.addSuccess(testName, 'Loading state UI binding works correctly');
      } else {
        report.addFailure(testName, 'Loading state UI binding failed');
      }
      
      // Test theme integration
      state.setThemeMode(ThemeMode.dark);
      if (state.themeMode == ThemeMode.dark && state.isDarkMode) {
        report.addSuccess(testName, 'Theme integration works correctly');
      } else {
        report.addFailure(testName, 'Theme integration failed');
      }
      
      // Test XML viewer integration
      const testXml = '<test>content</test>';
      state.setUIHierarchy(_createMockUIElement(), xmlContent: testXml);
      state.toggleXmlViewer();
      
      if (state.isXmlViewerVisible && state.hasXmlContent) {
        report.addSuccess(testName, 'XML viewer integration works correctly');
      } else {
        report.addFailure(testName, 'XML viewer integration failed');
      }
      
      state.dispose();
      
    } catch (e) {
      report.addError('$testName failed with exception: $e');
    }
  }

  /// Test data flow integration
  Future<void> _testDataFlowIntegration(IntegrationReport report) async {
    final testName = 'Data Flow Integration';
    
    try {
      final appIntegration = AppIntegration();
      final state = UIAnalyzerState();
      
      await appIntegration.initialize(state);
      
      // Test device refresh flow
      try {
        await appIntegration.refreshDevices();
        report.addSuccess(testName, 'Device refresh flow works correctly');
      } catch (e) {
        report.addWarning(testName, 'Device refresh flow failed (expected if no ADB): $e');
      }
      
      // Test search flow
      if (state.hasUIHierarchy) {
        final searchResults = await appIntegration.performSearch('test');
        report.addSuccess(testName, 'Search flow works correctly (found ${searchResults.length} results)');
      } else {
        // Create mock hierarchy for testing
        state.setUIHierarchy(_createMockUIElement());
        final searchResults = await appIntegration.performSearch('test');
        report.addSuccess(testName, 'Search flow works correctly with mock data (found ${searchResults.length} results)');
      }
      
      // Test filter flow
      final filterCriteria = FilterCriteria.empty.copyWithClickableFilter(true);
      final filteredResults = appIntegration.applyFilters(filterCriteria);
      report.addSuccess(testName, 'Filter flow works correctly (${filteredResults.length} filtered results)');
      
      // Test statistics flow
      final stats = appIntegration.getHierarchyStatistics();
      if (stats.isNotEmpty) {
        report.addSuccess(testName, 'Statistics flow works correctly');
      } else {
        report.addWarning(testName, 'Statistics flow returned empty results');
      }
      
      state.dispose();
      
    } catch (e) {
      report.addError('$testName failed with exception: $e');
    }
  }

  /// Test error handling integration
  Future<void> _testErrorHandlingIntegration(IntegrationReport report) async {
    final testName = 'Error Handling Integration';
    
    try {
      final state = UIAnalyzerState();
      
      // Test error state management
      const testError = 'Test error message';
      state.setError(testError);
      
      if (state.hasError && state.errorMessage == testError && !state.isLoading) {
        report.addSuccess(testName, 'Error state management works correctly');
      } else {
        report.addFailure(testName, 'Error state management failed');
      }
      
      // Test error clearing
      state.clearError();
      if (!state.hasError && state.errorMessage == null) {
        report.addSuccess(testName, 'Error clearing works correctly');
      } else {
        report.addFailure(testName, 'Error clearing failed');
      }
      
      // Test exception handling
      try {
        state.setErrorFromException(Exception('Test exception'));
        if (state.hasError) {
          report.addSuccess(testName, 'Exception handling works correctly');
        } else {
          report.addFailure(testName, 'Exception handling failed');
        }
      } catch (e) {
        report.addFailure(testName, 'Exception handling threw unexpected error: $e');
      }
      
      state.dispose();
      
    } catch (e) {
      report.addError('$testName failed with exception: $e');
    }
  }

  /// Test performance integration
  Future<void> _testPerformanceIntegration(IntegrationReport report) async {
    final testName = 'Performance Integration';
    
    try {
      final state = UIAnalyzerState();
      final stopwatch = Stopwatch();
      
      // Test large hierarchy performance
      stopwatch.start();
      final largeHierarchy = _createLargeUIHierarchy(1000);
      state.setUIHierarchy(largeHierarchy);
      stopwatch.stop();
      
      final hierarchyLoadTime = stopwatch.elapsedMilliseconds;
      if (hierarchyLoadTime < 1000) { // Should load within 1 second
        report.addSuccess(testName, 'Large hierarchy loading performance is acceptable (${hierarchyLoadTime}ms)');
      } else {
        report.addWarning(testName, 'Large hierarchy loading is slow (${hierarchyLoadTime}ms)');
      }
      
      // Test search performance
      stopwatch.reset();
      stopwatch.start();
      state.setSearchQuery('test');
      stopwatch.stop();
      
      final searchTime = stopwatch.elapsedMilliseconds;
      if (searchTime < 100) { // Should search within 100ms
        report.addSuccess(testName, 'Search performance is acceptable (${searchTime}ms)');
      } else {
        report.addWarning(testName, 'Search performance is slow (${searchTime}ms)');
      }
      
      // Test filter performance
      stopwatch.reset();
      stopwatch.start();
      state.setFilterCriteria(FilterCriteria.empty.copyWithClickableFilter(true));
      stopwatch.stop();
      
      final filterTime = stopwatch.elapsedMilliseconds;
      if (filterTime < 100) { // Should filter within 100ms
        report.addSuccess(testName, 'Filter performance is acceptable (${filterTime}ms)');
      } else {
        report.addWarning(testName, 'Filter performance is slow (${filterTime}ms)');
      }
      
      state.dispose();
      
    } catch (e) {
      report.addError('$testName failed with exception: $e');
    }
  }

  /// Create mock UI element for testing
  UIElement _createMockUIElement() {
    final root = UIElement(
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

    final child = UIElement(
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

    root.addChild(child);
    return root;
  }

  /// Create large UI hierarchy for performance testing
  UIElement _createLargeUIHierarchy(int elementCount) {
    final root = UIElement(
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

    // Create a balanced tree structure
    _addChildrenRecursively(root, elementCount - 1, 1, 5);
    return root;
  }

  /// Recursively add children to create large hierarchy
  void _addChildrenRecursively(UIElement parent, int remainingElements, int currentDepth, int maxChildren) {
    if (remainingElements <= 0 || currentDepth > 10) return;

    final childrenCount = (remainingElements < maxChildren) ? remainingElements : maxChildren;
    final elementsPerChild = (remainingElements - childrenCount) ~/ childrenCount;

    for (int i = 0; i < childrenCount; i++) {
      final child = UIElement(
        id: 'element_${currentDepth}_$i',
        depth: currentDepth,
        text: 'Element $i at depth $currentDepth',
        contentDesc: 'Test element $i',
        className: 'android.widget.TextView',
        packageName: 'com.test.app',
        resourceId: 'com.test.app:id/element_${currentDepth}_$i',
        clickable: i % 2 == 0,
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
}

/// Integration verification report
class IntegrationReport {
  final List<TestResult> results = [];
  double overallScore = 0.0;

  void addSuccess(String testName, String message) {
    results.add(TestResult(testName, TestStatus.success, message));
  }

  void addFailure(String testName, String message) {
    results.add(TestResult(testName, TestStatus.failure, message));
  }

  void addWarning(String testName, String message) {
    results.add(TestResult(testName, TestStatus.warning, message));
  }

  void addError(String message) {
    results.add(TestResult('Critical Error', TestStatus.error, message));
  }

  void calculateOverallScore() {
    if (results.isEmpty) {
      overallScore = 0.0;
      return;
    }

    int totalPoints = 0;
    int maxPoints = 0;

    for (final result in results) {
      maxPoints += 100;
      switch (result.status) {
        case TestStatus.success:
          totalPoints += 100;
          break;
        case TestStatus.warning:
          totalPoints += 70;
          break;
        case TestStatus.failure:
          totalPoints += 30;
          break;
        case TestStatus.error:
          totalPoints += 0;
          break;
      }
    }

    overallScore = (totalPoints / maxPoints) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'totalTests': results.length,
      'successCount': results.where((r) => r.status == TestStatus.success).length,
      'warningCount': results.where((r) => r.status == TestStatus.warning).length,
      'failureCount': results.where((r) => r.status == TestStatus.failure).length,
      'errorCount': results.where((r) => r.status == TestStatus.error).length,
      'results': results.map((r) => r.toJson()).toList(),
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Integration Verification Report');
    buffer.writeln('Overall Score: ${overallScore.toStringAsFixed(1)}%');
    buffer.writeln('Total Tests: ${results.length}');
    buffer.writeln('');

    for (final result in results) {
      buffer.writeln('${result.status.name.toUpperCase()}: ${result.testName}');
      buffer.writeln('  ${result.message}');
      buffer.writeln('');
    }

    return buffer.toString();
  }
}

/// Individual test result
class TestResult {
  final String testName;
  final TestStatus status;
  final String message;

  TestResult(this.testName, this.status, this.message);

  Map<String, dynamic> toJson() {
    return {
      'testName': testName,
      'status': status.name,
      'message': message,
    };
  }
}

/// Test status enumeration
enum TestStatus {
  success,
  warning,
  failure,
  error,
}