import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import '../../lib/services/xml_parser.dart';

void main() {
  group('XMLParser Integration Tests', () {
    late XMLParser parser;

    setUp(() {
      parser = XMLParser();
    });

    test('should parse real UI dump file if available', () async {
      // Try to find a real dump file
      final dumpDir = Directory('ui_tools/dumps');
      if (!await dumpDir.exists()) {
        print('Skipping integration test - no dump files available');
        return;
      }

      final dumpFiles = await dumpDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.xml'))
          .cast<File>()
          .toList();

      if (dumpFiles.isEmpty) {
        print('Skipping integration test - no XML dump files found');
        return;
      }

      // Use the first available dump file
      final dumpFile = dumpFiles.first;
      print('Testing with dump file: ${dumpFile.path}');

      try {
        final root = await parser.parseXMLFile(dumpFile.path);
        
        // Basic validation
        expect(root, isNotNull);
        expect(root.className, equals('hierarchy'));
        
        // Should have at least some elements
        final flatList = await parser.flattenHierarchy(root);
        expect(flatList.length, greaterThan(1));
        
        // Should have some statistics
        final stats = parser.getHierarchyStats(root);
        expect(stats['totalElements'], greaterThan(0));
        expect(stats['maxDepth'], greaterThan(0));
        
        // Should be able to find some elements with text
        final elementsWithText = root.findElementsWithText();
        expect(elementsWithText, isNotEmpty);
        
        // Should be able to find some clickable elements
        final clickableElements = root.findClickableElements();
        expect(clickableElements, isNotEmpty);
        
        print('✅ Successfully parsed ${flatList.length} elements');
        print('   - Max depth: ${stats['maxDepth']}');
        print('   - Clickable elements: ${stats['clickableElements']}');
        print('   - Elements with text: ${stats['elementsWithText']}');
        
      } catch (e) {
        fail('Failed to parse real dump file: $e');
      }
    });

    test('should validate hierarchy integrity with real data', () async {
      // Create a more complex test XML based on real structure
      const complexXML = '''<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>
<hierarchy rotation="0">
  <node index="0" text="" resource-id="" class="android.widget.FrameLayout" package="com.hexin.plat.android" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,0][1200,2664]">
    <node index="1" text="" resource-id="" class="android.widget.LinearLayout" package="com.hexin.plat.android" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,0][1200,2592]">
      <node index="0" text="买入" resource-id="com.hexin.plat.android:id/btn" class="android.widget.TextView" package="com.hexin.plat.android" content-desc="买入" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,278][240,409]" />
      <node index="1" text="卖出" resource-id="com.hexin.plat.android:id/btn" class="android.widget.TextView" package="com.hexin.plat.android" content-desc="卖出" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="true" bounds="[240,278][480,409]" />
    </node>
  </node>
</hierarchy>''';

      final root = await parser.parseXMLString(complexXML);
      
      // Validate hierarchy integrity
      expect(parser.validateHierarchyIntegrity(root), isTrue);
      
      // Test parent-child relationships
      final frameLayout = root.children[0];
      expect(frameLayout.parent, equals(root));
      expect(frameLayout.depth, equals(1));
      
      final linearLayout = frameLayout.children[0];
      expect(linearLayout.parent, equals(frameLayout));
      expect(linearLayout.depth, equals(2));
      
      final buyButton = linearLayout.children[0];
      expect(buyButton.parent, equals(linearLayout));
      expect(buyButton.depth, equals(3));
      expect(buyButton.text, equals('买入'));
      expect(buyButton.clickable, isTrue);
      
      final sellButton = linearLayout.children[1];
      expect(sellButton.parent, equals(linearLayout));
      expect(sellButton.depth, equals(3));
      expect(sellButton.text, equals('卖出'));
      expect(sellButton.clickable, isTrue);
    });

    test('should handle NAF attributes correctly', () async {
      const xmlWithNAF = '''<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>
<hierarchy rotation="0">
  <node NAF="true" index="0" text="" resource-id="" class="android.widget.LinearLayout" package="com.hexin.plat.android" content-desc="" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,121][206,278]">
    <node index="0" text="" resource-id="com.hexin.plat.android:id/title_bar_img" class="android.widget.ImageView" package="com.hexin.plat.android" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[52,160][131,239]" />
  </node>
</hierarchy>''';

      final root = await parser.parseXMLString(xmlWithNAF);
      
      expect(root.children.length, equals(1));
      final nafElement = root.children[0];
      expect(nafElement.className, equals('android.widget.LinearLayout'));
      expect(nafElement.clickable, isTrue);
      expect(nafElement.children.length, equals(1));
      
      final imageView = nafElement.children[0];
      expect(imageView.className, equals('android.widget.ImageView'));
      expect(imageView.resourceId, equals('com.hexin.plat.android:id/title_bar_img'));
    });
  });
}