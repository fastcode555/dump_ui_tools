import 'package:flutter_test/flutter_test.dart';
import 'package:dump_ui_tools/controllers/filter_controller.dart';
import 'package:dump_ui_tools/models/ui_element.dart';
import 'package:dump_ui_tools/models/filter_criteria.dart';
import 'dart:ui';

void main() {
  group('FilterController Tests', () {
    late FilterController filterController;
    late List<UIElement> testElements;
    
    setUp(() {
      filterController = FilterController();
      
      // Create test elements with various properties
      testElements = [
        UIElement(
          id: 'element1',
          depth: 0,
          className: 'TextView',
          text: 'Login Button',
          clickable: true,
          enabled: true,
          bounds: const Rect.fromLTWH(0, 0, 100, 50),
        ),
        UIElement(
          id: 'element2',
          depth: 1,
          className: 'EditText',
          text: 'Password Field',
          contentDesc: 'Enter password',
          clickable: false,
          enabled: true,
          bounds: const Rect.fromLTWH(0, 60, 100, 40),
        ),
        UIElement(
          id: 'element3',
          depth: 1,
          className: 'Button',
          text: 'Submit',
          resourceId: 'com.example:id/submit_button',
          clickable: true,
          enabled: false,
          bounds: const Rect.fromLTWH(0, 110, 100, 50),
        ),
        UIElement(
          id: 'element4',
          depth: 2,
          className: 'ImageView',
          text: '',
          contentDesc: '',
          clickable: false,
          enabled: true,
          bounds: const Rect.fromLTWH(0, 170, 100, 50),
        ),
      ];
      
      filterController.initialize(testElements);
    });
    
    tearDown(() {
      filterController.dispose();
    });
    
    test('should initialize with all elements', () {
      expect(filterController.totalElements, equals(4));
      expect(filterController.filteredCount, equals(4));
      expect(filterController.hasActiveFilters, isFalse);
      expect(filterController.activeFilterCount, equals(0));
      expect(filterController.filterRatio, equals(1.0));
    });
    
    test('should filter clickable elements', () {
      filterController.toggleClickableFilter();
      
      expect(filterController.hasActiveFilters, isTrue);
      expect(filterController.filteredCount, equals(2)); // Login Button and Submit
      expect(filterController.isFilterActive('clickable'), isTrue);
      
      final filtered = filterController.filteredElements;
      expect(filtered.every((e) => e.clickable), isTrue);
    });
    
    test('should filter input elements', () {
      filterController.toggleInputFilter();
      
      expect(filterController.filteredCount, equals(1)); // Only EditText
      expect(filterController.isFilterActive('input'), isTrue);
      
      final filtered = filterController.filteredElements;
      expect(filtered.first.className, equals('EditText'));
    });
    
    test('should filter elements with text', () {
      filterController.toggleTextFilter();
      
      expect(filterController.filteredCount, equals(3)); // All except ImageView
      expect(filterController.isFilterActive('text'), isTrue);
      
      final filtered = filterController.filteredElements;
      expect(filtered.every((e) => e.text.isNotEmpty || e.contentDesc.isNotEmpty), isTrue);
    });
    
    test('should filter enabled elements', () {
      filterController.toggleEnabledFilter();
      
      expect(filterController.filteredCount, equals(3)); // All except disabled Submit
      expect(filterController.isFilterActive('enabled'), isTrue);
      
      final filtered = filterController.filteredElements;
      expect(filtered.every((e) => e.enabled), isTrue);
    });
    
    test('should combine multiple filters', () {
      filterController.toggleClickableFilter();
      filterController.toggleEnabledFilter();
      
      expect(filterController.filteredCount, equals(1)); // Only Login Button
      expect(filterController.activeFilterCount, equals(2));
      
      final filtered = filterController.filteredElements;
      expect(filtered.first.text, equals('Login Button'));
      expect(filtered.first.clickable, isTrue);
      expect(filtered.first.enabled, isTrue);
    });
    
    test('should add and remove class name filters', () {
      filterController.addClassNameFilter('TextView');
      
      expect(filterController.filteredCount, equals(1)); // Only TextView
      expect(filterController.isFilterActive('className'), isTrue);
      
      filterController.addClassNameFilter('Button');
      
      expect(filterController.filteredCount, equals(2)); // TextView and Button
      
      filterController.removeClassNameFilter('TextView');
      
      expect(filterController.filteredCount, equals(1)); // Only Button
    });
    
    test('should set depth range filter', () {
      filterController.setDepthRange(1, 2);
      
      expect(filterController.filteredCount, equals(3)); // Depth 1 and 2 elements
      expect(filterController.isFilterActive('depth'), isTrue);
      
      final filtered = filterController.filteredElements;
      expect(filtered.every((e) => e.depth >= 1 && e.depth <= 2), isTrue);
    });
    
    test('should set search text filter', () {
      filterController.setSearchText('Button');
      
      expect(filterController.filteredCount, equals(1)); // Only Login Button contains "Button"
      expect(filterController.isFilterActive('search'), isTrue);
    });
    
    test('should clear all filters', () {
      filterController.toggleClickableFilter();
      filterController.toggleInputFilter();
      filterController.setSearchText('test');
      
      expect(filterController.hasActiveFilters, isTrue);
      expect(filterController.activeFilterCount, greaterThan(0));
      
      filterController.clearAllFilters();
      
      expect(filterController.hasActiveFilters, isFalse);
      expect(filterController.activeFilterCount, equals(0));
      expect(filterController.filteredCount, equals(4));
    });
    
    test('should clear specific filter types', () {
      filterController.toggleClickableFilter();
      filterController.toggleInputFilter();
      
      expect(filterController.activeFilterCount, equals(2));
      
      filterController.clearFilter('clickable');
      
      expect(filterController.activeFilterCount, equals(1));
      expect(filterController.isFilterActive('clickable'), isFalse);
      expect(filterController.isFilterActive('input'), isTrue);
    });
    
    test('should create and apply custom filters', () {
      final customCriteria = FilterCriteria(
        showOnlyClickable: true,
        showOnlyWithText: true,
      );
      
      filterController.createCustomFilter('Clickable with Text', customCriteria);
      
      expect(filterController.customFilters.length, equals(1));
      
      final customFilter = filterController.customFilters.first;
      filterController.applyCustomFilter(customFilter.id);
      
      expect(filterController.filteredCount, equals(2)); // Login Button and Submit
    });
    
    test('should delete custom filters', () {
      final customCriteria = FilterCriteria(showOnlyClickable: true);
      filterController.createCustomFilter('Test Filter', customCriteria);
      
      expect(filterController.customFilters.length, equals(1));
      
      final filterId = filterController.customFilters.first.id;
      filterController.deleteCustomFilter(filterId);
      
      expect(filterController.customFilters.length, equals(0));
    });
    
    test('should get suggested class names', () {
      final suggestions = filterController.getSuggestedClassNames();
      
      expect(suggestions.isNotEmpty, isTrue);
      expect(suggestions.contains('TextView'), isTrue);
      expect(suggestions.contains('EditText'), isTrue);
      expect(suggestions.contains('Button'), isTrue);
      expect(suggestions.contains('ImageView'), isTrue);
    });
    
    test('should get suggested resource IDs', () {
      final suggestions = filterController.getSuggestedResourceIds();
      
      expect(suggestions.contains('submit_button'), isTrue);
    });
    
    test('should provide filter match counts', () {
      expect(filterController.getFilterMatchCount('clickable'), equals(2));
      expect(filterController.getFilterMatchCount('input'), equals(1));
      expect(filterController.getFilterMatchCount('text'), equals(3));
      expect(filterController.getFilterMatchCount('enabled'), equals(3));
    });
    
    test('should validate filter criteria', () {
      expect(filterController.validateCriteria(), isTrue);
      
      // Set invalid depth range
      filterController.setDepthRange(5, 2); // min > max
      
      expect(filterController.validateCriteria(), isFalse);
      expect(filterController.getValidationError(), isNotNull);
    });
    
    test('should export and import criteria', () {
      filterController.toggleClickableFilter();
      filterController.setSearchText('test');
      
      final exported = filterController.exportCriteria();
      
      expect(exported, isA<Map<String, dynamic>>());
      expect(exported['showOnlyClickable'], isTrue);
      expect(exported['searchText'], equals('test'));
      
      filterController.clearAllFilters();
      expect(filterController.hasActiveFilters, isFalse);
      
      filterController.importCriteria(exported);
      
      expect(filterController.hasActiveFilters, isTrue);
      expect(filterController.isFilterActive('clickable'), isTrue);
    });
    
    test('should provide filter statistics', () {
      filterController.toggleClickableFilter();
      
      final stats = filterController.getFilterStatistics();
      
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('totalElements'), isTrue);
      expect(stats.containsKey('filteredElements'), isTrue);
      expect(stats.containsKey('filterRatio'), isTrue);
      expect(stats.containsKey('activeFilters'), isTrue);
      expect(stats.containsKey('filterDuration'), isTrue);
      expect(stats['totalElements'], equals(4));
      expect(stats['activeFilters'], equals(1));
    });
    
    test('should update elements and recalculate filters', () {
      filterController.toggleClickableFilter();
      expect(filterController.filteredCount, equals(2));
      
      // Add more elements
      final newElements = [
        ...testElements,
        UIElement(
          id: 'element5',
          depth: 0,
          className: 'TextView',
          text: 'New Button',
          clickable: true,
          enabled: true,
          bounds: const Rect.fromLTWH(0, 220, 100, 50),
        ),
      ];
      
      filterController.updateElements(newElements);
      
      expect(filterController.totalElements, equals(5));
      expect(filterController.filteredCount, equals(3)); // Now 3 clickable elements
    });
    
    test('should reset all state', () {
      filterController.toggleClickableFilter();
      filterController.setSearchText('test');
      filterController.createCustomFilter('Test', FilterCriteria(showOnlyClickable: true));
      
      expect(filterController.hasActiveFilters, isTrue);
      expect(filterController.customFilters.isNotEmpty, isTrue);
      
      filterController.reset();
      
      expect(filterController.hasActiveFilters, isFalse);
      expect(filterController.totalElements, equals(0));
      expect(filterController.filteredCount, equals(0));
      expect(filterController.customFilters.isEmpty, isTrue);
    });
  });
  
  group('FilterableUIElement Extension Tests', () {
    late UIElement testElement;
    
    setUp(() {
      testElement = UIElement(
        id: 'test',
        depth: 1,
        className: 'TextView',
        text: 'Test Button',
        clickable: true,
        enabled: true,
        bounds: const Rect.fromLTWH(0, 0, 100, 50),
      );
    });
    
    test('should match all criteria', () {
      final criteria1 = FilterCriteria(showOnlyClickable: true);
      final criteria2 = FilterCriteria(showOnlyWithText: true);
      
      expect(testElement.matchesAllCriteria([criteria1, criteria2]), isTrue);
      
      final criteria3 = FilterCriteria(showOnlyInputs: true);
      expect(testElement.matchesAllCriteria([criteria1, criteria3]), isFalse);
    });
    
    test('should match any criteria', () {
      final criteria1 = FilterCriteria(showOnlyInputs: true); // Won't match
      final criteria2 = FilterCriteria(showOnlyClickable: true); // Will match
      
      expect(testElement.matchesAnyCriteria([criteria1, criteria2]), isTrue);
      
      final criteria3 = FilterCriteria(showOnlyInputs: true);
      expect(testElement.matchesAnyCriteria([criteria1, criteria3]), isFalse);
    });
    
    test('should calculate match score', () {
      final criteria = FilterCriteria(
        searchText: 'Test',
        showOnlyClickable: true,
      );
      
      final score = testElement.getMatchScore(criteria);
      
      expect(score, greaterThan(0.0));
      expect(score, greaterThan(1.0)); // Base score + bonuses
    });
  });
}