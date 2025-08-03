import 'package:flutter_test/flutter_test.dart';
import 'package:dump_ui_tools/models/ui_element.dart';
import 'package:dump_ui_tools/models/android_device.dart';
import 'package:dump_ui_tools/models/filter_criteria.dart';
import 'package:dump_ui_tools/services/xml_parser.dart';
import 'package:dump_ui_tools/services/file_manager.dart';
import 'package:dump_ui_tools/controllers/search_controller.dart';
import 'package:dump_ui_tools/controllers/filter_controller.dart';
import 'dart:io';
import 'dart:ui';

void main() {
  group('Comprehensive Integration Tests', () {
    late XMLParser xmlParser;
    late SearchController searchController;
    late FilterController filterController;
    late String testXmlContent;
    late File tempXmlFile;
    
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      
      xmlParser = XMLParser();
      searchController = SearchController();
      filterController = FilterController();
      
      // Create comprehensive test XML content
      testXmlContent = '''<?xml version='1.0' encoding='UTF-8' standalone='yes'?>
<hierarchy rotation="0">
  <node index="0" text="" resource-id="" class="android.widget.FrameLayout" package="com.example.app" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,0][1080,1920]">
    <node index="0" text="" resource-id="" class="android.widget.LinearLayout" package="com.example.app" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,0][1080,1920]">
      <node index="0" text="Login Screen" resource-id="com.example.app:id/title" class="android.widget.TextView" package="com.example.app" content-desc="Login screen title" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[100,200][980,300]"/>
      <node index="1" text="" resource-id="com.example.app:id/username_field" class="android.widget.EditText" package="com.example.app" content-desc="Username input field" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[100,350][980,450]"/>
      <node index="2" text="" resource-id="com.example.app:id/password_field" class="android.widget.EditText" package="com.example.app" content-desc="Password input field" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="true" selected="false" bounds="[100,500][980,600]"/>
      <node index="3" text="Login" resource-id="com.example.app:id/login_button" class="android.widget.Button" package="com.example.app" content-desc="Login button" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[100,650][980,750]"/>
      <node index="4" text="Forgot Password?" resource-id="com.example.app:id/forgot_link" class="android.widget.TextView" package="com.example.app" content-desc="Forgot password link" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[100,800][980,850]"/>
    </node>
  </node>
</hierarchy>''';
      
      // Create temporary XML file
      tempXmlFile = File('${Directory.systemTemp.path}/test_ui_dump.xml');
      await tempXmlFile.writeAsString(testXmlContent);
    });
    
    tearDownAll(() async {
      // Clean up temporary file
      if (await tempXmlFile.exists()) {
        await tempXmlFile.delete();
      }
    });
    
    test('Complete XML parsing and hierarchy building workflow', () async {
      // Test XML parsing
      final rootElement = await xmlParser.parseXMLFile(tempXmlFile.path);
      
      // Verify root element
      expect(rootElement, isNotNull);
      expect(rootElement.className, equals('android.widget.FrameLayout'));
      expect(rootElement.children.length, equals(1));
      
      // Verify hierarchy structure
      final linearLayout = rootElement.children.first;
      expect(linearLayout.className, equals('android.widget.LinearLayout'));
      expect(linearLayout.children.length, equals(5));
      
      // Verify specific elements
      final titleElement = linearLayout.children[0];
      expect(titleElement.text, equals('Login Screen'));
      expect(titleElement.resourceId, equals('com.example.app:id/title'));
      
      final usernameField = linearLayout.children[1];
      expect(usernameField.className, equals('android.widget.EditText'));
      expect(usernameField.clickable, isTrue);
      
      final loginButton = linearLayout.children[3];
      expect(loginButton.text, equals('Login'));
      expect(loginButton.clickable, isTrue);
      
      // Test hierarchy flattening
      final flatElements = xmlParser.flattenHierarchy(rootElement);
      expect(flatElements.length, equals(7)); // Root + LinearLayout + 5 children
      
      // Verify parent-child relationships
      expect(titleElement.parent, equals(linearLayout));
      expect(linearLayout.parent, equals(rootElement));
      expect(rootElement.parent, isNull);
    });
    
    test('Search functionality integration', () async {
      final rootElement = await xmlParser.parseXMLFile(tempXmlFile.path);
      final flatElements = xmlParser.flattenHierarchy(rootElement);
      
      // Initialize search controller with elements
      searchController.updateElements(flatElements);
      
      // Test text search
      searchController.search('Login');
      expect(searchController.hasResults, isTrue);
      expect(searchController.results.length, greaterThan(0));
      
      // Verify search results contain expected elements
      final loginResults = searchController.results
          .where((result) => result.element.text.contains('Login'))
          .toList();
      expect(loginResults.length, equals(2)); // "Login Screen" and "Login" button
      
      // Test resource ID search
      searchController.search('username_field');
      expect(searchController.hasResults, isTrue);
      final usernameResults = searchController.results
          .where((result) => result.element.resourceId.contains('username_field'))
          .toList();
      expect(usernameResults.length, equals(1));
      
      // Test content description search
      searchController.search('Password input');
      expect(searchController.hasResults, isTrue);
      
      // Test case-insensitive search
      searchController.search('login');
      expect(searchController.hasResults, isTrue);
      
      // Test empty search
      searchController.search('');
      expect(searchController.hasResults, isFalse);
      
      // Test no results
      searchController.search('NonExistentElement');
      expect(searchController.hasResults, isFalse);
    });
    
    test('Filter functionality integration', () async {
      final rootElement = await xmlParser.parseXMLFile(tempXmlFile.path);
      final flatElements = xmlParser.flattenHierarchy(rootElement);
      
      // Initialize filter controller with elements
      filterController.updateElements(flatElements);
      
      // Test initial state - all elements visible
      expect(filterController.filteredElements.length, equals(flatElements.length));
      
      // Test clickable filter
      filterController.toggleClickableFilter();
      expect(filterController.isFilterActive('clickable'), isTrue);
      final clickableElements = filterController.filteredElements
          .where((element) => element.clickable)
          .toList();
      expect(filterController.filteredElements.length, equals(clickableElements.length));
      expect(filterController.filteredElements.length, equals(4)); // username, password, login button, forgot link
      
      // Test input elements filter
      filterController.clearAllFilters();
      filterController.toggleInputFilter();
      expect(filterController.isFilterActive('input'), isTrue);
      final inputElements = filterController.filteredElements
          .where((element) => element.className.contains('EditText'))
          .toList();
      expect(filterController.filteredElements.length, equals(inputElements.length));
      expect(filterController.filteredElements.length, equals(2)); // username and password fields
      
      // Test elements with text filter
      filterController.clearAllFilters();
      filterController.toggleTextFilter();
      expect(filterController.isFilterActive('text'), isTrue);
      final textElements = filterController.filteredElements
          .where((element) => element.text.isNotEmpty)
          .toList();
      expect(filterController.filteredElements.length, equals(textElements.length));
      expect(filterController.filteredElements.length, equals(3)); // title, login button, forgot link
      
      // Test combined filters
      filterController.clearAllFilters();
      filterController.toggleClickableFilter();
      filterController.toggleTextFilter();
      final combinedElements = filterController.filteredElements
          .where((element) => element.clickable && element.text.isNotEmpty)
          .toList();
      expect(filterController.filteredElements.length, equals(combinedElements.length));
      expect(filterController.filteredElements.length, equals(2)); // login button and forgot link
      
      // Test search with filters
      filterController.clearAllFilters();
      filterController.toggleClickableFilter();
      filterController.setSearchText('Login');
      expect(filterController.filteredElements.length, equals(1)); // Only login button (clickable with "Login" text)
      
      // Test filter clearing
      filterController.clearAllFilters();
      expect(filterController.filteredElements.length, equals(flatElements.length));
      expect(filterController.isFilterActive('clickable'), isFalse);
      expect(filterController.isFilterActive('input'), isFalse);
      expect(filterController.isFilterActive('text'), isFalse);
    });
    
    test('Element property validation and bounds parsing', () async {
      final rootElement = await xmlParser.parseXMLFile(tempXmlFile.path);
      final flatElements = xmlParser.flattenHierarchy(rootElement);
      
      // Find specific elements for testing
      final titleElement = flatElements.firstWhere(
        (element) => element.resourceId == 'com.example.app:id/title'
      );
      final usernameField = flatElements.firstWhere(
        (element) => element.resourceId == 'com.example.app:id/username_field'
      );
      final loginButton = flatElements.firstWhere(
        (element) => element.resourceId == 'com.example.app:id/login_button'
      );
      
      // Test title element properties
      expect(titleElement.text, equals('Login Screen'));
      expect(titleElement.contentDesc, equals('Login screen title'));
      expect(titleElement.className, equals('android.widget.TextView'));
      expect(titleElement.clickable, isFalse);
      expect(titleElement.enabled, isTrue);
      expect(titleElement.bounds, equals(const Rect.fromLTWH(100, 200, 880, 100)));
      
      // Test username field properties
      expect(usernameField.text, isEmpty);
      expect(usernameField.contentDesc, equals('Username input field'));
      expect(usernameField.className, equals('android.widget.EditText'));
      expect(usernameField.clickable, isTrue);
      expect(usernameField.focusable, isTrue);
      expect(usernameField.bounds, equals(const Rect.fromLTWH(100, 350, 880, 100)));
      
      // Test login button properties
      expect(loginButton.text, equals('Login'));
      expect(loginButton.contentDesc, equals('Login button'));
      expect(loginButton.className, equals('android.widget.Button'));
      expect(loginButton.clickable, isTrue);
      expect(loginButton.enabled, isTrue);
      expect(loginButton.bounds, equals(const Rect.fromLTWH(100, 650, 880, 100)));
      
      // Test hierarchy relationships
      expect(titleElement.depth, equals(2));
      expect(usernameField.depth, equals(2));
      expect(loginButton.depth, equals(2));
      
      // Test parent relationships
      expect(titleElement.parent?.className, equals('android.widget.LinearLayout'));
      expect(usernameField.parent, equals(titleElement.parent));
      expect(loginButton.parent, equals(titleElement.parent));
    });
    
    test('XML formatting and syntax highlighting', () async {
      // Test XML formatting
      final formattedXml = xmlParser.formatXMLWithHighlight(testXmlContent);
      expect(formattedXml, isNotNull);
      expect(formattedXml.length, greaterThan(testXmlContent.length)); // Should include formatting
      
      // Test that original content is preserved
      expect(formattedXml, contains('Login Screen'));
      expect(formattedXml, contains('com.example.app:id/title'));
      expect(formattedXml, contains('android.widget.EditText'));
      expect(formattedXml, contains('bounds="[100,200][980,300]"'));
    });
    
    test('Error handling and edge cases', () async {
      // Test invalid XML file
      expect(
        () => xmlParser.parseXMLFile('/nonexistent/file.xml'),
        throwsA(isA<XMLParseException>()),
      );
      
      // Test malformed XML
      final malformedXml = '<?xml version="1.0"?><hierarchy><node><unclosed></hierarchy>';
      final malformedFile = File('${Directory.systemTemp.path}/malformed.xml');
      await malformedFile.writeAsString(malformedXml);
      
      expect(
        () => xmlParser.parseXMLFile(malformedFile.path),
        throwsA(isA<XMLParseException>()),
      );
      
      await malformedFile.delete();
      
      // Test empty search
      final rootElement = await xmlParser.parseXMLFile(tempXmlFile.path);
      final flatElements = xmlParser.flattenHierarchy(rootElement);
      searchController.updateElements(flatElements);
      
      searchController.search('');
      expect(searchController.hasResults, isFalse);
      expect(searchController.results, isEmpty);
      
      // Test filter with no matching elements
      filterController.updateElements(flatElements);
      filterController.setSearchText('NonExistentElement');
      expect(filterController.filteredElements, isEmpty);
    });
    
    test('Performance with large hierarchy', () async {
      // Create a larger XML structure for performance testing
      final largeXmlBuffer = StringBuffer();
      largeXmlBuffer.write('<?xml version="1.0" encoding="UTF-8"?><hierarchy rotation="0">');
      
      // Generate 100 nested elements
      for (int i = 0; i < 100; i++) {
        largeXmlBuffer.write('''
          <node index="$i" text="Element $i" resource-id="com.test:id/element_$i" 
                class="android.widget.TextView" package="com.test" 
                clickable="${i % 2 == 0}" enabled="true" 
                bounds="[${i * 10},${i * 10}][${i * 10 + 100},${i * 10 + 50}]">
        ''');
      }
      
      // Close all nodes
      for (int i = 0; i < 100; i++) {
        largeXmlBuffer.write('</node>');
      }
      largeXmlBuffer.write('</hierarchy>');
      
      final largeXmlFile = File('${Directory.systemTemp.path}/large_test.xml');
      await largeXmlFile.writeAsString(largeXmlBuffer.toString());
      
      // Test parsing performance
      final stopwatch = Stopwatch()..start();
      final largeRootElement = await xmlParser.parseXMLFile(largeXmlFile.path);
      stopwatch.stop();
      
      // Should parse within reasonable time (less than 1 second for 100 elements)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      
      // Test search performance
      final largeFlatElements = xmlParser.flattenHierarchy(largeRootElement);
      searchController.updateElements(largeFlatElements);
      
      stopwatch.reset();
      stopwatch.start();
      searchController.search('Element 5');
      stopwatch.stop();
      
      // Search should be fast (less than 100ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(searchController.hasResults, isTrue);
      
      // Test filter performance
      filterController.updateElements(largeFlatElements);
      
      stopwatch.reset();
      stopwatch.start();
      filterController.toggleClickableFilter();
      stopwatch.stop();
      
      // Filtering should be fast (less than 100ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(filterController.filteredElements.length, equals(50)); // Half should be clickable
      
      await largeXmlFile.delete();
    });
    
    test('Integration with real-world XML structure', () async {
      // Test with a more complex, realistic XML structure
      final complexXml = '''<?xml version='1.0' encoding='UTF-8' standalone='yes'?>
<hierarchy rotation="0">
  <node index="0" text="" resource-id="" class="android.widget.FrameLayout" package="com.android.systemui" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,0][1080,1920]">
    <node index="0" text="" resource-id="android:id/statusBarBackground" class="android.view.View" package="com.android.systemui" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,0][1080,72]"/>
    <node index="1" text="" resource-id="android:id/navigationBarBackground" class="android.view.View" package="com.android.systemui" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,1848][1080,1920]"/>
    <node index="2" text="" resource-id="android:id/content" class="android.widget.FrameLayout" package="com.example.myapp" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,72][1080,1848]">
      <node index="0" text="" resource-id="" class="android.widget.RelativeLayout" package="com.example.myapp" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,72][1080,1848]">
        <node index="0" text="" resource-id="com.example.myapp:id/toolbar" class="androidx.appcompat.widget.Toolbar" package="com.example.myapp" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,72][1080,216]">
          <node index="0" text="My App" resource-id="" class="android.widget.TextView" package="com.example.myapp" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[72,126][200,162]"/>
          <node index="1" text="" resource-id="" class="android.widget.ImageButton" package="com.example.myapp" content-desc="More options" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[936,72][1080,216]"/>
        </node>
        <node index="1" text="" resource-id="com.example.myapp:id/recycler_view" class="androidx.recyclerview.widget.RecyclerView" package="com.example.myapp" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="true" focused="false" scrollable="true" long-clickable="false" password="false" selected="false" bounds="[0,216][1080,1848]">
          <node index="0" text="" resource-id="" class="android.widget.LinearLayout" package="com.example.myapp" content-desc="" checkable="false" checked="false" clickable="true" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,216][1080,360]">
            <node index="0" text="Item 1" resource-id="com.example.myapp:id/item_title" class="android.widget.TextView" package="com.example.myapp" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[72,240][500,276]"/>
            <node index="1" text="Description for item 1" resource-id="com.example.myapp:id/item_description" class="android.widget.TextView" package="com.example.myapp" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[72,288][800,324]"/>
          </node>
        </node>
      </node>
    </node>
  </node>
</hierarchy>''';
      
      final complexXmlFile = File('${Directory.systemTemp.path}/complex_test.xml');
      await complexXmlFile.writeAsString(complexXml);
      
      // Parse complex structure
      final complexRoot = await xmlParser.parseXMLFile(complexXmlFile.path);
      final complexFlat = xmlParser.flattenHierarchy(complexRoot);
      
      // Verify structure parsing
      expect(complexFlat.length, equals(12)); // All nodes in the hierarchy
      
      // Test finding specific elements in complex structure
      searchController.updateElements(complexFlat);
      searchController.search('RecyclerView');
      expect(searchController.hasResults, isTrue);
      
      // Test filtering in complex structure
      filterController.updateElements(complexFlat);
      filterController.toggleClickableFilter();
      final clickableInComplex = filterController.filteredElements;
      expect(clickableInComplex.length, equals(2)); // ImageButton and LinearLayout item
      
      // Test resource ID search in complex structure
      searchController.search('item_title');
      expect(searchController.hasResults, isTrue);
      final titleResults = searchController.results
          .where((result) => result.element.resourceId.contains('item_title'))
          .toList();
      expect(titleResults.length, equals(1));
      
      await complexXmlFile.delete();
    });
  });
}