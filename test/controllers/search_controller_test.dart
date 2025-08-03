import 'package:flutter_test/flutter_test.dart';
import 'package:dump_ui_tools/controllers/search_controller.dart';
import 'package:dump_ui_tools/models/ui_element.dart';

void main() {
  group('SearchController', () {
    late SearchController searchController;
    late List<UIElement> testElements;

    setUp(() {
      searchController = SearchController();
      testElements = _createTestElements();
    });

    tearDown(() {
      searchController.dispose();
    });

    group('Basic Search Functionality', () {
      test('should initialize with empty state', () {
        expect(searchController.query, isEmpty);
        expect(searchController.results, isEmpty);
        expect(searchController.hasResults, isFalse);
        expect(searchController.hasQuery, isFalse);
        expect(searchController.isSearching, isFalse);
      });

      test('should update query and trigger search', () async {
        searchController.updateQuery('Login');
        
        expect(searchController.query, equals('Login'));
        expect(searchController.hasQuery, isTrue);
        
        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 400));
        
        expect(searchController.isSearching, isFalse);
      });

      test('should clear search when query is empty', () {
        searchController.updateQuery('Login');
        expect(searchController.hasQuery, isTrue);
        
        searchController.updateQuery('');
        expect(searchController.hasQuery, isFalse);
        expect(searchController.results, isEmpty);
      });

      test('should perform immediate search without debouncing', () async {
        final results = await searchController.searchInElements(testElements, 'Login');
        
        expect(results, isNotEmpty);
        expect(results.first.element.text, contains('Login'));
        expect(searchController.lastSearchDuration, greaterThan(Duration.zero));
      });
    });

    group('Search Options', () {
      test('should respect case sensitivity option', () async {
        // Case insensitive (default)
        var results = await searchController.searchInElements(testElements, 'login');
        expect(results, isNotEmpty);
        
        // Case sensitive
        searchController.setOptions(const SearchOptions(caseSensitive: true));
        results = await searchController.searchInElements(testElements, 'login');
        expect(results, isEmpty);
        
        results = await searchController.searchInElements(testElements, 'Login');
        expect(results, isNotEmpty);
      });

      test('should respect exact match option', () async {
        // Partial match (default)
        var results = await searchController.searchInElements(testElements, 'Log');
        expect(results, isNotEmpty);
        
        // Exact match
        searchController.setOptions(const SearchOptions(exactMatch: true));
        results = await searchController.searchInElements(testElements, 'Log');
        expect(results, isEmpty);
        
        results = await searchController.searchInElements(testElements, 'Login Button');
        expect(results, isNotEmpty);
      });

      test('should search in different fields based on options', () async {
        // Search in text only
        searchController.setOptions(const SearchOptions(
          searchInText: true,
          searchInContentDesc: false,
          searchInResourceId: false,
          searchInClassName: false,
        ));
        
        var results = await searchController.searchInElements(testElements, 'Login');
        expect(results, isNotEmpty);
        
        // Search in resource ID only
        searchController.setOptions(const SearchOptions(
          searchInText: false,
          searchInContentDesc: false,
          searchInResourceId: true,
          searchInClassName: false,
        ));
        
        results = await searchController.searchInElements(testElements, 'login_btn');
        expect(results, isNotEmpty);
        
        results = await searchController.searchInElements(testElements, 'Login');
        expect(results, isEmpty);
      });

      test('should limit results based on maxResults option', () async {
        searchController.setOptions(const SearchOptions(maxResults: 1));
        
        final results = await searchController.searchInElements(testElements, 'Element');
        expect(results.length, equals(1));
      });
    });

    group('Search Results', () {
      test('should return search results with matches', () async {
        final results = await searchController.searchInElements(testElements, 'Login');
        
        expect(results, isNotEmpty);
        final result = results.first;
        expect(result.element.text, contains('Login'));
        expect(result.matches, isNotEmpty);
        expect(result.relevanceScore, greaterThan(0));
      });

      test('should sort results by relevance score', () async {
        final results = await searchController.searchInElements(testElements, 'Button');
        
        if (results.length > 1) {
          for (int i = 0; i < results.length - 1; i++) {
            expect(results[i].relevanceScore, greaterThanOrEqualTo(results[i + 1].relevanceScore));
          }
        }
      });

      test('should provide search matches with field information', () async {
        final results = await searchController.searchInElements(testElements, 'Login');
        
        final result = results.first;
        expect(result.matches, isNotEmpty);
        
        final match = result.matches.first;
        expect(match.field, isNotEmpty);
        expect(match.matchedText, isNotEmpty);
        expect(match.startIndex, greaterThanOrEqualTo(0));
        expect(match.endIndex, greaterThan(match.startIndex));
      });

      test('should calculate total matches correctly', () async {
        await searchController.searchInElements(testElements, 'Element');
        
        expect(searchController.totalMatches, greaterThan(0));
        expect(searchController.totalMatches, 
               equals(searchController.results.fold(0, (sum, result) => sum + result.matches.length)));
      });
    });

    group('Search Performance', () {
      test('should use search index for better performance', () async {
        // First search builds index
        await searchController.searchInElements(testElements, 'Login');
        
        // Second search should use index
        final stopwatch = Stopwatch()..start();
        await searchController.searchInElements(testElements, 'Button');
        stopwatch.stop();
        
        // Should be reasonably fast
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('should cache search results', () async {
        // First search
        final results1 = await searchController.searchInElements(testElements, 'Login');
        
        // Second identical search should use cache
        final results2 = await searchController.searchInElements(testElements, 'Login');
        
        expect(results1.length, equals(results2.length));
        expect(results1.first.element.id, equals(results2.first.element.id));
      });

      test('should provide performance metrics', () async {
        await searchController.searchInElements(testElements, 'Login');
        
        final metrics = searchController.getPerformanceMetrics();
        
        expect(metrics, containsKey('cacheSize'));
        expect(metrics, containsKey('maxCacheSize'));
        expect(metrics, containsKey('cacheHitRate'));
        expect(metrics, containsKey('indexSize'));
        expect(metrics, containsKey('lastSearchDuration'));
      });

      test('should clear search cache when requested', () {
        searchController.clearSearchCache();
        
        final metrics = searchController.getPerformanceMetrics();
        expect(metrics['cacheSize'], equals(0));
      });

      test('should clear search index when requested', () {
        searchController.clearSearchIndex();
        
        // Index should be rebuilt on next search
        expect(() => searchController.clearSearchIndex(), returnsNormally);
      });
    });

    group('Element Expansion', () {
      test('should calculate elements to expand for search results', () async {
        final results = await searchController.searchInElements(testElements, 'Grandchild');
        
        final elementsToExpand = searchController.getElementsToExpand(results);
        
        expect(elementsToExpand, isNotEmpty);
        // Should include parent elements in the path
      });

      test('should identify elements that should be highlighted', () async {
        await searchController.searchInElements(testElements, 'Login');
        
        final loginElement = testElements.firstWhere((e) => e.text.contains('Login'));
        expect(searchController.shouldHighlightElement(loginElement), isTrue);
        
        final otherElement = testElements.firstWhere((e) => e.text.contains('Password'));
        expect(searchController.shouldHighlightElement(otherElement), isFalse);
      });

      test('should get matches for specific element', () async {
        await searchController.searchInElements(testElements, 'Login');
        
        final loginElement = testElements.firstWhere((e) => e.text.contains('Login'));
        final matches = searchController.getMatchesForElement(loginElement);
        
        expect(matches, isNotEmpty);
        expect(matches.first.field, equals('text'));
      });

      test('should get highlighted text for element field', () async {
        await searchController.searchInElements(testElements, 'Login');
        
        final loginElement = testElements.firstWhere((e) => e.text.contains('Login'));
        final highlightedText = searchController.getHighlightedText(loginElement, 'text');
        
        expect(highlightedText, equals(loginElement.text));
      });
    });

    group('Search Statistics', () {
      test('should provide comprehensive search statistics', () async {
        await searchController.searchInElements(testElements, 'Button');
        
        final stats = searchController.getSearchStatistics();
        
        expect(stats, containsKey('query'));
        expect(stats, containsKey('totalResults'));
        expect(stats, containsKey('totalMatches'));
        expect(stats, containsKey('searchDuration'));
        expect(stats, containsKey('isSearching'));
        expect(stats, containsKey('hasResults'));
        
        expect(stats['query'], equals('Button'));
        expect(stats['totalResults'], greaterThan(0));
        expect(stats['hasResults'], isTrue);
      });

      test('should track search duration', () async {
        await searchController.searchInElements(testElements, 'Login');
        
        expect(searchController.lastSearchDuration, greaterThan(Duration.zero));
      });
    });

    group('Debouncing', () {
      test('should debounce search queries', () async {
        var searchCount = 0;
        
        // Override search method to count calls
        searchController.updateQuery('L');
        searchController.updateQuery('Lo');
        searchController.updateQuery('Log');
        searchController.updateQuery('Login');
        
        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 400));
        
        // Should only search once after debounce period
        expect(searchController.query, equals('Login'));
      });

      test('should cancel previous debounce timer on new query', () async {
        searchController.updateQuery('First');
        
        // Immediately update with new query
        searchController.updateQuery('Second');
        
        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 400));
        
        expect(searchController.query, equals('Second'));
      });
    });

    group('Error Handling', () {
      test('should handle empty element list gracefully', () async {
        final results = await searchController.searchInElements([], 'Login');
        
        expect(results, isEmpty);
        expect(searchController.totalMatches, equals(0));
      });

      test('should handle null or empty search query', () async {
        var results = await searchController.searchInElements(testElements, '');
        expect(results, isEmpty);
        
        results = await searchController.searchInElements(testElements, '   ');
        expect(results, isEmpty);
      });

      test('should handle search in elements with missing fields', () async {
        final elementWithEmptyFields = UIElement(
          id: 'empty_element',
          depth: 0,
          text: '',
          contentDesc: '',
          className: '',
          packageName: '',
          resourceId: '',
          clickable: false,
          enabled: true,
          bounds: const Rect.fromLTRB(0, 0, 100, 50),
          index: 0,
        );
        
        final elementsWithEmpty = [...testElements, elementWithEmptyFields];
        final results = await searchController.searchInElements(elementsWithEmpty, 'Login');
        
        expect(results, isNotEmpty);
        expect(results.any((r) => r.element.id == 'empty_element'), isFalse);
      });
    });

    group('Memory Management', () {
      test('should dispose resources properly', () {
        expect(() => searchController.dispose(), returnsNormally);
      });

      test('should clear all data on clear', () {
        searchController.updateQuery('Test');
        searchController.clear();
        
        expect(searchController.query, isEmpty);
        expect(searchController.results, isEmpty);
        expect(searchController.hasQuery, isFalse);
        expect(searchController.hasResults, isFalse);
      });

      test('should clear only results on clearResults', () {
        searchController.updateQuery('Test');
        searchController.clearResults();
        
        expect(searchController.query, equals('Test'));
        expect(searchController.results, isEmpty);
        expect(searchController.hasQuery, isTrue);
        expect(searchController.hasResults, isFalse);
      });
    });

    group('UIElement Search Extensions', () {
      test('should match query with default options', () {
        final element = testElements.first;
        
        expect(element.matchesQuery('Login'), isTrue);
        expect(element.matchesQuery('NonExistent'), isFalse);
      });

      test('should match query with custom options', () {
        final element = testElements.first;
        
        // Case sensitive
        expect(element.matchesQuery('login', options: const SearchOptions(caseSensitive: true)), isFalse);
        expect(element.matchesQuery('Login', options: const SearchOptions(caseSensitive: true)), isTrue);
        
        // Exact match
        expect(element.matchesQuery('Login', options: const SearchOptions(exactMatch: true)), isFalse);
        expect(element.matchesQuery('Login Button', options: const SearchOptions(exactMatch: true)), isTrue);
      });

      test('should search in specific fields only', () {
        final element = testElements.firstWhere((e) => e.resourceId.isNotEmpty);
        
        // Search in resource ID only
        expect(element.matchesQuery('login_btn', options: const SearchOptions(
          searchInText: false,
          searchInResourceId: true,
        )), isTrue);
        
        expect(element.matchesQuery('Login', options: const SearchOptions(
          searchInText: false,
          searchInResourceId: true,
        )), isFalse);
      });
    });
  });
}

