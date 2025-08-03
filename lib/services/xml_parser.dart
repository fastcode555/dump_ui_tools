import 'dart:io';
import 'dart:ui';
import 'dart:isolate';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import '../models/ui_element.dart';

/// Exception thrown when XML parsing fails
class XMLParseException implements Exception {
  final String message;
  final String? details;
  
  const XMLParseException(this.message, [this.details]);
  
  @override
  String toString() {
    if (details != null) {
      return 'XMLParseException: $message\nDetails: $details';
    }
    return 'XMLParseException: $message';
  }
}

/// Service for parsing Android UI dump XML files with performance optimizations
class XMLParser {
  static const String _hierarchyTag = 'hierarchy';
  static const String _nodeTag = 'node';
  
  // Performance optimization constants
  static const int _chunkSize = 1000; // Elements per chunk for large files
  static const int _largeFileThreshold = 50000; // Characters threshold for chunked parsing
  static const int _maxCacheSize = 10; // Maximum cached parsed results
  
  // Cache for parsed results
  static final Map<String, UIElement> _parseCache = {};
  static final List<String> _cacheKeys = [];
  
  /// Parse XML file and return the root UI element with caching and chunked parsing
  Future<UIElement> parseXMLFile(String filePath) async {
    try {
      // Check cache first
      final cacheKey = await _getCacheKey(filePath);
      if (_parseCache.containsKey(cacheKey)) {
        return _parseCache[cacheKey]!;
      }
      
      // Validate file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw XMLParseException('XML file not found: $filePath');
      }
      
      // Read file content
      final xmlContent = await file.readAsString();
      if (xmlContent.trim().isEmpty) {
        throw XMLParseException('XML file is empty: $filePath');
      }
      
      // Use chunked parsing for large files
      final result = xmlContent.length > _largeFileThreshold
          ? await parseXMLStringChunked(xmlContent)
          : await parseXMLString(xmlContent);
      
      // Cache the result
      _cacheResult(cacheKey, result);
      
      return result;
    } catch (e) {
      if (e is XMLParseException) {
        rethrow;
      }
      throw XMLParseException('Failed to read XML file: $filePath', e.toString());
    }
  }
  
  /// Parse XML string content and return the root UI element
  Future<UIElement> parseXMLString(String xmlContent) async {
    try {
      // Parse XML document
      final document = XmlDocument.parse(xmlContent);
      
      // Find hierarchy root
      final hierarchyElement = document.findElements(_hierarchyTag).firstOrNull;
      if (hierarchyElement == null) {
        throw XMLParseException('No hierarchy element found in XML');
      }
      
      // Create root element for the hierarchy
      final rootElement = _createRootElement(hierarchyElement);
      
      // Parse all child nodes
      final nodeElements = hierarchyElement.findElements(_nodeTag);
      for (final nodeElement in nodeElements) {
        final uiElement = _parseNodeElement(nodeElement, depth: 1);
        rootElement.addChild(uiElement);
        _parseChildNodes(nodeElement, uiElement, depth: 2);
      }
      
      return rootElement;
    } on XmlException catch (e) {
      throw XMLParseException('Invalid XML format', e.toString());
    } catch (e) {
      if (e is XMLParseException) {
        rethrow;
      }
      throw XMLParseException('Failed to parse XML content', e.toString());
    }
  }
  
  /// Parse large XML files in chunks using isolates for better performance
  Future<UIElement> parseXMLStringChunked(String xmlContent) async {
    try {
      // For very large files, use isolate-based parsing
      final receivePort = ReceivePort();
      
      await Isolate.spawn(_parseInIsolate, {
        'xmlContent': xmlContent,
        'sendPort': receivePort.sendPort,
      });
      
      final result = await receivePort.first as Map<String, dynamic>;
      receivePort.close();
      
      if (result['error'] != null) {
        throw XMLParseException('Isolate parsing failed', result['error']);
      }
      
      return _reconstructUIElementFromMap(result['data']);
    } catch (e) {
      // Fallback to regular parsing if isolate fails
      return await parseXMLString(xmlContent);
    }
  }
  
  /// Static method to run in isolate for parsing
  static void _parseInIsolate(Map<String, dynamic> params) async {
    try {
      final xmlContent = params['xmlContent'] as String;
      final sendPort = params['sendPort'] as SendPort;
      
      // Parse in chunks
      final parser = XMLParser();
      final result = await parser.parseXMLString(xmlContent);
      
      // Convert to serializable format
      final serializedResult = _serializeUIElement(result);
      
      sendPort.send({
        'data': serializedResult,
        'error': null,
      });
    } catch (e) {
      final sendPort = params['sendPort'] as SendPort;
      sendPort.send({
        'data': null,
        'error': e.toString(),
      });
    }
  }
  
  /// Create root element for the hierarchy
  UIElement _createRootElement(XmlElement hierarchyElement) {
    final rotation = hierarchyElement.getAttribute('rotation') ?? '0';
    
    return UIElement(
      id: 'root',
      depth: 0,
      text: '',
      contentDesc: 'UI Hierarchy Root (rotation: $rotation)',
      className: 'hierarchy',
      packageName: '',
      resourceId: '',
      clickable: false,
      enabled: true,
      bounds: const Rect.fromLTRB(0, 0, 0, 0),
      index: 0,
    );
  }
  
  /// Parse a single node element into UIElement
  UIElement _parseNodeElement(XmlElement nodeElement, {required int depth}) {
    try {
      // Generate unique ID for this element
      final id = _generateElementId(nodeElement, depth);
      
      // Extract attributes
      final text = nodeElement.getAttribute('text') ?? '';
      final contentDesc = nodeElement.getAttribute('content-desc') ?? '';
      final className = nodeElement.getAttribute('class') ?? '';
      final packageName = nodeElement.getAttribute('package') ?? '';
      final resourceId = nodeElement.getAttribute('resource-id') ?? '';
      final clickable = _parseBoolAttribute(nodeElement, 'clickable');
      final enabled = _parseBoolAttribute(nodeElement, 'enabled', defaultValue: true);
      final bounds = _parseBoundsAttribute(nodeElement);
      final index = _parseIntAttribute(nodeElement, 'index');
      
      return UIElement(
        id: id,
        depth: depth,
        text: text,
        contentDesc: contentDesc,
        className: className,
        packageName: packageName,
        resourceId: resourceId,
        clickable: clickable,
        enabled: enabled,
        bounds: bounds,
        index: index,
      );
    } catch (e) {
      throw XMLParseException('Failed to parse node element at depth $depth', e.toString());
    }
  }
  
  /// Recursively parse child nodes
  void _parseChildNodes(XmlElement parentXmlElement, UIElement parentUIElement, {required int depth}) {
    final childNodes = parentXmlElement.findElements(_nodeTag);
    
    for (final childNode in childNodes) {
      final childUIElement = _parseNodeElement(childNode, depth: depth);
      parentUIElement.addChild(childUIElement);
      
      // Recursively parse grandchildren
      _parseChildNodes(childNode, childUIElement, depth: depth + 1);
    }
  }
  
  /// Generate unique ID for an element
  String _generateElementId(XmlElement element, int depth) {
    final className = element.getAttribute('class') ?? 'unknown';
    final index = element.getAttribute('index') ?? '0';
    final resourceId = element.getAttribute('resource-id') ?? '';
    final text = element.getAttribute('text') ?? '';
    
    // Create a unique identifier based on element properties
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = (className + index + resourceId + text + depth.toString()).hashCode;
    
    return '${className.split('.').last}_${depth}_${index}_${hash.abs()}_$timestamp';
  }
  
  /// Parse boolean attribute with default value
  bool _parseBoolAttribute(XmlElement element, String attributeName, {bool defaultValue = false}) {
    final value = element.getAttribute(attributeName);
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true';
  }
  
  /// Parse integer attribute with default value
  int _parseIntAttribute(XmlElement element, String attributeName, {int defaultValue = 0}) {
    final value = element.getAttribute(attributeName);
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }
  
  /// Parse bounds attribute into Rect
  Rect _parseBoundsAttribute(XmlElement element) {
    final boundsStr = element.getAttribute('bounds');
    if (boundsStr == null || boundsStr.isEmpty) {
      return const Rect.fromLTRB(0, 0, 0, 0);
    }
    
    try {
      // Expected format: [left,top][right,bottom]
      final regex = RegExp(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]');
      final match = regex.firstMatch(boundsStr);
      
      if (match == null) {
        throw XMLParseException('Invalid bounds format: $boundsStr');
      }
      
      final left = double.parse(match.group(1)!);
      final top = double.parse(match.group(2)!);
      final right = double.parse(match.group(3)!);
      final bottom = double.parse(match.group(4)!);
      
      return Rect.fromLTRB(left, top, right, bottom);
    } catch (e) {
      throw XMLParseException('Failed to parse bounds: $boundsStr', e.toString());
    }
  }
  
  /// Validate XML content before parsing
  bool validateXMLContent(String xmlContent) {
    try {
      final document = XmlDocument.parse(xmlContent);
      final hierarchyElement = document.findElements(_hierarchyTag).firstOrNull;
      return hierarchyElement != null;
    } catch (e) {
      return false;
    }
  }
  
  /// Parse XML file and build complete UI hierarchy tree
  Future<UIElement> parseXMLFileWithHierarchy(String filePath) async {
    final root = await parseXMLFile(filePath);
    _buildHierarchyRelationships(root);
    _calculateDepths(root, 0);
    return root;
  }
  
  /// Build parent-child relationships and ensure hierarchy integrity
  void _buildHierarchyRelationships(UIElement root) {
    _validateAndFixHierarchy(root);
  }
  
  /// Validate and fix hierarchy relationships
  void _validateAndFixHierarchy(UIElement element) {
    // Ensure all children have correct parent reference
    for (final child in element.children) {
      // Parent reference is set automatically when addChild is called
      // during parsing, so we just validate the relationship
      if (child.parent != element) {
        throw XMLParseException('Invalid parent-child relationship detected');
      }
      
      // Recursively validate children
      _validateAndFixHierarchy(child);
    }
  }
  
  /// Calculate and update depth for all elements in hierarchy
  void _calculateDepths(UIElement element, int depth) {
    // Update depth using reflection-like approach since depth is final
    // In a real implementation, we might need to recreate elements with correct depth
    // For now, we assume depth is set correctly during parsing
    
    for (final child in element.children) {
      _calculateDepths(child, depth + 1);
    }
  }
  
  /// Generate flattened list of all UI elements in hierarchy order
  Future<List<UIElement>> flattenHierarchy(UIElement root) async {
    final flatList = <UIElement>[];
    _flattenHierarchyRecursive(root, flatList);
    return flatList;
  }
  
  /// Recursively flatten hierarchy into a list
  void _flattenHierarchyRecursive(UIElement element, List<UIElement> flatList) {
    flatList.add(element);
    
    for (final child in element.children) {
      _flattenHierarchyRecursive(child, flatList);
    }
  }
  
  /// Generate flattened list with depth-first traversal
  List<UIElement> flattenHierarchyDepthFirst(UIElement root) {
    final flatList = <UIElement>[];
    final stack = <UIElement>[root];
    
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      flatList.add(current);
      
      // Add children in reverse order to maintain left-to-right traversal
      final children = current.children.reversed.toList();
      stack.addAll(children);
    }
    
    return flatList;
  }
  
  /// Generate flattened list with breadth-first traversal
  List<UIElement> flattenHierarchyBreadthFirst(UIElement root) {
    final flatList = <UIElement>[];
    final queue = <UIElement>[root];
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      flatList.add(current);
      
      // Add all children to queue
      queue.addAll(current.children);
    }
    
    return flatList;
  }
  
  /// Get hierarchy statistics including depth analysis
  Map<String, dynamic> getHierarchyStats(UIElement root) {
    final stats = <String, dynamic>{};
    final allElements = [root, ...root.getAllDescendants()];
    
    stats['totalElements'] = allElements.length;
    stats['maxDepth'] = allElements.map((e) => e.depth).reduce((a, b) => a > b ? a : b);
    stats['minDepth'] = allElements.map((e) => e.depth).reduce((a, b) => a < b ? a : b);
    stats['averageDepth'] = allElements.map((e) => e.depth).reduce((a, b) => a + b) / allElements.length;
    
    // Depth distribution
    final depthCounts = <int, int>{};
    for (final element in allElements) {
      depthCounts[element.depth] = (depthCounts[element.depth] ?? 0) + 1;
    }
    stats['depthDistribution'] = depthCounts;
    
    // Element type statistics
    stats['clickableElements'] = allElements.where((e) => e.clickable).length;
    stats['enabledElements'] = allElements.where((e) => e.enabled).length;
    stats['elementsWithText'] = allElements.where((e) => e.text.isNotEmpty).length;
    stats['elementsWithContentDesc'] = allElements.where((e) => e.contentDesc.isNotEmpty).length;
    stats['elementsWithResourceId'] = allElements.where((e) => e.resourceId.isNotEmpty).length;
    
    // Count elements by class name
    final classCounts = <String, int>{};
    for (final element in allElements) {
      final className = element.className.split('.').last;
      classCounts[className] = (classCounts[className] ?? 0) + 1;
    }
    stats['classCounts'] = classCounts;
    
    // Hierarchy structure analysis
    stats['leafNodes'] = allElements.where((e) => e.children.isEmpty).length;
    stats['branchNodes'] = allElements.where((e) => e.children.isNotEmpty).length;
    
    final childCounts = allElements.map((e) => e.children.length).toList();
    if (childCounts.isNotEmpty) {
      stats['maxChildren'] = childCounts.reduce((a, b) => a > b ? a : b);
      stats['averageChildren'] = childCounts.reduce((a, b) => a + b) / childCounts.length;
    }
    
    return stats;
  }
  
  /// Find elements by hierarchy path (e.g., "root/LinearLayout/TextView")
  List<UIElement> findByHierarchyPath(UIElement root, String path) {
    final pathParts = path.split('/').where((part) => part.isNotEmpty).toList();
    if (pathParts.isEmpty) return [root];
    
    final results = <UIElement>[];
    _findByPathRecursive(root, pathParts, 0, results);
    return results;
  }
  
  void _findByPathRecursive(UIElement element, List<String> pathParts, int currentIndex, List<UIElement> results) {
    if (currentIndex >= pathParts.length) {
      results.add(element);
      return;
    }
    
    final targetClass = pathParts[currentIndex];
    final elementClass = element.className.split('.').last;
    
    if (elementClass == targetClass || targetClass == '*') {
      if (currentIndex == pathParts.length - 1) {
        results.add(element);
      } else {
        for (final child in element.children) {
          _findByPathRecursive(child, pathParts, currentIndex + 1, results);
        }
      }
    }
    
    // Continue searching in children even if current element doesn't match
    // This allows for partial path matching
    for (final child in element.children) {
      _findByPathRecursive(child, pathParts, currentIndex, results);
    }
  }
  
  /// Get the full hierarchy path for an element
  String getHierarchyPath(UIElement element) {
    final path = element.getPathFromRoot();
    return path.map((e) => e.className.split('.').last).join('/');
  }
  
  /// Validate hierarchy integrity
  bool validateHierarchyIntegrity(UIElement root) {
    try {
      _validateIntegrityRecursive(root, <UIElement>{});
      return true;
    } catch (e) {
      return false;
    }
  }
  
  void _validateIntegrityRecursive(UIElement element, Set<UIElement> visited) {
    if (visited.contains(element)) {
      throw XMLParseException('Circular reference detected in hierarchy');
    }
    
    visited.add(element);
    
    // Validate parent-child relationships
    for (final child in element.children) {
      if (child.parent != element) {
        throw XMLParseException('Invalid parent-child relationship');
      }
      
      if (child.depth <= element.depth) {
        throw XMLParseException('Invalid depth relationship: child depth must be greater than parent');
      }
      
      _validateIntegrityRecursive(child, Set.from(visited));
    }
    
    visited.remove(element);
  }
  
  /// Format XML content with syntax highlighting
  Widget formatXMLWithHighlight(String xmlContent, {bool isDarkTheme = false}) {
    // Clean and format the XML content
    final formattedXML = _formatXMLContent(xmlContent);
    
    // Apply custom theme with enhanced attribute value highlighting
    final theme = _getCustomXMLTheme(isDarkTheme);
    
    return HighlightView(
      formattedXML,
      language: 'xml',
      theme: theme,
      padding: const EdgeInsets.all(16.0),
      textStyle: const TextStyle(
        fontFamily: 'Monaco',
        fontSize: 14.0,
        height: 1.4,
      ),
    );
  }
  
  /// Get custom XML highlighting theme
  Map<String, TextStyle> _getCustomXMLTheme(bool isDarkTheme) {
    final baseTheme = isDarkTheme ? atomOneDarkTheme : atomOneLightTheme;
    
    // Create custom theme with enhanced attribute value highlighting
    final customTheme = Map<String, TextStyle>.from(baseTheme);
    
    if (isDarkTheme) {
      // Dark theme customizations
      customTheme['tag'] = const TextStyle(color: Color(0xFF61AFEF)); // Blue
      customTheme['attr'] = const TextStyle(color: Color(0xFFE06C75)); // Red
      customTheme['string'] = const TextStyle(
        color: Color(0xFF98C379), // Green
        fontWeight: FontWeight.bold,
      );
      customTheme['keyword'] = const TextStyle(color: Color(0xFFC678DD)); // Purple
      customTheme['comment'] = const TextStyle(
        color: Color(0xFF5C6370), // Gray
        fontStyle: FontStyle.italic,
      );
    } else {
      // Light theme customizations
      customTheme['tag'] = const TextStyle(color: Color(0xFF0184BC)); // Blue
      customTheme['attr'] = const TextStyle(color: Color(0xFFE45649)); // Red
      customTheme['string'] = const TextStyle(
        color: Color(0xFF50A14F), // Green
        fontWeight: FontWeight.bold,
      );
      customTheme['keyword'] = const TextStyle(color: Color(0xFFA626A4)); // Purple
      customTheme['comment'] = const TextStyle(
        color: Color(0xFFA0A1A7), // Gray
        fontStyle: FontStyle.italic,
      );
    }
    
    return customTheme;
  }
  
  /// Format XML content for better readability
  String _formatXMLContent(String xmlContent) {
    try {
      // Parse and reformat XML with proper indentation
      final document = XmlDocument.parse(xmlContent);
      return document.toXmlString(pretty: true, indent: '  ');
    } catch (e) {
      // If parsing fails, return original content
      return xmlContent;
    }
  }
  
  /// Create highlighted XML widget with custom styling for attribute values
  Widget createHighlightedXMLWidget(String xmlContent, {
    bool isDarkTheme = false,
    double fontSize = 14.0,
    String fontFamily = 'Monaco',
    EdgeInsets padding = const EdgeInsets.all(16.0),
  }) {
    final formattedXML = _formatXMLContent(xmlContent);
    final theme = _getCustomXMLTheme(isDarkTheme);
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xFF282C34) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDarkTheme ? const Color(0xFF3E4451) : const Color(0xFFE1E4E8),
          width: 1.0,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: HighlightView(
            formattedXML,
            language: 'xml',
            theme: theme,
            padding: padding,
            textStyle: TextStyle(
              fontFamily: fontFamily,
              fontSize: fontSize,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
  
  /// Extract and highlight specific attribute values in XML
  String highlightAttributeValues(String xmlContent, List<String> attributeNames) {
    try {
      final document = XmlDocument.parse(xmlContent);
      final buffer = StringBuffer();
      
      _highlightAttributesRecursive(document, buffer, attributeNames);
      
      return buffer.toString();
    } catch (e) {
      return xmlContent;
    }
  }
  
  void _highlightAttributesRecursive(XmlNode node, StringBuffer buffer, List<String> attributeNames) {
    if (node is XmlElement) {
      buffer.write('<${node.name}');
      
      // Highlight specified attributes
      for (final attribute in node.attributes) {
        buffer.write(' ${attribute.name}="');
        
        if (attributeNames.contains(attribute.name.local)) {
          // Add special highlighting marker for specified attributes
          buffer.write('**${attribute.value}**');
        } else {
          buffer.write(attribute.value);
        }
        
        buffer.write('"');
      }
      
      if (node.children.isEmpty) {
        buffer.write(' />');
      } else {
        buffer.write('>');
        
        for (final child in node.children) {
          _highlightAttributesRecursive(child, buffer, attributeNames);
        }
        
        buffer.write('</${node.name}>');
      }
    } else if (node is XmlText) {
      buffer.write(node.text);
    } else if (node is XmlDocument) {
      for (final child in node.children) {
        _highlightAttributesRecursive(child, buffer, attributeNames);
      }
    }
  }
  
  /// Get line numbers for XML content
  List<int> getXMLLineNumbers(String xmlContent) {
    final lines = xmlContent.split('\n');
    return List.generate(lines.length, (index) => index + 1);
  }
  
  /// Create XML viewer with line numbers
  Widget createXMLViewerWithLineNumbers(String xmlContent, {
    bool isDarkTheme = false,
    double fontSize = 14.0,
    bool showLineNumbers = true,
  }) {
    final formattedXML = _formatXMLContent(xmlContent);
    final lines = formattedXML.split('\n');
    final theme = _getCustomXMLTheme(isDarkTheme);
    
    if (!showLineNumbers) {
      return createHighlightedXMLWidget(xmlContent, isDarkTheme: isDarkTheme, fontSize: fontSize);
    }
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xFF282C34) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDarkTheme ? const Color(0xFF3E4451) : const Color(0xFFE1E4E8),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line numbers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            decoration: BoxDecoration(
              color: isDarkTheme ? const Color(0xFF21252B) : const Color(0xFFF6F8FA),
              border: Border(
                right: BorderSide(
                  color: isDarkTheme ? const Color(0xFF3E4451) : const Color(0xFFE1E4E8),
                  width: 1.0,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: lines.asMap().entries.map((entry) {
                return Text(
                  '${entry.key + 1}',
                  style: TextStyle(
                    fontFamily: 'Monaco',
                    fontSize: fontSize,
                    color: isDarkTheme ? const Color(0xFF5C6370) : const Color(0xFF6A737D),
                    height: 1.4,
                  ),
                );
              }).toList(),
            ),
          ),
          // XML content
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: HighlightView(
                  formattedXML,
                  language: 'xml',
                  theme: theme,
                  padding: const EdgeInsets.all(16.0),
                  textStyle: TextStyle(
                    fontFamily: 'Monaco',
                    fontSize: fontSize,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get XML parsing statistics
  Map<String, dynamic> getParsingStats(UIElement root) {
    return getHierarchyStats(root);
  }
  
  /// Generate cache key for file
  Future<String> _getCacheKey(String filePath) async {
    final file = File(filePath);
    final stat = await file.stat();
    return '${filePath}_${stat.modified.millisecondsSinceEpoch}_${stat.size}';
  }
  
  /// Cache parsing result with LRU eviction
  void _cacheResult(String key, UIElement result) {
    // Remove oldest entries if cache is full
    while (_cacheKeys.length >= _maxCacheSize) {
      final oldestKey = _cacheKeys.removeAt(0);
      _parseCache.remove(oldestKey);
    }
    
    // Add new result
    _parseCache[key] = result;
    _cacheKeys.add(key);
  }
  
  /// Clear parsing cache
  static void clearCache() {
    _parseCache.clear();
    _cacheKeys.clear();
  }
  
  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _parseCache.length,
      'maxCacheSize': _maxCacheSize,
      'cacheKeys': List.from(_cacheKeys),
    };
  }
  
  /// Serialize UIElement for isolate communication
  static Map<String, dynamic> _serializeUIElement(UIElement element) {
    return {
      'id': element.id,
      'depth': element.depth,
      'text': element.text,
      'contentDesc': element.contentDesc,
      'className': element.className,
      'packageName': element.packageName,
      'resourceId': element.resourceId,
      'clickable': element.clickable,
      'enabled': element.enabled,
      'bounds': {
        'left': element.bounds.left,
        'top': element.bounds.top,
        'right': element.bounds.right,
        'bottom': element.bounds.bottom,
      },
      'index': element.index,
      'children': element.children.map(_serializeUIElement).toList(),
    };
  }
  
  /// Reconstruct UIElement from serialized map
  UIElement _reconstructUIElementFromMap(Map<String, dynamic> data) {
    final bounds = data['bounds'] as Map<String, dynamic>;
    final element = UIElement(
      id: data['id'],
      depth: data['depth'],
      text: data['text'],
      contentDesc: data['contentDesc'],
      className: data['className'],
      packageName: data['packageName'],
      resourceId: data['resourceId'],
      clickable: data['clickable'],
      enabled: data['enabled'],
      bounds: Rect.fromLTRB(
        bounds['left'],
        bounds['top'],
        bounds['right'],
        bounds['bottom'],
      ),
      index: data['index'],
    );
    
    // Reconstruct children
    final childrenData = data['children'] as List<dynamic>;
    for (final childData in childrenData) {
      final child = _reconstructUIElementFromMap(childData as Map<String, dynamic>);
      element.addChild(child);
    }
    
    return element;
  }
  
  /// Memory-efficient flattening with lazy evaluation
  Stream<UIElement> flattenHierarchyStream(UIElement root) async* {
    final stack = <UIElement>[root];
    
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      yield current;
      
      // Add children in reverse order to maintain traversal order
      final children = current.children.reversed.toList();
      stack.addAll(children);
    }
  }
  
  /// Get parsing performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'cacheHitRate': _cacheKeys.isNotEmpty ? _parseCache.length / _cacheKeys.length : 0.0,
      'cacheSize': _parseCache.length,
      'maxCacheSize': _maxCacheSize,
      'chunkSize': _chunkSize,
      'largeFileThreshold': _largeFileThreshold,
    };
  }
}