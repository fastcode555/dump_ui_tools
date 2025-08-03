import 'dart:ui';

/// Represents a UI element from Android UI hierarchy
class UIElement {
  /// Unique identifier for this element
  final String id;
  
  /// Depth level in the hierarchy tree
  final int depth;
  
  /// Text content of the element
  final String text;
  
  /// Content description for accessibility
  final String contentDesc;
  
  /// Class name of the UI element (e.g., TextView, Button)
  final String className;
  
  /// Package name of the app containing this element
  final String packageName;
  
  /// Resource ID of the element
  final String resourceId;
  
  /// Whether the element is clickable
  final bool clickable;
  
  /// Whether the element is enabled
  final bool enabled;
  
  /// Bounds rectangle of the element on screen
  final Rect bounds;
  
  /// Index of this element among its siblings
  final int index;
  
  /// List of child elements
  final List<UIElement> _children = [];
  
  /// Parent element (null for root)
  UIElement? _parent;
  
  /// Constructor
  UIElement({
    required this.id,
    required this.depth,
    this.text = '',
    this.contentDesc = '',
    required this.className,
    this.packageName = '',
    this.resourceId = '',
    this.clickable = false,
    this.enabled = true,
    required this.bounds,
    this.index = 0,
    UIElement? parent,
  }) : _parent = parent;
  
  /// Get parent element
  UIElement? get parent => _parent;
  
  /// Get immutable list of children
  List<UIElement> get children => List.unmodifiable(_children);
  
  /// Check if this element has children
  bool get hasChildren => _children.isNotEmpty;
  
  /// Get the number of children
  int get childCount => _children.length;
  
  /// Add a child element
  void addChild(UIElement child) {
    if (!_children.contains(child)) {
      _children.add(child);
      child._parent = this;
    }
  }
  
  /// Remove a child element
  bool removeChild(UIElement child) {
    final removed = _children.remove(child);
    if (removed) {
      child._parent = null;
    }
    return removed;
  }
  
  /// Remove child at specific index
  UIElement? removeChildAt(int index) {
    if (index >= 0 && index < _children.length) {
      final child = _children.removeAt(index);
      child._parent = null;
      return child;
    }
    return null;
  }
  
  /// Clear all children
  void clearChildren() {
    for (final child in _children) {
      child._parent = null;
    }
    _children.clear();
  }
  
  /// Find elements by text content (case-insensitive)
  List<UIElement> findByText(String searchText, {bool exactMatch = false}) {
    final results = <UIElement>[];
    _findByTextRecursive(searchText, results, exactMatch);
    return results;
  }
  
  void _findByTextRecursive(String searchText, List<UIElement> results, bool exactMatch) {
    final searchLower = searchText.toLowerCase();
    final textLower = text.toLowerCase();
    final contentDescLower = contentDesc.toLowerCase();
    
    bool matches = false;
    if (exactMatch) {
      matches = textLower == searchLower || contentDescLower == searchLower;
    } else {
      matches = textLower.contains(searchLower) || contentDescLower.contains(searchLower);
    }
    
    if (matches) {
      results.add(this);
    }
    
    for (final child in _children) {
      child._findByTextRecursive(searchText, results, exactMatch);
    }
  }
  
  /// Find elements by resource ID
  List<UIElement> findByResourceId(String resourceIdPattern) {
    final results = <UIElement>[];
    _findByResourceIdRecursive(resourceIdPattern, results);
    return results;
  }
  
  void _findByResourceIdRecursive(String resourceIdPattern, List<UIElement> results) {
    if (resourceId.contains(resourceIdPattern)) {
      results.add(this);
    }
    
    for (final child in _children) {
      child._findByResourceIdRecursive(resourceIdPattern, results);
    }
  }
  
  /// Find elements by class name
  List<UIElement> findByClassName(String classNamePattern) {
    final results = <UIElement>[];
    _findByClassNameRecursive(classNamePattern, results);
    return results;
  }
  
  void _findByClassNameRecursive(String classNamePattern, List<UIElement> results) {
    if (className.contains(classNamePattern)) {
      results.add(this);
    }
    
    for (final child in _children) {
      child._findByClassNameRecursive(classNamePattern, results);
    }
  }
  
  /// Find clickable elements
  List<UIElement> findClickableElements() {
    final results = <UIElement>[];
    _findClickableRecursive(results);
    return results;
  }
  
  void _findClickableRecursive(List<UIElement> results) {
    if (clickable) {
      results.add(this);
    }
    
    for (final child in _children) {
      child._findClickableRecursive(results);
    }
  }
  
  /// Find input elements (EditText, etc.)
  List<UIElement> findInputElements() {
    final results = <UIElement>[];
    _findInputRecursive(results);
    return results;
  }
  
  void _findInputRecursive(List<UIElement> results) {
    if (className.contains('EditText') || className.contains('TextInputLayout')) {
      results.add(this);
    }
    
    for (final child in _children) {
      child._findInputRecursive(results);
    }
  }
  
  /// Find elements with text content
  List<UIElement> findElementsWithText() {
    final results = <UIElement>[];
    _findWithTextRecursive(results);
    return results;
  }
  
  void _findWithTextRecursive(List<UIElement> results) {
    if (text.isNotEmpty || contentDesc.isNotEmpty) {
      results.add(this);
    }
    
    for (final child in _children) {
      child._findWithTextRecursive(results);
    }
  }
  
  /// Get all descendants in a flat list
  List<UIElement> getAllDescendants() {
    final results = <UIElement>[];
    _getAllDescendantsRecursive(results);
    return results;
  }
  
  void _getAllDescendantsRecursive(List<UIElement> results) {
    for (final child in _children) {
      results.add(child);
      child._getAllDescendantsRecursive(results);
    }
  }
  
  /// Get path from root to this element
  List<UIElement> getPathFromRoot() {
    final path = <UIElement>[];
    UIElement? current = this;
    
    while (current != null) {
      path.insert(0, current);
      current = current._parent;
    }
    
    return path;
  }
  
  /// Check if this element is an ancestor of another element
  bool isAncestorOf(UIElement other) {
    UIElement? current = other._parent;
    while (current != null) {
      if (current == this) {
        return true;
      }
      current = current._parent;
    }
    return false;
  }
  
  /// Check if this element is a descendant of another element
  bool isDescendantOf(UIElement other) {
    return other.isAncestorOf(this);
  }
  
  /// Get display text for UI (prioritizes text over contentDesc)
  String get displayText {
    if (text.isNotEmpty) return text;
    if (contentDesc.isNotEmpty) return contentDesc;
    return className.split('.').last; // Return simple class name
  }
  
  /// Get bounds as a readable string
  String get boundsString {
    return '[${bounds.left.toInt()},${bounds.top.toInt()}][${bounds.right.toInt()},${bounds.bottom.toInt()}]';
  }
  
  /// Get center point of the element
  Offset get center => bounds.center;
  
  /// Get width of the element
  double get width => bounds.width;
  
  /// Get height of the element
  double get height => bounds.height;
  
  @override
  String toString() {
    return 'UIElement(id: $id, text: "$text", class: $className, bounds: $boundsString)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UIElement && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}