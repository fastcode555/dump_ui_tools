import 'package:flutter_test/flutter_test.dart';
import 'package:dump_ui_tools/controllers/ui_analyzer_state.dart';
import 'package:dump_ui_tools/models/ui_element.dart';
import 'package:dump_ui_tools/models/android_device.dart';
import 'package:dump_ui_tools/models/filter_criteria.dart';
import 'package:dump_ui_tools/services/user_preferences.dart';
import 'dart:ui';

void main() {
  group('UIAnalyzerState Tests', () {
    late UIAnalyzerState state;
    
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await UserPreferences.initialize();
      state = UIAnalyzerState();
    });
    
    tearDown(() {
      state.dispose();
    });
    
    test('should initialize with empty state', () {
      expect(state.rootElement, isNull);
      expect(state.flatElements, isEmpty);
      expect(state.filteredElements, isEmpty);
      expect(state.selectedDevice, isNull);
      expect(state.availableDevices, isEmpty);
      expect(state.filterCriteria, equals(FilterCriteria.empty));
      expect(state.selectedElement, isNull);
      expect(state.xmlContent, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.hasUIHierarchy, isFalse);
    });
    
    test('should set UI hierarchy correctly', () {
      final rootElement = UIElement(
        id: 'root',
        depth: 0,
        className: 'LinearLayout',
        bounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
      
      final childElement = UIElement(
        id: 'child',
        depth: 1,
        className: 'TextView',
        text: 'Hello',
        bounds: const Rect.fromLTWH(10, 10, 80, 20),
      );
      
      rootElement.addChild(childElement);
      
      state.setUIHierarchy(rootElement, xmlContent: '<test>xml</test>');
      
      expect(state.rootElement, equals(rootElement));
      expect(state.hasUIHierarchy, isTrue);
      expect(state.flatElements.length, equals(2)); // root + child
      expect(state.xmlContent, equals('<test>xml</test>'));
      expect(state.errorMessage, isNull);
    });
    
    test('should manage device selection', () {
      final device1 = AndroidDevice(
        id: 'device1',
        name: 'Test Device 1',
        status: DeviceStatus.device,
      );
      
      final device2 = AndroidDevice(
        id: 'device2',
        name: 'Test Device 2',
        status: DeviceStatus.offline,
      );
      
      state.setAvailableDevices([device1, device2]);
      
      expect(state.availableDevices.length, equals(2));
      expect(state.selectedDevice, isNull);
      
      state.selectDevice(device1);
      
      expect(state.selectedDevice, equals(device1));
      expect(state.hasSelectedDevice, isTrue);
      expect(state.isDeviceConnected, isTrue);
    });
    
    test('should handle filter criteria updates', () {
      final criteria = FilterCriteria(
        searchText: 'test',
        showOnlyClickable: true,
      );
      
      state.setFilterCriteria(criteria);
      
      expect(state.filterCriteria, equals(criteria));
      expect(state.hasActiveFilters, isTrue);
    });
    
    test('should manage loading state', () {
      expect(state.isLoading, isFalse);
      
      state.setLoading(true);
      expect(state.isLoading, isTrue);
      expect(state.errorMessage, isNull);
      
      state.setLoading(false);
      expect(state.isLoading, isFalse);
    });
    
    test('should manage error state', () {
      const errorMessage = 'Test error';
      
      state.setError(errorMessage);
      
      expect(state.errorMessage, equals(errorMessage));
      expect(state.hasError, isTrue);
      expect(state.isLoading, isFalse);
      
      state.clearError();
      
      expect(state.errorMessage, isNull);
      expect(state.hasError, isFalse);
    });
    
    test('should toggle XML viewer visibility', () {
      expect(state.isXmlViewerVisible, isFalse);
      
      state.toggleXmlViewer();
      expect(state.isXmlViewerVisible, isTrue);
      
      state.toggleXmlViewer();
      expect(state.isXmlViewerVisible, isFalse);
    });
    
    test('should manage search query', () {
      const query = 'test search';
      
      state.setSearchQuery(query);
      
      expect(state.searchQuery, equals(query));
    });
    
    test('should reset all state', () {
      // Set up some state
      final device = AndroidDevice(id: 'test', name: 'Test');
      final element = UIElement(
        id: 'test',
        depth: 0,
        className: 'View',
        bounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
      
      state.setAvailableDevices([device]);
      state.selectDevice(device);
      state.setUIHierarchy(element);
      state.setLoading(true);
      state.setError('test error');
      
      // Reset
      state.reset();
      
      // Verify everything is reset
      expect(state.rootElement, isNull);
      expect(state.selectedDevice, isNull);
      expect(state.availableDevices, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.hasUIHierarchy, isFalse);
    });
    
    test('should provide statistics', () {
      final stats = state.getStatistics();
      
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('totalElements'), isTrue);
      expect(stats.containsKey('filteredElements'), isTrue);
      expect(stats.containsKey('hasActiveFilters'), isTrue);
      expect(stats.containsKey('availableDevices'), isTrue);
    });
  });
}