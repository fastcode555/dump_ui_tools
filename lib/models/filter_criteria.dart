import 'ui_element.dart';

/// Represents search and filter criteria for UI elements
class FilterCriteria {
  /// Text to search for in element text or content description
  final String searchText;
  
  /// Whether to show only clickable elements
  final bool showOnlyClickable;
  
  /// Whether to show only input elements (EditText, etc.)
  final bool showOnlyInputs;
  
  /// Whether to show only elements with text content
  final bool showOnlyWithText;
  
  /// Set of class names to filter by
  final Set<String> classNameFilters;
  
  /// Set of resource IDs to filter by
  final Set<String> resourceIdFilters;
  
  /// Set of package names to filter by
  final Set<String> packageNameFilters;
  
  /// Whether to use case-sensitive search
  final bool caseSensitive;
  
  /// Whether to use exact match for text search
  final bool exactMatch;
  
  /// Minimum depth level to show
  final int? minDepth;
  
  /// Maximum depth level to show
  final int? maxDepth;
  
  /// Whether to show enabled elements only
  final bool enabledOnly;
  
  /// Constructor
  const FilterCriteria({
    this.searchText = '',
    this.showOnlyClickable = false,
    this.showOnlyInputs = false,
    this.showOnlyWithText = false,
    this.classNameFilters = const {},
    this.resourceIdFilters = const {},
    this.packageNameFilters = const {},
    this.caseSensitive = false,
    this.exactMatch = false,
    this.minDepth,
    this.maxDepth,
    this.enabledOnly = false,
  });
  
  /// Create empty filter criteria
  static const FilterCriteria empty = FilterCriteria();
  
  /// Check if any filters are active
  bool get hasActiveFilters {
    return searchText.isNotEmpty ||
           showOnlyClickable ||
           showOnlyInputs ||
           showOnlyWithText ||
           classNameFilters.isNotEmpty ||
           resourceIdFilters.isNotEmpty ||
           packageNameFilters.isNotEmpty ||
           minDepth != null ||
           maxDepth != null ||
           enabledOnly;
  }
  
  /// Get count of active filters
  int get activeFilterCount {
    int count = 0;
    if (searchText.isNotEmpty) count++;
    if (showOnlyClickable) count++;
    if (showOnlyInputs) count++;
    if (showOnlyWithText) count++;
    if (classNameFilters.isNotEmpty) count++;
    if (resourceIdFilters.isNotEmpty) count++;
    if (packageNameFilters.isNotEmpty) count++;
    if (minDepth != null) count++;
    if (maxDepth != null) count++;
    if (enabledOnly) count++;
    return count;
  }
  
  /// Check if an element matches the filter criteria
  bool matches(UIElement element) {
    // Text search filter
    if (searchText.isNotEmpty) {
      if (!_matchesTextSearch(element)) {
        return false;
      }
    }
    
    // Clickable filter
    if (showOnlyClickable && !element.clickable) {
      return false;
    }
    
    // Input elements filter
    if (showOnlyInputs && !_isInputElement(element)) {
      return false;
    }
    
    // Elements with text filter
    if (showOnlyWithText && !_hasText(element)) {
      return false;
    }
    
    // Class name filter
    if (classNameFilters.isNotEmpty && !_matchesClassName(element)) {
      return false;
    }
    
    // Resource ID filter
    if (resourceIdFilters.isNotEmpty && !_matchesResourceId(element)) {
      return false;
    }
    
    // Package name filter
    if (packageNameFilters.isNotEmpty && !_matchesPackageName(element)) {
      return false;
    }
    
    // Depth filters
    if (minDepth != null && element.depth < minDepth!) {
      return false;
    }
    
    if (maxDepth != null && element.depth > maxDepth!) {
      return false;
    }
    
    // Enabled filter
    if (enabledOnly && !element.enabled) {
      return false;
    }
    
    return true;
  }
  
  bool _matchesTextSearch(UIElement element) {
    final searchLower = caseSensitive ? searchText : searchText.toLowerCase();
    final textToSearch = caseSensitive ? element.text : element.text.toLowerCase();
    final contentDescToSearch = caseSensitive ? element.contentDesc : element.contentDesc.toLowerCase();
    
    if (exactMatch) {
      return textToSearch == searchLower || contentDescToSearch == searchLower;
    } else {
      return textToSearch.contains(searchLower) || contentDescToSearch.contains(searchLower);
    }
  }
  
  bool _isInputElement(UIElement element) {
    return element.className.contains('EditText') || 
           element.className.contains('TextInputLayout') ||
           element.className.contains('AutoCompleteTextView');
  }
  
  bool _hasText(UIElement element) {
    return element.text.isNotEmpty || element.contentDesc.isNotEmpty;
  }
  
  bool _matchesClassName(UIElement element) {
    return classNameFilters.any((filter) => element.className.contains(filter));
  }
  
  bool _matchesResourceId(UIElement element) {
    return resourceIdFilters.any((filter) => element.resourceId.contains(filter));
  }
  
  bool _matchesPackageName(UIElement element) {
    return packageNameFilters.any((filter) => element.packageName.contains(filter));
  }
  
