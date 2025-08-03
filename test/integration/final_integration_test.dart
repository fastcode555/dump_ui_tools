import 'package:flutter_test/flutter_test.dart';
import 'package:dump_ui_tools/models/ui_element.dart';
import 'package:dump_ui_tools/services/xml_parser.dart';
import 'dart:io';
import 'dart:ui';

void main() {
  group('Final Integration Tests', () {
    late XMLParser xmlParser;
    late String testXmlContent;
    late File tempXmlFile;
    
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      
      xmlParser = XMLParser();
      
      // Create test XML content
      testXmlContent = '''<?xml version='1.0' encoding='UTF-8' standalone='yes'?>
<hierarchy rotation="0">
  <node index="0" text="" resource-id="" class="android.widget.FrameLayout" package="com.example.app" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,0][1080,1920]">
    <node index="0" text="" resource-id="" class="android.widget.LinearLayout" package="com.example.app" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,0][1080,1920]">
      <node index="0" text="Login Screen" resource-id="com.example.app:id/title" class="android.widget.TextView" package="com.example.app" content-desc="Login screen title" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[100,200][980,300]"/>
      <node index="1" text="" resource-id="com.example.app:id/username_field" class="android.widget.EditText" package="com.example.app" content-desc="Username input field" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[100,350][980,450]"/>
      <node index="2" text="" resource-id="com.example.app:id/password_field" class="android.widget.EditText" package="com.example.app" content-desc="Password input field" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="true" selected="false" bounds="[100,500][980,600]"/>
      <node index="3" text="Login" resource-id="com.example.app:id/login_button" class="android.widget.Button" package="com.example.app" content-desc="Login button" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[100,650][980,750]"/>
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
    
    test('XML parsing and hierarchy building', () async {
      // Test XML parsing
      final rootElement = await xmlParser.parseXMLFile(tempXmlFile.path);
      
      // Verify root element (hierarchy wrapper)
      expect(rootElement, isNotNull);
      expect(rootElement.className, equals('hierarchy'));
      expect(rootElement.children.length, equals(1));
      
      // Verify actual UI root (FrameLayout)
      final frameLayout = rootElement.children.first;
      expect(frameLayout.className, equals('android.widget.FrameLayout'));
      expect(frameLayout.children.length, equals(1));
      
      // Verify hierarchy structure
      final linearLayout = frameLayout.children.first;
      expect(linearLayout.className, equals('android.widget.LinearLayout'));
      expect(linearLayout.children.length, equals(4));
      
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
      
      // Verify parent-child relationships
      expect(titleElement.parent, equals(linearLayout));
      expect(linearLayout.parent, equals(frameLayout));
      expect(frameLayout.parent, equals(rootElement));
      expect(rootElement.parent, isNull);
    });
    
    test('Element property validation and bounds parsing', () async {
      final rootElement = await xmlParser.parseXMLFile(tempXmlFile.path);
      final frameLayout = rootElement.children.first;
      final linearLayout = frameLayout.children.first;
      
      // Find specific elements for testing
      final titleElement = linearLayout.children.firstWhere(
        (element) => element.resourceId == 'com.example.app:id/title'
      );
      final usernameField = linearLayout.children.firstWhere(
        (element) => element.resourceId == 'com.example.app:id/username_field'
      );
      final loginButton = linearLayout.children.firstWhere(
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
      expect(usernameField.enabled, isTrue);
      expect(usernameField.bounds, equals(const Rect.fromLTWH(100, 350, 880, 100)));
      
      // Test login button properties
      expect(loginButton.text, equals('Login'));
      expect(loginButton.contentDesc, equals('Login button'));
      expect(loginButton.className, equals('android.widget.Button'));
      expect(loginButton.clickable, isTrue);
      expect(loginButton.enabled, isTrue);
      expect(loginButton.bounds, equals(const Rect.fromLTWH(100, 650, 880, 100)));
      
      // Test hierarchy relationships (depth starts from hierarchy root)
      expect(titleElement.depth, equals(3)); // hierarchy -> FrameLayout -> LinearLayout -> TextView
      expect(usernameField.depth, equals(3));
      expect(loginButton.depth, equals(3));
      
      // Test parent relationships
      expect(titleElement.parent?.className, equals('android.widget.LinearLayout'));
      expect(usernameField.parent, equals(titleElement.parent));
      expect(loginButton.parent, equals(titleElement.parent));
    });
    
    test('XML string parsing', () async {
      // Test parsing from string instead of file
      final rootElement = await xmlParser.parseXMLString(testXmlContent);
      
      // Verify structure is the same as file parsing
      expect(rootElement, isNotNull);
      expect(rootElement.className, equals('hierarchy'));
      expect(rootElement.children.length, equals(1));
      
      final frameLayout = rootElement.children.first;
      expect(frameLayout.className, equals('android.widget.FrameLayout'));
      final linearLayout = frameLayout.children.first;
      expect(linearLayout.children.length, equals(4));
      
      // Verify specific element
      final titleElement = linearLayout.children[0];
      expect(titleElement.text, equals('Login Screen'));
    });
    
    test('Error handling for invalid XML', () async {
      // Test invalid XML file
      expect(
        () => xmlParser.parseXMLFile('/nonexistent/file.xml'),
        throwsA(isA<XMLParseException>()),
      );
      
      // Test malformed XML string
      const malformedXml = '<?xml version="1.0"?><hierarchy><node><unclosed></hierarchy>';
      
      expect(
        () => xmlParser.parseXMLString(malformedXml),
        throwsA(isA<XMLParseException>()),
      );
      
      // Test empty XML
      expect(
        () => xmlParser.parseXMLString(''),
        throwsA(isA<XMLParseException>()),
      );
    });
    
    test('XML validation through parsing', () async {
      // Test valid XML by attempting to parse
      try {
        final rootElement = await xmlParser.parseXMLString(testXmlContent);
        expect(rootElement, isNotNull);
      } catch (e) {
        fail('Valid XML should parse successfully');
      }
      
      // Test invalid XML
      const invalidXml = '<hierarchy><node><unclosed></hierarchy>';
      expect(
        () => xmlParser.parseXMLString(invalidXml),
        throwsA(isA<XMLParseException>()),
      );
      
      // Test empty content
      expect(
        () => xmlParser.parseXMLString(''),
        throwsA(isA<XMLParseException>()),
      );
    });
    
    test('Performance with moderately complex hierarchy', () async {
      // Create a moderately complex XML structure
      final complexXmlBuffer = StringBuffer();
      complexXmlBuffer.write('<?xml version="1.0" encoding="UTF-8"?><hierarchy rotation="0">');
      complexXmlBuffer.write('<node index="0" class="android.widget.FrameLayout" bounds="[0,0][1080,1920]">');
      
      // Generate 50 nested elements
      for (int i = 0; i < 50; i++) {
        complexXmlBuffer.write('''
          <node index="$i" text="Element $i" resource-id="com.test:id/element_$i" 
                class="android.widget.TextView" package="com.test" 
                clickable="${i % 2 == 0}" enabled="true" 
                bounds="[${i * 10},${i * 10}][${i * 10 + 100},${i * 10 + 50}]">
        ''');
      }
      
      // Close all nodes
      for (int i = 0; i < 50; i++) {
        complexXmlBuffer.write('</node>');
      }
      complexXmlBuffer.write('</node></hierarchy>');
      
      // Test parsing performance
      final stopwatch = Stopwatch()..start();
      final complexRoot = await xmlParser.parseXMLString(complexXmlBuffer.toString());
      stopwatch.stop();
      
      // Should parse within reasonable time (less than 500ms for 50 elements)
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      
      // Verify structure
      expect(complexRoot, isNotNull);
      expect(complexRoot.className, equals('hierarchy'));
      
      final actualRoot = complexRoot.children.first;
      expect(actualRoot.className, equals('android.widget.FrameLayout'));
      
      // Navigate to nested elements
      var currentElement = actualRoot;
      int depth = 0;
      while (currentElement.children.isNotEmpty && depth < 10) {
        currentElement = currentElement.children.first;
        depth++;
      }
      
      // Should have navigated through several levels
      expect(depth, greaterThan(5));
    });
    
    test('Real-world XML structure parsing', () async {
      // Test with a realistic Android UI dump structure
      const realWorldXml = '''<?xml version='1.0' encoding='UTF-8' standalone='yes'?>
<hierarchy rotation="0">
  <node index="0" text="" resource-id="" class="android.widget.FrameLayout" package="com.android.systemui" bounds="[0,0][1080,1920]">
    <node index="0" text="" resource-id="android:id/statusBarBackground" class="android.view.View" package="com.android.systemui" bounds="[0,0][1080,72]"/>
    <node index="1" text="" resource-id="android:id/content" class="android.widget.FrameLayout" package="com.example.myapp" bounds="[0,72][1080,1848]">
      <node index="0" text="" resource-id="" class="android.widget.RelativeLayout" package="com.example.myapp" bounds="[0,72][1080,1848]">
        <node index="0" text="" resource-id="com.example.myapp:id/toolbar" class="androidx.appcompat.widget.Toolbar" package="com.example.myapp" bounds="[0,72][1080,216]">
          <node index="0" text="My App" resource-id="" class="android.widget.TextView" package="com.example.myapp" bounds="[72,126][200,162]"/>
          <node index="1" text="" resource-id="" class="android.widget.ImageButton" package="com.example.myapp" content-desc="More options" clickable="true" enabled="true" focusable="true" bounds="[936,72][1080,216]"/>
        </node>
        <node index="1" text="" resource-id="com.example.myapp:id/recycler_view" class="androidx.recyclerview.widget.RecyclerView" package="com.example.myapp" scrollable="true" bounds="[0,216][1080,1848]">
          <node index="0" text="" resource-id="" class="android.widget.LinearLayout" package="com.example.myapp" clickable="true" bounds="[0,216][1080,360]">
            <node index="0" text="Item 1" resource-id="com.example.myapp:id/item_title" class="android.widget.TextView" package="com.example.myapp" bounds="[72,240][500,276]"/>
            <node index="1" text="Description for item 1" resource-id="com.example.myapp:id/item_description" class="android.widget.TextView" package="com.example.myapp" bounds="[72,288][800,324]"/>
          </node>
        </node>
      </node>
    </node>
  </node>
</hierarchy>''';
      
      // Parse complex structure
      final complexRoot = await xmlParser.parseXMLString(realWorldXml);
      
      // Verify structure parsing
      expect(complexRoot, isNotNull);
      expect(complexRoot.className, equals('hierarchy'));
      
      final actualFrameLayout = complexRoot.children.first;
      expect(actualFrameLayout.className, equals('android.widget.FrameLayout'));
      
      // Navigate to specific elements
      final contentFrame = actualFrameLayout.children[1]; // android:id/content
      expect(contentFrame.resourceId, equals('android:id/content'));
      
      final relativeLayout = contentFrame.children[0];
      expect(relativeLayout.className, equals('android.widget.RelativeLayout'));
      
      final toolbar = relativeLayout.children[0];
      expect(toolbar.resourceId, equals('com.example.myapp:id/toolbar'));
      expect(toolbar.className, equals('androidx.appcompat.widget.Toolbar'));
      
      final appTitle = toolbar.children[0];
      expect(appTitle.text, equals('My App'));
      expect(appTitle.className, equals('android.widget.TextView'));
      
      final moreButton = toolbar.children[1];
      expect(moreButton.contentDesc, equals('More options'));
      expect(moreButton.clickable, isTrue);
      
      final recyclerView = relativeLayout.children[1];
      expect(recyclerView.resourceId, equals('com.example.myapp:id/recycler_view'));
      expect(recyclerView.className, equals('androidx.recyclerview.widget.RecyclerView'));
      
      final listItem = recyclerView.children[0];
      expect(listItem.clickable, isTrue);
      
      final itemTitle = listItem.children[0];
      expect(itemTitle.text, equals('Item 1'));
      expect(itemTitle.resourceId, equals('com.example.myapp:id/item_title'));
      
      final itemDescription = listItem.children[1];
      expect(itemDescription.text, equals('Description for item 1'));
      expect(itemDescription.resourceId, equals('com.example.myapp:id/item_description'));
    });
    
    test('Bounds parsing accuracy', () async {
      final rootElement = await xmlParser.parseXMLFile(tempXmlFile.path);
      final frameLayout = rootElement.children.first;
      final linearLayout = frameLayout.children.first;
      
      // Test various bounds formats
      final titleElement = linearLayout.children[0];
      expect(titleElement.bounds.left, equals(100.0));
      expect(titleElement.bounds.top, equals(200.0));
      expect(titleElement.bounds.right, equals(980.0));
      expect(titleElement.bounds.bottom, equals(300.0));
      expect(titleElement.bounds.width, equals(880.0));
      expect(titleElement.bounds.height, equals(100.0));
      
      // Test frame layout bounds (full screen)
      expect(frameLayout.bounds.left, equals(0.0));
      expect(frameLayout.bounds.top, equals(0.0));
      expect(frameLayout.bounds.right, equals(1080.0));
      expect(frameLayout.bounds.bottom, equals(1920.0));
      expect(frameLayout.bounds.width, equals(1080.0));
      expect(frameLayout.bounds.height, equals(1920.0));
    });
    
    test('Element finding and traversal', () async {
      final rootElement = await xmlParser.parseXMLFile(tempXmlFile.path);
      
      // Test finding element by resource ID
      UIElement? foundElement = _findElementByResourceId(rootElement, 'com.example.app:id/login_button');
      expect(foundElement, isNotNull);
      expect(foundElement!.text, equals('Login'));
      
      // Test finding element by text
      foundElement = _findElementByText(rootElement, 'Login Screen');
      expect(foundElement, isNotNull);
      expect(foundElement!.resourceId, equals('com.example.app:id/title'));
      
      // Test finding element by class name
      final editTextElements = _findElementsByClassName(rootElement, 'android.widget.EditText');
      expect(editTextElements.length, equals(2)); // username and password fields
      
      // Test finding clickable elements
      final clickableElements = _findClickableElements(rootElement);
      expect(clickableElements.length, equals(3)); // username, password, login button
    });
  });
}

// Helper functions for element finding
UIElement? _findElementByResourceId(UIElement root, String resourceId) {
  if (root.resourceId == resourceId) {
    return root;
  }
  
  for (final child in root.children) {
    final found = _findElementByResourceId(child, resourceId);
    if (found != null) {
      return found;
    }
  }
  
  return null;
}

UIElement? _findElementByText(UIElement root, String text) {
  if (root.text == text) {
    return root;
  }
  
  for (final child in root.children) {
    final found = _findElementByText(child, text);
    if (found != null) {
      return found;
    }
  }
  
  return null;
}

List<UIElement> _findElementsByClassName(UIElement root, String className) {
  final results = <UIElement>[];
  
  if (root.className == className) {
    results.add(root);
  }
  
  for (final child in root.children) {
    results.addAll(_findElementsByClassName(child, className));
  }
  
  return results;
}

List<UIElement> _findClickableElements(UIElement root) {
  final results = <UIElement>[];
  
  if (root.clickable) {
    results.add(root);
  }
  
  for (final child in root.children) {
    results.addAll(_findClickableElements(child));
  }
  
  return results;
}