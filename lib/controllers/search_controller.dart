import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/ui_element.dart';

/// Search result item with highlighting information
class SearchResult {
  final UIElement element;
  final List<SearchMatch> matches;
  final double relevanceScore;
  
  const SearchResult({
    required this.element,
    required this.matches,
    required this.relevanceScore,
  });
}

/// Represents a search match within an element
class SearchMatch {
  final String field; // 'text', 'contentDesc', 'resourceId', 'className'
  final String matchedText;
  final int startIndex;
  final int endIndex;
  
  const SearchMatch({
    required this.field,
    required this.matchedText,
    required this.startIndex,
    required this.endIndex,
  });
}

/// Search options for customizing search behavior
class SearchOptions {
  final bool caseSensitive;
  final bool exactMatch;
  final bool searchInText;
  final bool searchInContentDesc;
  final bool searchInResourceId;
  final bool searchInClassName;
  final bool highlightMatches;
  final int maxResults;
  
  const SearchOptions({
    this.caseSensitive = false,
    this.exactMatch = false,
    this.searchInText = true,
    this.searchInContentDesc = true,
    this.searchInResourceId = true,
    this.searchInClassName = false,
    this.highlightMatches = true,
    this.maxResults = 1000,
  });
  
  static const SearchOptions defaultOptions = SearchOptions();
}

/// Controller for handling search functionality with real-time search and result filtering
class SearchController extends ChangeNotifier {
  // Private fields
  String _query = '';
  List<SearchResult> _results = [];
  List<UIElement> _expandedPaths = [];
  bool _isSearching = false;
  SearchOptions _options = SearchOptions.defaultOptions;
  Timer? _debounceTimer;
  
  // Search statistics
  int _totalMatches = 0;
  Duration _lastSearchDuration = Duration.zero;
  
  // Performance optimization fields
  static const int _maxCachedSearches = 50;
  final Map<String, List<SearchResult>> _searchCache = {};
  final List<String> _cacheKeys = [];
  
  // Index for faster searching
  Map<String, List<UIElement>>? _textIndex;
  Map<String, List<UIElement>>? _resourceIdIndex;
  Map<String, List<UIElement>>? _classNameIndex;
  
  // Getters
  String get query => _query;
  List<SearchResult> get results => List.unmodifiable(_results);
  List<UIElement> get expandedPaths => List.unmodifiable(_expandedPaths);
  bool get isSearching => _isSearching;
  bool get hasResults => _results.isNotEmpty;
  bool get hasQuery => _query.isNotEmpty;
  SearchOptions get options => _options;
  int get totalMatches => _totalMatches;
  Duration get lastSearchDuration => _lastSearchDuration;
  
  /// Set search options
  void setOptions(SearchOptions newOptions) {
    if (_options != newOptions) {
      _options = newOptions;
      
      // Re-run search if there's an active query
      if (_query.isNotEmpty) {
        _performSearch(_query);
      }
      
      notifyListeners();
    }
  }
  