  /// Filter a list of UI elements
  List<UIElement> filterElements(List<UIElement> elements) {
    if (!hasActiveFilters) {
      return elements;
    }
    
    return elements.where(matches).toList();
  }
  
  /// Create a copy with updated search text
  FilterCriteria copyWithSearchText(String newSearchText) {
    return FilterCriteria(
      searchText: newSearchText,
      showOnlyClickable: showOnlyClickable,
      showOnlyInputs: showOnlyInputs,
      showOnlyWithText: showOnlyWithText,
      classNameFilters: classNameFilters,
      resourceIdFilters: resourceIdFilters,
      packageNameFilters: packageNameFilters,
      caseSensitive: caseSensitive,
      exactMatch: exactMatch,
      minDepth: minDepth,
      maxDepth: maxDepth,
      enabledOnly: enabledOnly,
    );
  }
  
  /// Create a copy with updated clickable filter
  FilterCriteria copyWithClickableFilter(bool showClickable) {
    return FilterCriteria(
      searchText: searchText,
      showOnlyClickable: showClickable,
      showOnlyInputs: showOnlyInputs,
      showOnlyWithText: showOnlyWithText,
      classNameFilters: classNameFilters,
      resourceIdFilters: resourceIdFilters,
      packageNameFilters: packageNameFilters,
      caseSensitive: caseSensitive,
      exactMatch: exactMatch,
      minDepth: minDepth,
      maxDepth: maxDepth,
      enabledOnly: enabledOnly,
    );
  }
  
  /// Create a copy with updated input filter
  FilterCriteria copyWithInputFilter(bool showInputs) {
    return FilterCriteria(
      searchText: searchText,
      showOnlyClickable: showOnlyClickable,
      showOnlyInputs: showInputs,
      showOnlyWithText: showOnlyWithText,
      classNameFilters: classNameFilters,
      resourceIdFilters: resourceIdFilters,
      packageNameFilters: packageNameFilters,
      caseSensitive: caseSensitive,
      exactMatch: exactMatch,
      minDepth: minDepth,
      maxDepth: maxDepth,
      enabledOnly: enabledOnly,
    );
  }
  
  /// Create a copy with updated text filter
  FilterCriteria copyWithTextFilter(bool showWithText) {
    return FilterCriteria(
      searchText: searchText,
      showOnlyClickable: showOnlyClickable,
      showOnlyInputs: showOnlyInputs,
      showOnlyWithText: showWithText,
      classNameFilters: classNameFilters,
      resourceIdFilters: resourceIdFilters,
      packageNameFilters: packageNameFilters,
      caseSensitive: caseSensitive,
      exactMatch: exactMatch,
      minDepth: minDepth,
      maxDepth: maxDepth,
      enabledOnly: enabledOnly,
    );
  }
  
  /// Create a copy with updated class name filters
  FilterCriteria copyWithClassNameFilters(Set<String> newFilters) {
    return FilterCriteria(
      searchText: searchText,
      showOnlyClickable: showOnlyClickable,
      showOnlyInputs: showOnlyInputs,
      showOnlyWithText: showOnlyWithText,
      classNameFilters: newFilters,
      resourceIdFilters: resourceIdFilters,
      packageNameFilters: packageNameFilters,
      caseSensitive: caseSensitive,
      exactMatch: exactMatch,
      minDepth: minDepth,
      maxDepth: maxDepth,
      enabledOnly: enabledOnly,
    );
  }
  
  /// Add a class name filter
  FilterCriteria addClassNameFilter(String className) {
    final newFilters = Set<String>.from(classNameFilters)..add(className);
    return copyWithClassNameFilters(newFilters);
  }
  
  /// Remove a class name filter
  FilterCriteria removeClassNameFilter(String className) {
    final newFilters = Set<String>.from(classNameFilters)..remove(className);
    return copyWithClassNameFilters(newFilters);
  }
  
  /// Create a copy with updated resource ID filters
  FilterCriteria copyWithResourceIdFilters(Set<String> newFilters) {
    return FilterCriteria(
      searchText: searchText,
      showOnlyClickable: showOnlyClickable,
      showOnlyInputs: showOnlyInputs,
      showOnlyWithText: showOnlyWithText,
      classNameFilters: classNameFilters,
      resourceIdFilters: newFilters,
      packageNameFilters: packageNameFilters,
      caseSensitive: caseSensitive,
      exactMatch: exactMatch,
      minDepth: minDepth,
      maxDepth: maxDepth,
      enabledOnly: enabledOnly,
    );
  }
  
  /// Create a copy with depth range
  FilterCriteria copyWithDepthRange(int? minDepth, int? maxDepth) {
    return FilterCriteria(
      searchText: searchText,
      showOnlyClickable: showOnlyClickable,
      showOnlyInputs: showOnlyInputs,
      showOnlyWithText: showOnlyWithText,
      classNameFilters: classNameFilters,
      resourceIdFilters: resourceIdFilters,
      packageNameFilters: packageNameFilters,
      caseSensitive: caseSensitive,
      exactMatch: exactMatch,
      minDepth: minDepth,
      maxDepth: maxDepth,
      enabledOnly: enabledOnly,
    );
  }
  
