import 'package:flutter/foundation.dart';
import '../models/ui_element.dart';
import '../models/filter_criteria.dart';

/// Represents a filter option that can be toggled on/off
class FilterOption {
  final String id;
  final String label;
  final String description;
  final bool isActive;
  final int matchCount;
  
  const FilterOption({
    required this.id,
    required this.label,
    required this.description,
    required this.isActive,
    this.matchCount = 0,
  });
  
  FilterOption copyWith({
    String? id,
    String? label,
    String? description,
    bool? isActive,
    int? matchCount,
  }) {
    return FilterOption(
      id: id ?? this.id,
      label: label ?? this.label,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      matchCount: matchCount ?? this.matchCount,
    );
  }
}

/// Represents a custom filter with advanced options
class CustomFilter {
  final String id;
  final String name;
  final FilterCriteria criteria;
  final DateTime createdAt;
  final bool isBuiltIn;
  
  const CustomFilter({
    required this.id,
    required this.name,
    required this.criteria,
    required this.createdAt,
    this.isBuiltIn = false,
  });
}

/// Controller for managing various filter conditions and combinations
class FilterController extends ChangeNotifier {
  // Private fields
  FilterCriteria _criteria = FilterCriteria.empty;
  List<UIElement> _allElements = [];
  List<UIElement> _filteredElements = [];
  List<FilterOption> _availableFilters = [];
  List<CustomFilter> _customFilters = [];
  Map<String, int> _filterMatchCounts = {};
  
  // Filter statistics
  int _totalElements = 0;
  int _filteredCount = 0;
  Duration _lastFilterDuration = Duration.zero;
  
  // Getters
  FilterCriteria get criteria => _criteria;
  List<UIElement> get filteredElements => List.unmodifiable(_filteredElements);
  List<FilterOption> get availableFilters => List.unmodifiable(_availableFilters);
  List<CustomFilter> get customFilters => List.unmodifiable(_customFilters);
  Map<String, int> get filterMatchCounts => Map.unmodifiable(_filterMatchCounts);
  
  bool get hasActiveFilters => _criteria.hasActiveFilters;
  int get activeFilterCount => _criteria.activeFilterCount;
  int get totalElements => _totalElements;
  int get filteredCount => _filteredCount;
  double get filterRatio => _totalElements > 0 ? _filteredCount / _totalElements : 0.0;
  Duration get lastFilterDuration => _lastFilterDuration;
  
  /// Initialize the controller with elements
  void initialize(List<UIElement> elements) {
    _allElements = List.from(elements);
    _totalElements = elements.length;
    _initializeAvailableFilters();
    _applyFilters();
  }
  
  /// Update the elements list
  void updateElements(List<UIElement> elements) {
    _allElements = List.from(elements);
    _totalElements = elements.length;
    _updateFilterMatchCounts();
    _applyFilters();
  }
  
  /// Set filter criteria
  void setCriteria(FilterCriteria newCriteria) {
    if (_criteria != newCriteria) {
      _criteria = newCriteria;
      _updateAvailableFilters();
      _applyFilters();
      notifyListeners();
    }
  }
  
  /// Toggle clickable elements filter
  void toggleClickableFilter() {
    final newCriteria = _criteria.copyWithClickableFilter(!_criteria.showOnlyClickable);
    setCriteria(newCriteria);
  }
  
  /// Toggle input elements filter
  void toggleInputFilter() {
    final newCriteria = _criteria.copyWithInputFilter(!_criteria.showOnlyInputs);
    setCriteria(newCriteria);
  }
  
  /// Toggle elements with text filter
  void toggleTextFilter() {
    final newCriteria = _criteria.copyWithTextFilter(!_criteria.showOnlyWithText);
    setCriteria(newCriteria);
  }
  
  /// Toggle enabled elements filter
  void toggleEnabledFilter() {
    final newCriteria = _criteria.copyWith(enabledOnly: !_criteria.enabledOnly);
    setCriteria(newCriteria);
  }
  
  /// Add class name filter
  void addClassNameFilter(String className) {
    final newCriteria = _criteria.addClassNameFilter(className);
    setCriteria(newCriteria);
  }
  
  /// Remove class name filter
  void removeClassNameFilter(String className) {
    final newCriteria = _criteria.removeClassNameFilter(className);
    setCriteria(newCriteria);
  }
  
  /// Set class name filters
  void setClassNameFilters(Set<String> classNames) {
    final newCriteria = _criteria.copyWithClassNameFilters(classNames);
    setCriteria(newCriteria);
  }
  
  /// Set resource ID filters
  void setResourceIdFilters(Set<String> resourceIds) {
    final newCriteria = _criteria.copyWithResourceIdFilters(resourceIds);
    setCriteria(newCriteria);
  }
  
