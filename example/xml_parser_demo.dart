import 'dart:io';
import '../lib/services/xml_parser.dart';

/// Demo script to show XML parser functionality
void main() async {
  final parser = XMLParser();
  
  print('🔍 XML Parser Demo');
  print('==================');
  
  // Test with sample XML content
  const sampleXML = '''<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>
<hierarchy rotation="0">
  <node index="0" text="平安证券" resource-id="com.hexin.plat.android:id/page_title_view" class="android.widget.TextView" package="com.hexin.plat.android" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="true" bounds="[488,136][712,211]">
    <node index="0" text="买入" resource-id="com.hexin.plat.android:id/btn" class="android.widget.TextView" package="com.hexin.plat.android" content-desc="买入" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,278][240,409]" />
    <node index="1" text="卖出" resource-id="com.hexin.plat.android:id/btn" class="android.widget.TextView" package="com.hexin.plat.android" content-desc="卖出" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="true" bounds="[240,278][480,409]" />
  </node>
</hierarchy>''';

  try {
    print('\n📄 Parsing sample XML...');
    final root = await parser.parseXMLString(sampleXML);
    
    print('✅ XML parsed successfully!');
    print('Root element: ${root.className}');
    print('Children count: ${root.children.length}');
    
    if (root.children.isNotEmpty) {
      final firstChild = root.children[0];
      print('\nFirst child details:');
      print('  Text: "${firstChild.text}"');
      print('  Class: ${firstChild.className}');
      print('  Resource ID: ${firstChild.resourceId}');
      print('  Bounds: ${firstChild.boundsString}');
      print('  Children: ${firstChild.children.length}');
      
      // Show nested children
      for (int i = 0; i < firstChild.children.length; i++) {
        final child = firstChild.children[i];
        print('    Child $i: "${child.text}" (${child.clickable ? 'clickable' : 'not clickable'})');
      }
    }
    
    // Test flattening
    print('\n📋 Flattening hierarchy...');
    final flatList = await parser.flattenHierarchy(root);
    print('Total elements in flat list: ${flatList.length}');
    
    // Show all elements with text
    final elementsWithText = flatList.where((e) => e.text.isNotEmpty).toList();
    print('\nElements with text:');
    for (final element in elementsWithText) {
      print('  "${element.text}" (${element.className.split('.').last})');
    }
    
    // Test statistics
    print('\n📊 Hierarchy statistics:');
    final stats = parser.getHierarchyStats(root);
    print('  Total elements: ${stats['totalElements']}');
    print('  Max depth: ${stats['maxDepth']}');
    print('  Clickable elements: ${stats['clickableElements']}');
    print('  Elements with text: ${stats['elementsWithText']}');
    print('  Leaf nodes: ${stats['leafNodes']}');
    print('  Branch nodes: ${stats['branchNodes']}');
    
    // Test search functionality
    print('\n🔍 Search functionality:');
    final clickableElements = root.findClickableElements();
    print('Found ${clickableElements.length} clickable elements:');
    for (final element in clickableElements) {
      print('  "${element.text}" at ${element.boundsString}');
    }
    
    // Test hierarchy path
    print('\n🗂️ Hierarchy paths:');
    for (final element in flatList.take(5)) {
      final path = parser.getHierarchyPath(element);
      print('  ${element.displayText.isEmpty ? element.className.split('.').last : element.displayText} -> $path');
    }
    
    print('\n✅ Demo completed successfully!');
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}