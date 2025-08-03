import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dump_ui_tools/services/xml_parser.dart';
import 'package:dump_ui_tools/models/ui_element.dart';

void main() {
  group('XMLParser', () {
    late XMLParser parser;
    late Directory tempDir;

    setUp(() async {
      parser = XMLParser();
      tempDir = await Directory.systemTemp.createTemp('xml_parser_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      XMLParser.clearCache();
    });

    group('Basic XML Parsing', () {
      test('should parse simple XML hierarchy', () async {
        const xmlContent = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node text="Hello World" class="android.widget.TextView" 
        clickable="true" enabled="true" bounds="[0,0][100,50]" index="0"/>
</hierarchy>''';

        final result = await parser.parseXMLString(xmlContent);

        expect(result.className, equals('hierarchy'));
        expect(result.children.length, equals(1));
        
        final child = result.children.first;
        expect(child.text, equals('Hello World'));
        expect(child.className, equals('android.widget.TextView'));
        expect(child.clickable, isTrue);
        expect(child.enabled, isTrue);
        expect(child.bounds, equals(const Rect.fromLTRB(0, 0, 100, 50)));
        expect(child.index, equals(0));
      });

      test('should parse nested XML hierarchy', () async {
        const xmlContent = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node class="android.widget.LinearLayout" bounds="[0,0][200,100]" index="0">
    <node text="Button 1" class="android.widget.Button" 
          clickable="true" bounds="[10,10][90,40]" index="0"/>
    <node text="Button 2" class="android.widget.Button" 
          clickable="true" bounds="[110,10][190,40]" index="1"/>
  </node>
</hierarchy>''';

        final result = await parser.parseXMLString(xmlContent);

        expect(result.children.length, equals(1));
        
        final layout = result.children.first;
        expect(layout.className, equals('android.widget.LinearLayout'));
        expect(layout.children.length, equals(2));
        
        final button1 = layout.children[0];
        expect(button1.text, equals('Button 1'));
        expect(button1.clickable, isTrue);
        expect(button1.index, equals(0));
        
        final button2 = layout.children[1];
        expect(button2.text, equals('Button 2'));
        expect(button2.clickable, isTrue);
        expect(button2.index, equals(1));
      });

      test('should handle empty XML elements', () async {
        const xmlContent = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node class="android.widget.View" bounds="[0,0][100,50]" index="0"/>
</hierarchy>''';

        final result = await parser.parseXMLString(xmlContent);
        final child = result.children.first;

        expect(child.text, isEmpty);
        expect(child.contentDesc, isEmpty);
        expect(child.resourceId, isEmpty);
        expect(child.packageName, isEmpty);
        expect(child.clickable, isFalse);
        expect(child.enabled, isTrue); // Default value
      });

      test('should parse all supported attributes', () async {
        const xmlContent = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node text="Test Text" 
        content-desc="Test Description"
        class="android.widget.Button"
        package="com.example.app"
        resource-id="com.example.app:id/test_button"
        clickable="true"
        enabled="false"
        bounds="[10,20][110,70]"
        index="5"/>
</hierarchy>''';

        final result = await parser.parseXMLString(xmlContent);
        final element = result.children.first;

        expect(element.text, equals('Test Text'));
        expect(element.contentDesc, equals('Test Description'));
        expect(element.className, equals('android.widget.Button'));
        expect(element.packageName, equals('com.example.app'));
        expect(element.resourceId, equals('com.example.app:id/test_button'));
        expect(element.clickable, isTrue);
        expect(element.enabled, isFalse);
        expect(element.bounds, equals(const Rect.fromLTRB(10, 20, 110, 70)));
        expect(element.index, equals(5));
      });
    });

    group('Error Handling', () {
      test('should throw XMLParseException for invalid XML', () async {
        const invalidXml = '<invalid><unclosed>';

        expect(
          () => parser.parseXMLString(invalidXml),
          throwsA(isA<XMLParseException>()),
        );
      });

      test('should throw XMLParseException for missing hierarchy', () async {
        const xmlWithoutHierarchy = '''<?xml version='1.0' encoding='UTF-8'?>
<root>
  <node text="Test"/>
</root>''';

        expect(
          () => parser.parseXMLString(xmlWithoutHierarchy),
          throwsA(isA<XMLParseException>()),
        );
      });

      test('should throw XMLParseException for invalid bounds format', () async {
        const xmlWithInvalidBounds = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node text="Test" bounds="invalid_bounds"/>
</hierarchy>''';

        expect(
          () => parser.parseXMLString(xmlWithInvalidBounds),
          throwsA(isA<XMLParseException>()),
        );
      });

      test('should handle file not found error', () async {
        expect(
          () => parser.parseXMLFile('/non/existent/file.xml'),
          throwsA(isA<XMLParseException>()),
        );
      });

      test('should handle empty file', () async {
        final emptyFile = File('${tempDir.path}/empty.xml');
        await emptyFile.writeAsString('');

        expect(
          () => parser.parseXMLFile(emptyFile.path),
          throwsA(isA<XMLParseException>()),
        );
      });
    });

    group('File Operations', () {
      test('should parse XML from file', () async {
        const xmlContent = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node text="File Test" class="android.widget.TextView" bounds="[0,0][100,50]"/>
</hierarchy>''';

        final testFile = File('${tempDir.path}/test.xml');
        await testFile.writeAsString(xmlContent);

        final result = await parser.parseXMLFile(testFile.path);

        expect(result.children.length, equals(1));
        expect(result.children.first.text, equals('File Test'));
      });

      test('should validate XML content', () {
        const validXml = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node text="Valid"/>
</hierarchy>''';

        const invalidXml = '<invalid>';

        expect(parser.validateXMLContent(validXml), isTrue);
        expect(parser.validateXMLContent(invalidXml), isFalse);
      });
    });

    group('Hierarchy Processing', () {
      test('should build parent-child relationships correctly', () async {
        const xmlContent = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node class="android.widget.LinearLayout" bounds="[0,0][200,100]">
    <node text="Child 1" class="android.widget.TextView" bounds="[0,0][100,50]">
      <node text="Grandchild" class="android.widget.View" bounds="[0,0][50,25]"/>
    </node>
    <node text="Child 2" class="android.widget.TextView" bounds="[100,0][200,50]"/>
  </node>
</hierarchy>''';

        final result = await parser.parseXMLFileWithHierarchy(tempDir.path);
        final testFile = File('${tempDir.path}/hierarchy_test.xml');
        await testFile.writeAsString(xmlContent);

        final hierarchy = await parser.parseXMLFile(testFile.path);
        
        final layout = hierarchy.children.first;
        final child1 = layout.children.first;
        final child2 = layout.children.last;
        final grandchild = child1.children.first;

        // Verify parent-child relationships
        expect(child1.parent, equals(layout));
        expect(child2.parent, equals(layout));
        expect(grandchild.parent, equals(child1));

        // Verify depths
        expect(layout.depth, equals(1));
        expect(child1.depth, equals(2));
        expect(child2.depth, equals(2));
        expect(grandchild.depth, equals(3));
      });

      test('should flatten hierarchy correctly', () async {
        const xmlContent = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node class="Root" bounds="[0,0][200,100]">
    <node text="Child 1" class="Child1" bounds="[0,0][100,50]"/>
    <node text="Child 2" class="Child2" bounds="[100,0][200,50]"/>
  </node>
</hierarchy>''';

        final testFile = File('${tempDir.path}/flatten_test.xml');
        await testFile.writeAsString(xmlContent);

        final hierarchy = await parser.parseXMLFile(testFile.path);
        final flatList = await parser.flattenHierarchy(hierarchy);

        expect(flatList.length, equals(4)); // root + layout + 2 children
        expect(flatList[0].className, equals('hierarchy')); // root
        expect(flatList[1].className, equals('Root')); // layout
        expect(flatList[2].className, equals('Child1')); // first child
        expect(flatList[3].className, equals('Child2')); // second child
      });

      test('should generate hierarchy statistics', () async {
        const xmlContent = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node class="android.widget.LinearLayout" clickable="false" enabled="true">
    <node text="Button 1" class="android.widget.Button" clickable="true" enabled="true"/>
    <node text="Button 2" class="android.widget.Button" clickable="true" enabled="false"/>
    <node text="Text View" class="android.widget.TextView" clickable="false" enabled="true"/>
  </node>
</hierarchy>''';

        final testFile = File('${tempDir.path}/stats_test.xml');
        await testFile.writeAsString(xmlContent);

        final hierarchy = await parser.parseXMLFile(testFile.path);
        final stats = parser.getHierarchyStats(hierarchy);

        expect(stats['totalElements'], equals(5)); // root + layout + 3 children
        expect(stats['clickableElements'], equals(2)); // 2 buttons
        expect(stats['enabledElements'], equals(4)); // all except disabled button
        expect(stats['elementsWithText'], equals(3)); // 3 elements with text
        expect(stats['maxDepth'], equals(2));
        expect(stats['leafNodes'], equals(3)); // 3 children with no children
        expect(stats['branchNodes'], equals(2)); // root and layout
      });
    });

    group('Performance Features', () {
      test('should cache parsing results', () async {
        const xmlContent = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node text="Cached Test" class="android.widget.TextView"/>
</hierarchy>''';

        final testFile = File('${tempDir.path}/cache_test.xml');
        await testFile.writeAsString(xmlContent);

        // First parse
        final result1 = await parser.parseXMLFile(testFile.path);
        
        // Second parse should use cache
        final result2 = await parser.parseXMLFile(testFile.path);

        expect(result1.children.first.text, equals(result2.children.first.text));
        
        final cacheStats = XMLParser.getCacheStats();
        expect(cacheStats['cacheSize'], greaterThan(0));
      });

      test('should provide performance metrics', () {
        final metrics = parser.getPerformanceMetrics();

        expect(metrics.containsKey('cacheHitRate'), isTrue);
        expect(metrics.containsKey('cacheSize'), isTrue);
        expect(metrics.containsKey('maxCacheSize'), isTrue);
        expect(metrics.containsKey('chunkSize'), isTrue);
        expect(metrics.containsKey('largeFileThreshold'), isTrue);
      });

      test('should handle large files with chunked parsing', () async {
        // Create a large XML content
        final buffer = StringBuffer();
        buffer.writeln('<?xml version=\'1.0\' encoding=\'UTF-8\'?>');
        buffer.writeln('<hierarchy rotation="0">');
        
        // Add many nodes to exceed threshold
        for (int i = 0; i < 100; i++) {
          buffer.writeln('  <node text="Element $i" class="android.widget.TextView" bounds="[0,$i][100,${i + 50}]"/>');
        }
        
        buffer.writeln('</hierarchy>');

        final largeXmlContent = buffer.toString();
        final testFile = File('${tempDir.path}/large_test.xml');
        await testFile.writeAsString(largeXmlContent);

        final result = await parser.parseXMLFile(testFile.path);

        expect(result.children.length, equals(100));
        expect(result.children.first.text, equals('Element 0'));
        expect(result.children.last.text, equals('Element 99'));
      });

      test('should provide memory-efficient streaming', () async {
        const xmlContent = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node class="Root">
    <node text="Child 1"/>
    <node text="Child 2"/>
  </node>
</hierarchy>''';

        final testFile = File('${tempDir.path}/stream_test.xml');
        await testFile.writeAsString(xmlContent);

        final hierarchy = await parser.parseXMLFile(testFile.path);
        final streamedElements = <UIElement>[];

        await for (final element in parser.flattenHierarchyStream(hierarchy)) {
          streamedElements.add(element);
        }

        expect(streamedElements.length, equals(4)); // root + layout + 2 children
      });
    });

    group('Hierarchy Path Operations', () {
      test('should find elements by hierarchy path', () async {
        const xmlContent = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node class="android.widget.LinearLayout">
    <node class="android.widget.TextView" text="Target"/>
    <node class="android.widget.Button" text="Button"/>
  </node>
</hierarchy>''';

        final testFile = File('${tempDir.path}/path_test.xml');
        await testFile.writeAsString(xmlContent);

        final hierarchy = await parser.parseXMLFile(testFile.path);
        final results = parser.findByHierarchyPath(hierarchy, 'hierarchy/LinearLayout/TextView');

        expect(results.length, equals(1));
        expect(results.first.text, equals('Target'));
      });

      test('should get hierarchy path for element', () async {
        const xmlContent = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node class="android.widget.LinearLayout">
    <node class="android.widget.TextView" text="Target"/>
  </node>
</hierarchy>''';

        final testFile = File('${tempDir.path}/path_get_test.xml');
        await testFile.writeAsString(xmlContent);

        final hierarchy = await parser.parseXMLFile(testFile.path);
        final textView = hierarchy.children.first.children.first;
        final path = parser.getHierarchyPath(textView);

        expect(path, equals('hierarchy/LinearLayout/TextView'));
      });

      test('should validate hierarchy integrity', () async {
        const xmlContent = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node class="android.widget.LinearLayout">
    <node class="android.widget.TextView" text="Valid"/>
  </node>
</hierarchy>''';

        final testFile = File('${tempDir.path}/integrity_test.xml');
        await testFile.writeAsString(xmlContent);

        final hierarchy = await parser.parseXMLFile(testFile.path);
        final isValid = parser.validateHierarchyIntegrity(hierarchy);

        expect(isValid, isTrue);
      });
    });

    group('XML Formatting and Highlighting', () {
      test('should format XML with syntax highlighting', () {
        const xmlContent = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node text="Test" class="android.widget.TextView"/>
</hierarchy>''';

        final highlightWidget = parser.formatXMLWithHighlight(xmlContent);

        expect(highlightWidget, isA<Widget>());
      });

      test('should create XML viewer with line numbers', () {
        const xmlContent = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node text="Test"/>
</hierarchy>''';

        final viewerWidget = parser.createXMLViewerWithLineNumbers(xmlContent);

        expect(viewerWidget, isA<Widget>());
      });

      test('should highlight specific attribute values', () {
        const xmlContent = '''<?xml version='1.0' encoding='UTF-8'?>
<hierarchy rotation="0">
  <node text="Highlight Me" class="android.widget.TextView"/>
</hierarchy>''';

        final highlighted = parser.highlightAttributeValues(xmlContent, ['text']);

        expect(highlighted, contains('**Highlight Me**'));
      });

      test('should get XML line numbers', () {
        const xmlContent = '''Line 1
Line 2
Line 3''';

        final lineNumbers = parser.getXMLLineNumbers(xmlContent);

        expect(lineNumbers, equals([1, 2, 3]));
      });
    });
  });
}