  /// Set depth range filter
  void setDepthRange(int? minDepth, int? maxDepth) {
    final newCriteria = _criteria.copyWithDepthRange(minDepth, maxDepth);
    setCriteria(newCriteria);
  }
  
  /// Set search text filter
  void setSearchText(String searchText) {
    final newCriteria = _criteria.copyWithSearchText(searchText);
    setCriteria(newCriteria);
  }
  
  /// Clear all filters
  void clearAllFilters() {
    setCriteria(FilterCriteria.empty);
  }
  
  /// Clear specific filter type
  void clearFilter(String filterType) {
    FilterCriteria newCriteria;
    
    switch (filterType) {
      case 'clickable':
        newCriteria = _criteria.copyWithClickableFilter(false);
        break;
      case 'input':
        newCriteria = _criteria.copyWithInputFilter(false);
        break;
      case 'text':
        newCriteria = _criteria.copyWithTextFilter(false);
        break;
      case 'enabled':
        newCriteria = _criteria.copyWith(enabledOnly: false);
        break;
      case 'className':
        newCriteria = _criteria.copyWithClassNameFilters({});
        break;
      case 'resourceId':
        newCriteria = _criteria.copyWithResourceIdFilters({});
        break;
      case 'depth':
        newCriteria = _criteria.copyWithDepthRange(null, null);
        break;
      case 'search':
        newCriteria = _criteria.copyWithSearchText('');
        break;
      default:
        return;
    }
    
    setCriteria(newCriteria);
  }
  
  /// Create a custom filter
  void createCustomFilter(String name, FilterCriteria criteria) {
    final customFilter = CustomFilter(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      criteria: criteria,
      createdAt: DateTime.now(),
    );
    
    _customFilters.add(customFilter);
    notifyListeners();
  }
  
  /// Apply a custom filter
  void applyCustomFilter(String filterId) {
    final filter = _customFilters.cast<CustomFilter?>().firstWhere(
      (f) => f?.id == filterId,
      orElse: () => null,
    );
    
    if (filter != null) {
      setCriteria(filter.criteria);
    }
  }
  
  /// Delete a custom filter
  void deleteCustomFilter(String filterId) {
    _customFilters.removeWhere((filter) => filter.id == filterId);
    notifyListeners();
  }
  
  /// Get suggested class name filters based on current elements
  List<String> getSuggestedClassNames() {
    final classNames = <String, int>{};
    
    for (final element in _allElements) {
      final className = element.className.split('.').last; // Get simple class name
      classNames[className] = (classNames[className] ?? 0) + 1;
    }
    
    // Return class names sorted by frequency
    final sortedEntries = classNames.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.take(20).map((e) => e.key).toList();
  }
  
  /// Get suggested resource ID filters
  List<String> getSuggestedResourceIds() {
    final resourceIds = <String, int>{};
    
    for (final element in _allElements) {
      if (element.resourceId.isNotEmpty) {
        // Extract the ID part after the last '/'
        final parts = element.resourceId.split('/');
        if (parts.length > 1) {
          final id = parts.last;
          resourceIds[id] = (resourceIds[id] ?? 0) + 1;
        }
      }
    }
    
    final sortedEntries = resourceIds.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.take(20).map((e) => e.key).toList();
  }
  
  /// Get filter statistics
  Map<String, dynamic> getFilterStatistics() {
    return {
      'totalElements': _totalElements,
      'filteredElements': _filteredCount,
      'filterRatio': filterRatio,
      'activeFilters': activeFilterCount,
      'filterDuration': _lastFilterDuration.inMilliseconds,
      'availableFilters': _availableFilters.length,
      'customFilters': _customFilters.length,
      'matchCounts': _filterMatchCounts,
    };
  }
  
  /// Check if a specific filter is active
  bool isFilterActive(String filterType) {
    switch (filterType) {
      case 'clickable':
        return _criteria.showOnlyClickable;
      case 'input':
        return _criteria.showOnlyInputs;
      case 'text':
        return _criteria.showOnlyWithText;
      case 'enabled':
        return _criteria.enabledOnly;
      case 'className':
        return _criteria.classNameFilters.isNotEmpty;
      case 'resourceId':
        return _criteria.resourceIdFilters.isNotEmpty;
      case 'depth':
        return _criteria.minDepth != null || _criteria.maxDepth != null;
      case 'search':
        return _criteria.searchText.isNotEmpty;
      default:
        return false;
    }
  }
  
  /// Get count of elements that would match a specific filter
  int getFilterMatchCount(String filterType) {
    return _filterMatchCounts[filterType] ?? 0;
  }
  
  /// Validate current filter criteria
  bool validateCriteria() {
    return _criteria.isValid();
  }
  
  /// Get validation error message
  String? getValidationError() {
    return _criteria.getValidationError();
  }
  