  /// Update search query with debouncing
  void updateQuery(String newQuery) {
    if (_query == newQuery) return;
    
    _query = newQuery;
    
    // Cancel previous debounce timer
    _debounceTimer?.cancel();
    
    if (newQuery.isEmpty) {
      _clearResults();
      notifyListeners();
      return;
    }
    
    // Set up debounce timer for real-time search
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(newQuery);
    });
    
    notifyListeners();
  }
  
  /// Perform immediate search without debouncing
  void searchImmediately(String query) {
    _debounceTimer?.cancel();
    _query = query;
    
    if (query.isEmpty) {
      _clearResults();
    } else {
      _performSearch(query);
    }
    
    notifyListeners();
  }
  
  /// Search in a list of UI elements with caching and indexing
  Future<List<SearchResult>> searchInElements(List<UIElement> elements, String query) async {
    if (query.isEmpty || elements.isEmpty) {
      return [];
    }
    
    // Check cache first
    final cacheKey = _getCacheKey(query, _options);
    if (_searchCache.containsKey(cacheKey)) {
      _results = _searchCache[cacheKey]!;
      _expandedPaths = getElementsToExpand(_results);
      return _results;
    }
    
    final stopwatch = Stopwatch()..start();
    _isSearching = true;
    notifyListeners();
    
    try {
      // Build index if not exists or elements changed
      _buildSearchIndex(elements);
      
      final results = await _performOptimizedSearch(elements, query);
      
      stopwatch.stop();
      _lastSearchDuration = stopwatch.elapsed;
      
      // Cache the results
      _cacheSearchResults(cacheKey, results);
      
      return results;
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }
  
  /// Clear search results and query
  void clear() {
    _debounceTimer?.cancel();
    _query = '';
    _clearResults();
    notifyListeners();
  }
  
  /// Clear only results, keep query
  void clearResults() {
    _clearResults();
    notifyListeners();
  }
  
  /// Get elements that should be expanded to show search results
  List<UIElement> getElementsToExpand(List<SearchResult> searchResults) {
    final elementsToExpand = <UIElement>{};
    
    for (final result in searchResults) {
      final path = result.element.getPathFromRoot();
      // Add all ancestors except the element itself
      for (int i = 0; i < path.length - 1; i++) {
        elementsToExpand.add(path[i]);
      }
    }
    
    return elementsToExpand.toList();
  }
  
  /// Check if an element should be highlighted
  bool shouldHighlightElement(UIElement element) {
    return _results.any((result) => result.element == element);
  }
  
  /// Get search matches for a specific element
  List<SearchMatch> getMatchesForElement(UIElement element) {
    final result = _results.cast<SearchResult?>().firstWhere(
      (result) => result?.element == element,
      orElse: () => null,
    );
    
    return result?.matches ?? [];
  }
  
  /// Get highlighted text for an element field
  String getHighlightedText(UIElement element, String field) {
    final matches = getMatchesForElement(element);
    final fieldMatches = matches.where((match) => match.field == field).toList();
    
    if (fieldMatches.isEmpty) {
      return _getFieldValue(element, field);
    }
    
    // For now, return the original text
    // In a real implementation, you might want to return HTML or styled text
    return _getFieldValue(element, field);
  }
  
  /// Get search statistics
  Map<String, dynamic> getSearchStatistics() {
    return {
      'query': _query,
      'totalResults': _results.length,
      'totalMatches': _totalMatches,
      'searchDuration': _lastSearchDuration.inMilliseconds,
      'isSearching': _isSearching,
      'hasResults': hasResults,
    };
  }
  
  /// Private method to perform the actual search
  void _performSearch(String query) async {
    // This method would typically receive elements from the state manager
    // For now, we'll just update the internal state
    _isSearching = true;
    notifyListeners();
    
    // Simulate async search
    await Future.delayed(const Duration(milliseconds: 50));
    
    _isSearching = false;
    notifyListeners();
  }
  
  /// Private method to search in elements
  Future<List<SearchResult>> _performSearchInElements(List<UIElement> elements, String query) async {
    final results = <SearchResult>[];
    final processedQuery = _options.caseSensitive ? query : query.toLowerCase();
    
    for (final element in elements) {
      final matches = <SearchMatch>[];
      double relevanceScore = 0.0;
      
      // Search in text field
      if (_options.searchInText && element.text.isNotEmpty) {
        final textMatches = _findMatches(element.text, processedQuery, 'text');
        matches.addAll(textMatches);
        relevanceScore += textMatches.length * 2.0; // Text matches have higher weight
      }
      
      // Search in content description
      if (_options.searchInContentDesc && element.contentDesc.isNotEmpty) {
        final contentMatches = _findMatches(element.contentDesc, processedQuery, 'contentDesc');
        matches.addAll(contentMatches);
        relevanceScore += contentMatches.length * 1.5;
      }
      
      // Search in resource ID
      if (_options.searchInResourceId && element.resourceId.isNotEmpty) {
        final resourceMatches = _findMatches(element.resourceId, processedQuery, 'resourceId');
        matches.addAll(resourceMatches);
        relevanceScore += resourceMatches.length * 1.0;
      }
      
      // Search in class name
      if (_options.searchInClassName && element.className.isNotEmpty) {
        final classMatches = _findMatches(element.className, processedQuery, 'className');
        matches.addAll(classMatches);
        relevanceScore += classMatches.length * 0.5;
      }
      
      // If we found matches, add to results
      if (matches.isNotEmpty) {
        results.add(SearchResult(
          element: element,
          matches: matches,
          relevanceScore: relevanceScore,
        ));
      }
      
      // Limit results if specified
      if (results.length >= _options.maxResults) {
        break;
      }
    }
    
    // Sort by relevance score (highest first)
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    
    _results = results;
    _totalMatches = results.fold(0, (sum, result) => sum + result.matches.length);
    
    // Calculate elements to expand
    _expandedPaths = getElementsToExpand(results);
    
    return results;
  }
  
  /// Find matches in a text field
  List<SearchMatch> _findMatches(String text, String query, String field) {
    final matches = <SearchMatch>[];
    final searchText = _options.caseSensitive ? text : text.toLowerCase();
    
    if (_options.exactMatch) {
      if (searchText == query) {
        matches.add(SearchMatch(
          field: field,
          matchedText: text,
          startIndex: 0,
          endIndex: text.length,
        ));
      }
    } else {
      int startIndex = 0;
      while (true) {
        final index = searchText.indexOf(query, startIndex);
        if (index == -1) break;
        
        matches.add(SearchMatch(
          field: field,
          matchedText: text.substring(index, index + query.length),
          startIndex: index,
          endIndex: index + query.length,
        ));
        
        startIndex = index + 1;
      }
    }
    
    return matches;
  }
  
  /// Get field value from element
  String _getFieldValue(UIElement element, String field) {
    switch (field) {
      case 'text':
        return element.text;
      case 'contentDesc':
        return element.contentDesc;
      case 'resourceId':
        return element.resourceId;
      case 'className':
        return element.className;
      default:
        return '';
    }
  }
  
  /// Clear internal results
  void _clearResults() {
    _results.clear();
    _expandedPaths.clear();
    _totalMatches = 0;
    _lastSearchDuration = Duration.zero;
  }
  
  /// Build search index for faster lookups
  void _buildSearchIndex(List<UIElement> elements) {
    if (_textIndex != null) return; // Already built
    
    _textIndex = {};
    _resourceIdIndex = {};
    _classNameIndex = {};
    
    for (final element in elements) {
      // Index by text words
      if (element.text.isNotEmpty) {
        final words = element.text.toLowerCase().split(RegExp(r'\s+'));
        for (final word in words) {
          if (word.isNotEmpty) {
            _textIndex![word] = (_textIndex![word] ?? [])..add(element);
          }
        }
      }
      
      // Index by resource ID
      if (element.resourceId.isNotEmpty) {
        final resourceId = element.resourceId.toLowerCase();
        _resourceIdIndex![resourceId] = (_resourceIdIndex![resourceId] ?? [])..add(element);
      }
      
      // Index by class name
      if (element.className.isNotEmpty) {
        final className = element.className.toLowerCase();
        _classNameIndex![className] = (_classNameIndex![className] ?? [])..add(element);
      }
    }
  }
  
  /// Clear search index to force rebuild
  void clearSearchIndex() {
    _textIndex = null;
    _resourceIdIndex = null;
    _classNameIndex = null;
  }
  
  /// Perform optimized search using indexes
  Future<List<SearchResult>> _performOptimizedSearch(List<UIElement> elements, String query) async {
    final results = <SearchResult>[];
    final processedQuery = _options.caseSensitive ? query : query.toLowerCase();
    final candidateElements = <UIElement>{};
    
    // Use indexes to find candidate elements
    if (_options.searchInText && _textIndex != null) {
      final words = processedQuery.split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.isNotEmpty) {
          final matches = _textIndex!.entries
              .where((entry) => entry.key.contains(word))
              .expand((entry) => entry.value);
          candidateElements.addAll(matches);
        }
      }
    }
    
    if (_options.searchInResourceId && _resourceIdIndex != null) {
      final matches = _resourceIdIndex!.entries
          .where((entry) => entry.key.contains(processedQuery))
          .expand((entry) => entry.value);
      candidateElements.addAll(matches);
    }
    
    if (_options.searchInClassName && _classNameIndex != null) {
      final matches = _classNameIndex!.entries
          .where((entry) => entry.key.contains(processedQuery))
          .expand((entry) => entry.value);
      candidateElements.addAll(matches);
    }
    
    // If no indexes are used, fall back to full search
    if (candidateElements.isEmpty) {
      candidateElements.addAll(elements);
    }
    
    // Process candidate elements
    for (final element in candidateElements) {
      final matches = <SearchMatch>[];
      double relevanceScore = 0.0;
      
      // Search in text field
      if (_options.searchInText && element.text.isNotEmpty) {
        final textMatches = _findMatches(element.text, processedQuery, 'text');
        matches.addAll(textMatches);
        relevanceScore += textMatches.length * 2.0;
      }
      
      // Search in content description
      if (_options.searchInContentDesc && element.contentDesc.isNotEmpty) {
        final contentMatches = _findMatches(element.contentDesc, processedQuery, 'contentDesc');
        matches.addAll(contentMatches);
        relevanceScore += contentMatches.length * 1.5;
      }
      
      // Search in resource ID
      if (_options.searchInResourceId && element.resourceId.isNotEmpty) {
        final resourceMatches = _findMatches(element.resourceId, processedQuery, 'resourceId');
        matches.addAll(resourceMatches);
        relevanceScore += resourceMatches.length * 1.0;
      }
      
      // Search in class name
      if (_options.searchInClassName && element.className.isNotEmpty) {
        final classMatches = _findMatches(element.className, processedQuery, 'className');
        matches.addAll(classMatches);
        relevanceScore += classMatches.length * 0.5;
      }
      
      // If we found matches, add to results
      if (matches.isNotEmpty) {
        results.add(SearchResult(
          element: element,
          matches: matches,
          relevanceScore: relevanceScore,
        ));
      }
      
      // Limit results if specified
      if (results.length >= _options.maxResults) {
        break;
      }
    }
    
    // Sort by relevance score (highest first)
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    
    _results = results;
    _totalMatches = results.fold(0, (sum, result) => sum + result.matches.length);
    _expandedPaths = getElementsToExpand(results);
    
    return results;
  }
  
  /// Generate cache key for search
  String _getCacheKey(String query, SearchOptions options) {
    return '${query}_${options.caseSensitive}_${options.exactMatch}_${options.searchInText}_${options.searchInContentDesc}_${options.searchInResourceId}_${options.searchInClassName}';
  }
  
  /// Cache search results with LRU eviction
  void _cacheSearchResults(String key, List<SearchResult> results) {
    // Remove oldest entries if cache is full
    while (_cacheKeys.length >= _maxCachedSearches) {
      final oldestKey = _cacheKeys.removeAt(0);
      _searchCache.remove(oldestKey);
    }
    
    // Add new results
    _searchCache[key] = List.from(results);
    _cacheKeys.add(key);
  }
  
  /// Clear search cache
  void clearSearchCache() {
    _searchCache.clear();
    _cacheKeys.clear();
  }
  
  /// Get search performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'cacheSize': _searchCache.length,
      'maxCacheSize': _maxCachedSearches,
      'cacheHitRate': _cacheKeys.isNotEmpty ? _searchCache.length / _cacheKeys.length : 0.0,
      'indexSize': {
        'text': _textIndex?.length ?? 0,
        'resourceId': _resourceIdIndex?.length ?? 0,
        'className': _classNameIndex?.length ?? 0,
      },
      'lastSearchDuration': _lastSearchDuration.inMilliseconds,
    };
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _results.clear();
    _expandedPaths.clear();
    _searchCache.clear();
    _cacheKeys.clear();
    clearSearchIndex();
    super.dispose();
  }
}