  /// Create a copy with all parameters
  FilterCriteria copyWith({
    String? searchText,
    bool? showOnlyClickable,
    bool? showOnlyInputs,
    bool? showOnlyWithText,
    Set<String>? classNameFilters,
    Set<String>? resourceIdFilters,
    Set<String>? packageNameFilters,
    bool? caseSensitive,
    bool? exactMatch,
    int? minDepth,
    int? maxDepth,
    bool? enabledOnly,
  }) {
    return FilterCriteria(
      searchText: searchText ?? this.searchText,
      showOnlyClickable: showOnlyClickable ?? this.showOnlyClickable,
      showOnlyInputs: showOnlyInputs ?? this.showOnlyInputs,
      showOnlyWithText: showOnlyWithText ?? this.showOnlyWithText,
      classNameFilters: classNameFilters ?? this.classNameFilters,
      resourceIdFilters: resourceIdFilters ?? this.resourceIdFilters,
      packageNameFilters: packageNameFilters ?? this.packageNameFilters,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      exactMatch: exactMatch ?? this.exactMatch,
      minDepth: minDepth ?? this.minDepth,
      maxDepth: maxDepth ?? this.maxDepth,
      enabledOnly: enabledOnly ?? this.enabledOnly,
    );
  }
  
  /// Clear all filters
  FilterCriteria clearAll() {
    return const FilterCriteria();
  }
  
  /// Validate filter criteria
  bool isValid() {
    // Check depth range validity
    if (minDepth != null && maxDepth != null && minDepth! > maxDepth!) {
      return false;
    }
    
    // Check for negative depth values
    if (minDepth != null && minDepth! < 0) {
      return false;
    }
    
    if (maxDepth != null && maxDepth! < 0) {
      return false;
    }
    
    return true;
  }
  
  /// Get validation error message
  String? getValidationError() {
    if (minDepth != null && maxDepth != null && minDepth! > maxDepth!) {
      return '最小深度不能大于最大深度';
    }
    
    if (minDepth != null && minDepth! < 0) {
      return '最小深度不能为负数';
    }
    
    if (maxDepth != null && maxDepth! < 0) {
      return '最大深度不能为负数';
    }
    
    return null;
  }
  
  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'searchText': searchText,
      'showOnlyClickable': showOnlyClickable,
      'showOnlyInputs': showOnlyInputs,
      'showOnlyWithText': showOnlyWithText,
      'classNameFilters': classNameFilters.toList(),
      'resourceIdFilters': resourceIdFilters.toList(),
      'packageNameFilters': packageNameFilters.toList(),
      'caseSensitive': caseSensitive,
      'exactMatch': exactMatch,
      'minDepth': minDepth,
      'maxDepth': maxDepth,
      'enabledOnly': enabledOnly,
    };
  }
  
  /// Create from JSON map
  static FilterCriteria fromJson(Map<String, dynamic> json) {
    return FilterCriteria(
      searchText: json['searchText'] as String? ?? '',
      showOnlyClickable: json['showOnlyClickable'] as bool? ?? false,
      showOnlyInputs: json['showOnlyInputs'] as bool? ?? false,
      showOnlyWithText: json['showOnlyWithText'] as bool? ?? false,
      classNameFilters: Set<String>.from(json['classNameFilters'] as List? ?? []),
      resourceIdFilters: Set<String>.from(json['resourceIdFilters'] as List? ?? []),
      packageNameFilters: Set<String>.from(json['packageNameFilters'] as List? ?? []),
      caseSensitive: json['caseSensitive'] as bool? ?? false,
      exactMatch: json['exactMatch'] as bool? ?? false,
      minDepth: json['minDepth'] as int?,
      maxDepth: json['maxDepth'] as int?,
      enabledOnly: json['enabledOnly'] as bool? ?? false,
    );
  }
  
  @override
  String toString() {
    return 'FilterCriteria(searchText: "$searchText", activeFilters: $activeFilterCount)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterCriteria &&
           other.searchText == searchText &&
           other.showOnlyClickable == showOnlyClickable &&
           other.showOnlyInputs == showOnlyInputs &&
           other.showOnlyWithText == showOnlyWithText &&
           other.classNameFilters.length == classNameFilters.length &&
           other.classNameFilters.containsAll(classNameFilters) &&
           other.resourceIdFilters.length == resourceIdFilters.length &&
           other.resourceIdFilters.containsAll(resourceIdFilters) &&
           other.packageNameFilters.length == packageNameFilters.length &&
           other.packageNameFilters.containsAll(packageNameFilters) &&
           other.caseSensitive == caseSensitive &&
           other.exactMatch == exactMatch &&
           other.minDepth == minDepth &&
           other.maxDepth == maxDepth &&
           other.enabledOnly == enabledOnly;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      searchText,
      showOnlyClickable,
      showOnlyInputs,
      showOnlyWithText,
      classNameFilters,
      resourceIdFilters,
      packageNameFilters,
      caseSensitive,
      exactMatch,
      minDepth,
      maxDepth,
      enabledOnly,
    );
  }
}