  /// Export current filter criteria
  Map<String, dynamic> exportCriteria() {
    return _criteria.toJson();
  }
  
  /// Import filter criteria
  void importCriteria(Map<String, dynamic> json) {
    try {
      final criteria = FilterCriteria.fromJson(json);
      setCriteria(criteria);
    } catch (e) {
      // Handle import error
      debugPrint('Error importing filter criteria: $e');
    }
  }
  
  /// Private method to initialize available filters
  void _initializeAvailableFilters() {
    _availableFilters = [
      const FilterOption(
        id: 'clickable',
        label: '可点击元素',
        description: '只显示可以点击的UI元素',
        isActive: false,
      ),
      const FilterOption(
        id: 'input',
        label: '输入框',
        description: '只显示输入框类型的元素',
        isActive: false,
      ),
      const FilterOption(
        id: 'text',
        label: '有文本元素',
        description: '只显示包含文本或内容描述的元素',
        isActive: false,
      ),
      const FilterOption(
        id: 'enabled',
        label: '启用元素',
        description: '只显示启用状态的元素',
        isActive: false,
      ),
    ];
    
    _updateFilterMatchCounts();
  }
  
  /// Private method to update available filters based on current criteria
  void _updateAvailableFilters() {
    _availableFilters = _availableFilters.map((filter) {
      bool isActive;
      switch (filter.id) {
        case 'clickable':
          isActive = _criteria.showOnlyClickable;
          break;
        case 'input':
          isActive = _criteria.showOnlyInputs;
          break;
        case 'text':
          isActive = _criteria.showOnlyWithText;
          break;
        case 'enabled':
          isActive = _criteria.enabledOnly;
          break;
        default:
          isActive = false;
      }
      
      return filter.copyWith(
        isActive: isActive,
        matchCount: _filterMatchCounts[filter.id] ?? 0,
      );
    }).toList();
  }
  
  /// Private method to update filter match counts
  void _updateFilterMatchCounts() {
    _filterMatchCounts.clear();
    
    // Count clickable elements
    _filterMatchCounts['clickable'] = _allElements.where((e) => e.clickable).length;
    
    // Count input elements
    _filterMatchCounts['input'] = _allElements.where((e) => 
        e.className.contains('EditText') || 
        e.className.contains('TextInputLayout')).length;
    
    // Count elements with text
    _filterMatchCounts['text'] = _allElements.where((e) => 
        e.text.isNotEmpty || e.contentDesc.isNotEmpty).length;
    
    // Count enabled elements
    _filterMatchCounts['enabled'] = _allElements.where((e) => e.enabled).length;
  }
  
  /// Private method to apply current filters
  void _applyFilters() {
    final stopwatch = Stopwatch()..start();
    
    if (!_criteria.hasActiveFilters) {
      _filteredElements = List.from(_allElements);
    } else {
      _filteredElements = _criteria.filterElements(_allElements);
    }
    
    _filteredCount = _filteredElements.length;
    
    stopwatch.stop();
    _lastFilterDuration = stopwatch.elapsed;
  }
  
  /// Reset all filters and state
  void reset() {
    _criteria = FilterCriteria.empty;
    _allElements.clear();
    _filteredElements.clear();
    _customFilters.clear();
    _filterMatchCounts.clear();
    _totalElements = 0;
    _filteredCount = 0;
    _lastFilterDuration = Duration.zero;
    
    _initializeAvailableFilters();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _allElements.clear();
    _filteredElements.clear();
    _availableFilters.clear();
    _customFilters.clear();
    _filterMatchCounts.clear();
    super.dispose();
  }
}

/// Extension methods for filter functionality
extension FilterableUIElement on UIElement {
  /// Check if this element matches multiple filter criteria
  bool matchesAllCriteria(List<FilterCriteria> criteriaList) {
    return criteriaList.every((criteria) => criteria.matches(this));
  }
  
  /// Check if this element matches any of the filter criteria
  bool matchesAnyCriteria(List<FilterCriteria> criteriaList) {
    return criteriaList.any((criteria) => criteria.matches(this));
  }
  
  /// Get a score indicating how well this element matches the criteria
  double getMatchScore(FilterCriteria criteria) {
    double score = 0.0;
    
    // Base score for matching
    if (criteria.matches(this)) {
      score += 1.0;
    }
    
    // Bonus for text matches
    if (criteria.searchText.isNotEmpty) {
      final query = criteria.searchText.toLowerCase();
      if (text.toLowerCase().contains(query)) {
        score += 0.5;
      }
      if (contentDesc.toLowerCase().contains(query)) {
        score += 0.3;
      }
    }
    
    // Bonus for specific element types
    if (criteria.showOnlyClickable && clickable) {
      score += 0.2;
    }
    
    if (criteria.showOnlyInputs && className.contains('EditText')) {
      score += 0.2;
    }
    
    return score;
  }
}