/// Extension methods for search functionality
extension SearchableUIElement on UIElement {
  /// Check if this element matches a search query
  bool matchesQuery(String query, {SearchOptions? options}) {
    final searchOptions = options ?? SearchOptions.defaultOptions;
    final processedQuery = searchOptions.caseSensitive ? query : query.toLowerCase();
    
    if (searchOptions.exactMatch) {
      return _exactMatch(processedQuery, searchOptions);
    } else {
      return _containsMatch(processedQuery, searchOptions);
    }
  }
  
  bool _exactMatch(String query, SearchOptions options) {
    if (options.searchInText) {
      final text = options.caseSensitive ? this.text : this.text.toLowerCase();
      if (text == query) return true;
    }
    
    if (options.searchInContentDesc) {
      final contentDesc = options.caseSensitive ? this.contentDesc : this.contentDesc.toLowerCase();
      if (contentDesc == query) return true;
    }
    
    if (options.searchInResourceId) {
      final resourceId = options.caseSensitive ? this.resourceId : this.resourceId.toLowerCase();
      if (resourceId == query) return true;
    }
    
    if (options.searchInClassName) {
      final className = options.caseSensitive ? this.className : this.className.toLowerCase();
      if (className == query) return true;
    }
    
    return false;
  }
  
  bool _containsMatch(String query, SearchOptions options) {
    if (options.searchInText) {
      final text = options.caseSensitive ? this.text : this.text.toLowerCase();
      if (text.contains(query)) return true;
    }
    
    if (options.searchInContentDesc) {
      final contentDesc = options.caseSensitive ? this.contentDesc : this.contentDesc.toLowerCase();
      if (contentDesc.contains(query)) return true;
    }
    
    if (options.searchInResourceId) {
      final resourceId = options.caseSensitive ? this.resourceId : this.resourceId.toLowerCase();
      if (resourceId.contains(query)) return true;
    }
    
    if (options.searchInClassName) {
      final className = options.caseSensitive ? this.className : this.className.toLowerCase();
      if (className.contains(query)) return true;
    }
    
    return false;
  }
}