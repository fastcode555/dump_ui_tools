import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:provider/provider.dart';
import '../../controllers/ui_analyzer_state.dart';

class XMLViewerPanel extends StatefulWidget {
  final VoidCallback? onClose;
  
  const XMLViewerPanel({
    super.key,
    this.onClose,
  });

  @override
  State<XMLViewerPanel> createState() => _XMLViewerPanelState();
}

class _XMLViewerPanelState extends State<XMLViewerPanel> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  double _zoomLevel = 1.0;
  static const double _minZoom = 0.5;
  static const double _maxZoom = 3.0;
  static const double _zoomStep = 0.1;
  bool _showLineNumbers = true;
  bool _wordWrap = false;
  
  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  // Custom XML highlighting theme that emphasizes attribute values
  Map<String, TextStyle> _getCustomXMLTheme(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    if (isDarkMode) {
      return {
        'root': TextStyle(
          backgroundColor: colorScheme.surface,
          color: colorScheme.onSurface,
        ),
        'tag': TextStyle(
          color: const Color(0xFF7C3AED), // Purple for tags
          fontWeight: FontWeight.w500,
        ),
        'name': TextStyle(
          color: const Color(0xFF7C3AED), // Purple for tag names
          fontWeight: FontWeight.w500,
        ),
        'attr': TextStyle(
          color: const Color(0xFF0EA5E9), // Blue for attribute names
        ),
        'string': TextStyle(
          color: const Color(0xFF10B981), // Green for attribute values - emphasized
          fontWeight: FontWeight.w600,
          backgroundColor: const Color(0xFF064E3B).withOpacity(0.3),
        ),
        'comment': TextStyle(
          color: const Color(0xFF6B7280),
          fontStyle: FontStyle.italic,
        ),
        'keyword': TextStyle(
          color: const Color(0xFFEC4899),
          fontWeight: FontWeight.w500,
        ),
        'built_in': TextStyle(
          color: const Color(0xFFF59E0B),
        ),
      };
    } else {
      return {
        'root': TextStyle(
          backgroundColor: colorScheme.surface,
          color: colorScheme.onSurface,
        ),
        'tag': TextStyle(
          color: const Color(0xFF7C2D12), // Brown for tags
          fontWeight: FontWeight.w500,
        ),
        'name': TextStyle(
          color: const Color(0xFF7C2D12), // Brown for tag names
          fontWeight: FontWeight.w500,
        ),
        'attr': TextStyle(
          color: const Color(0xFF1E40AF), // Blue for attribute names
        ),
        'string': TextStyle(
          color: const Color(0xFF059669), // Green for attribute values - emphasized
          fontWeight: FontWeight.w600,
          backgroundColor: const Color(0xFFD1FAE5).withOpacity(0.5),
        ),
        'comment': TextStyle(
          color: const Color(0xFF6B7280),
          fontStyle: FontStyle.italic,
        ),
        'keyword': TextStyle(
          color: const Color(0xFFDB2777),
          fontWeight: FontWeight.w500,
        ),
        'built_in': TextStyle(
          color: const Color(0xFFD97706),
        ),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header with controls
          _buildHeader(context),
          
          // XML content area
          Expanded(
            child: Consumer<UIAnalyzerState>(
              builder: (context, state, child) {
                if (!state.hasXmlContent) {
                  return _buildEmptyState(context);
                }
                
                return _buildXMLContent(context, state.xmlContent);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.code,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'XML Source',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          
          // View options
          _buildViewOptions(context),
          
          const SizedBox(width: 8),
          
          // Zoom controls
          _buildZoomControls(context),
          
          const SizedBox(width: 8),
          
          // Copy button
          Consumer<UIAnalyzerState>(
            builder: (context, state, child) {
              return IconButton(
                onPressed: state.hasXmlContent ? () => _copyXMLContent(context, state.xmlContent) : null,
                icon: const Icon(Icons.copy),
                iconSize: 20,
                tooltip: 'Copy XML content',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              );
            },
          ),
          
          const SizedBox(width: 4),
          
          // Close button
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close),
            iconSize: 20,
            tooltip: 'Close XML viewer',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewOptions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _showLineNumbers = !_showLineNumbers;
            });
          },
          icon: Icon(_showLineNumbers ? Icons.format_list_numbered : Icons.format_list_numbered_outlined),
          iconSize: 18,
          tooltip: _showLineNumbers ? 'Hide line numbers' : 'Show line numbers',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _wordWrap = !_wordWrap;
            });
          },
          icon: Icon(_wordWrap ? Icons.wrap_text : Icons.wrap_text_outlined),
          iconSize: 18,
          tooltip: _wordWrap ? 'Disable word wrap' : 'Enable word wrap',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildZoomControls(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _zoomLevel > _minZoom ? _zoomOut : null,
          icon: const Icon(Icons.zoom_out),
          iconSize: 18,
          tooltip: 'Zoom out',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${(_zoomLevel * 100).round()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        IconButton(
          onPressed: _zoomLevel < _maxZoom ? _zoomIn : null,
          icon: const Icon(Icons.zoom_in),
          iconSize: 18,
          tooltip: 'Zoom in',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No XML content available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Capture UI to view XML source',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXMLContent(BuildContext context, String xmlContent) {
    final lines = xmlContent.split('\n');
    final customTheme = _getCustomXMLTheme(context);
    
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Transform.scale(
        scale: _zoomLevel,
        alignment: Alignment.topLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line numbers
            if (_showLineNumbers) _buildLineNumbers(context, lines.length),
            
            // XML content with syntax highlighting
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.vertical,
                child: _wordWrap 
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      child: _buildSelectableHighlightView(xmlContent, customTheme),
                    )
                  : SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: _buildSelectableHighlightView(xmlContent, customTheme),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineNumbers(BuildContext context, int lineCount) {
    final lineNumberWidth = (lineCount.toString().length * 8.0 + 16).clamp(40.0, 80.0);
    
    return Container(
      width: lineNumberWidth,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(lineCount, (index) {
              return Container(
                height: 13 * 1.4, // Match text line height
                alignment: Alignment.centerRight,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: 'Monaco, Consolas, monospace',
                    fontSize: 13,
                    height: 1.4,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableHighlightView(String xmlContent, Map<String, TextStyle> customTheme) {
    return SelectionArea(
      child: HighlightView(
        xmlContent,
        language: 'xml',
        theme: customTheme,
        padding: EdgeInsets.zero,
        textStyle: TextStyle(
          fontFamily: 'Monaco, Consolas, monospace',
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel + _zoomStep).clamp(_minZoom, _maxZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel - _zoomStep).clamp(_minZoom, _maxZoom);
    });
  }

  void _copyXMLContent(BuildContext context, String xmlContent) {
    Clipboard.setData(ClipboardData(text: xmlContent));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('XML content copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}