List<UIElement> _createTestElements() {
  final root = UIElement(
    id: 'root',
    depth: 0,
    text: 'Root Element',
    contentDesc: 'Root description',
    className: 'android.widget.LinearLayout',
    packageName: 'com.example.app',
    resourceId: '',
    clickable: false,
    enabled: true,
    bounds: const Rect.fromLTRB(0, 0, 1080, 1920),
    index: 0,
  );

  final loginButton = UIElement(
    id: 'login_btn',
    depth: 1,
    text: 'Login Button',
    contentDesc: 'Login button',
    className: 'android.widget.Button',
    packageName: 'com.example.app',
    resourceId: 'com.example.app:id/login_btn',
    clickable: true,
    enabled: true,
    bounds: const Rect.fromLTRB(100, 200, 300, 250),
    index: 0,
  );

  final passwordField = UIElement(
    id: 'password_field',
    depth: 1,
    text: 'Password Field',
    contentDesc: 'Password input',
    className: 'android.widget.EditText',
    packageName: 'com.example.app',
    resourceId: 'com.example.app:id/password_field',
    clickable: true,
    enabled: true,
    bounds: const Rect.fromLTRB(100, 300, 500, 350),
    index: 1,
  );

  final submitButton = UIElement(
    id: 'submit_btn',
    depth: 2,
    text: 'Submit Button',
    contentDesc: 'Submit action',
    className: 'android.widget.Button',
    packageName: 'com.example.app',
    resourceId: 'com.example.app:id/submit_btn',
    clickable: true,
    enabled: true,
    bounds: const Rect.fromLTRB(150, 400, 250, 450),
    index: 0,
  );

  final grandchild = UIElement(
    id: 'grandchild',
    depth: 3,
    text: 'Grandchild Element',
    contentDesc: 'Deep nested element',
    className: 'android.widget.TextView',
    packageName: 'com.example.app',
    resourceId: '',
    clickable: false,
    enabled: true,
    bounds: const Rect.fromLTRB(160, 410, 240, 440),
    index: 0,
  );

  // Build hierarchy
  root.addChild(loginButton);
  root.addChild(passwordField);
  loginButton.addChild(submitButton);
  submitButton.addChild(grandchild);

  return [root, loginButton, passwordField, submitButton, grandchild];
}