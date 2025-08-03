import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/ui_element.dart';

/// Virtual scrolling tree view for handling large UI hierarchies efficiently
class VirtualTreeView extends StatefulWidget {
  final UIElement? root;
  final UIElement? selectedElement;
  final Set<String> expandedElements;
  final ValueChanged<UIElement>? onElementSelected;
  final ValueChanged<UIElement>? onElementExpanded;
  final ValueChanged<UIElement>? onElementCollapsed;
  final double itemHeight;
  final EdgeInsets padding;
  final bool showRoot;

  const VirtualTreeView({
    super.key,
    this.root,
    this.selectedElement,
    this.expandedElements = const {},
    this.onElementSelected,
    this.onElementExpanded,
    this.onElementCollapsed,
    this.itemHeight = 48.0,
    this.padding = const EdgeInsets.all(8.0),
    this.showRoot = true,
  });

  @override
  State<VirtualTreeView> createState() => _VirtualTreeViewState();
}

class _VirtualTreeViewState extends State<VirtualTreeView> {
  final ScrollController _scrollController = ScrollController();
  List<_TreeViewItem> _flattenedItems = [];
  int _visibleStartIndex = 0;
  int _visibleEndIndex = 0;
  double _viewportHeight = 0;
  
  // Performance optimization: cache for built widgets
  final Map<String, Widget> _widgetCache = {};
  int _cacheVersion = 0;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _rebuildFlattenedItems();
  }

  @override
  void didUpdateWidget(VirtualTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.root != widget.root ||
        oldWidget.expandedElements != widget.expandedElements ||
        oldWidget.selectedElement != widget.selectedElement) {
      _rebuildFlattenedItems();
      
      // Clear cache when structure changes
      if (oldWidget.root != widget.root ||
          oldWidget.expandedElements != widget.expandedElements) {
        _clearWidgetCache();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _clearWidgetCache();
    super.dispose();
  }
  
  void _clearWidgetCache() {
    _widgetCache.clear();
    _cacheVersion++;
  }

  void _onScroll() {
    _updateVisibleRange();
  }

  void _updateVisibleRange() {
    if (_viewportHeight == 0 || _flattenedItems.isEmpty) return;

    final scrollOffset = _scrollController.offset;
    final startIndex = math.max(0, (scrollOffset / widget.itemHeight).floor() - 5);
    final endIndex = math.min(
      _flattenedItems.length - 1,
      ((scrollOffset + _viewportHeight) / widget.itemHeight).ceil() + 5,
    );

    if (startIndex != _visibleStartIndex || endIndex != _visibleEndIndex) {
      setState(() {
        _visibleStartIndex = startIndex;
        _visibleEndIndex = endIndex;
      });
    }
  }

  void _rebuildFlattenedItems() {
    _flattenedItems.clear();
    
    if (widget.root != null) {
      if (widget.showRoot) {
        _addElementToFlatList(widget.root!, 0);
      } else {
        // Start with root's children
        for (final child in widget.root!.children) {
          _addElementToFlatList(child, 0);
        }
      }
    }
    
    _updateVisibleRange();
  }

  void _addElementToFlatList(UIElement element, int depth) {
    _flattenedItems.add(_TreeViewItem(
      element: element,
      depth: depth,
      isExpanded: widget.expandedElements.contains(element.id),
    ));

    // Add children if expanded
    if (widget.expandedElements.contains(element.id)) {
      for (final child in element.children) {
        _addElementToFlatList(child, depth + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportHeight = constraints.maxHeight;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateVisibleRange();
        });

        return _buildVirtualScrollView();
      },
    );
  }

  Widget _buildVirtualScrollView() {
    if (_flattenedItems.isEmpty) {
      return _buildEmptyState();
    }

    final totalHeight = _flattenedItems.length * widget.itemHeight;

    return Scrollbar(
      controller: _scrollController,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: widget.padding,
            sliver: SliverFixedExtentList(
              itemExtent: widget.itemHeight,
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < _visibleStartIndex || index > _visibleEndIndex) {
                    return const SizedBox.shrink();
                  }

                  final item = _flattenedItems[index];
                  return _buildTreeItem(item, index);
                },
                childCount: _flattenedItems.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No UI hierarchy available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeItem(_TreeViewItem item, int index) {
    final isSelected = widget.selectedElement == item.element;
    final hasChildren = item.element.children.isNotEmpty;
    
    // Create cache key based on element state
    final cacheKey = '${item.element.id}_${isSelected}_${item.isExpanded}_$_cacheVersion';
    
    // Return cached widget if available and state hasn't changed
    if (_widgetCache.containsKey(cacheKey)) {
      return _widgetCache[cacheKey]!;
    }

    final tileWidget = VirtualTreeTile(
      key: ValueKey('${item.element.id}_$index'),
      element: item.element,
      depth: item.depth,
      isSelected: isSelected,
      isExpanded: item.isExpanded,
      hasChildren: hasChildren,
      onTap: () => widget.onElementSelected?.call(item.element),
      onExpandToggle: hasChildren ? () => _handleExpandToggle(item.element) : null,
    );
    
    // Cache the widget for reuse
    _widgetCache[cacheKey] = tileWidget;
    
    // Limit cache size to prevent memory issues
    if (_widgetCache.length > 100) {
      final keysToRemove = _widgetCache.keys.take(_widgetCache.length - 100).toList();
      for (final key in keysToRemove) {
        _widgetCache.remove(key);
      }
    }
    
    return tileWidget;
  }

  void _handleExpandToggle(UIElement element) {
    if (widget.expandedElements.contains(element.id)) {
      widget.onElementCollapsed?.call(element);
    } else {
      widget.onElementExpanded?.call(element);
    }
  }
}

/// Data class for flattened tree items
class _TreeViewItem {
  final UIElement element;
  final int depth;
  final bool isExpanded;

  const _TreeViewItem({
    required this.element,
    required this.depth,
    required this.isExpanded,
  });
}

/// Optimized tree tile widget for virtual scrolling
class VirtualTreeTile extends StatefulWidget {
  final UIElement element;
  final int depth;
  final bool isSelected;
  final bool isExpanded;
  final bool hasChildren;
  final VoidCallback? onTap;
  final VoidCallback? onExpandToggle;

  const VirtualTreeTile({
    super.key,
    required this.element,
    required this.depth,
    this.isSelected = false,
    this.isExpanded = false,
    this.hasChildren = false,
    this.onTap,
    this.onExpandToggle,
  });

  @override
  State<VirtualTreeTile> createState() => _VirtualTreeTileState();
}

class _VirtualTreeTileState extends State<VirtualTreeTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.only(
            left: widget.depth * 16.0 + 8.0,
            right: 8.0,
            top: 4.0,
            bottom: 4.0,
          ),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(4),
            border: widget.isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Row(
            children: [
              _buildExpanderIcon(),
              const SizedBox(width: 4),
              _buildElementIcon(),
              const SizedBox(width: 8),
              Expanded(child: _buildElementInfo()),
              _buildElementBadges(),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (widget.isSelected) {
      return Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3);
    } else if (_isHovered) {
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    } else {
      return Colors.transparent;
    }
  }

  Widget _buildExpanderIcon() {
    if (!widget.hasChildren) {
      return const SizedBox(width: 16);
    }

    return GestureDetector(
      onTap: widget.onExpandToggle,
      child: Container(
        width: 16,
        height: 16,
        alignment: Alignment.center,
        child: Icon(
          widget.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildElementIcon() {
    return Icon(
      _getElementIcon(),
      size: 16,
      color: _getElementIconColor(),
    );
  }

  IconData _getElementIcon() {
    final className = widget.element.className.toLowerCase();
    
    if (className.contains('button')) {
      return Icons.smart_button;
    } else if (className.contains('edittext') || className.contains('textinput')) {
      return Icons.text_fields;
    } else if (className.contains('textview') || className.contains('text')) {
      return Icons.text_format;
    } else if (className.contains('image')) {
      return Icons.image;
    } else if (className.contains('recyclerview') || className.contains('listview')) {
      return Icons.list;
    } else if (className.contains('scrollview')) {
      return Icons.view_stream;
    } else if (className.contains('layout')) {
      return Icons.view_compact;
    } else if (widget.element.clickable) {
      return Icons.touch_app;
    } else {
      return Icons.widgets;
    }
  }

  Color _getElementIconColor() {
    if (widget.element.clickable) {
      return Theme.of(context).colorScheme.primary;
    } else if (!widget.element.enabled) {
      return Theme.of(context).colorScheme.outline;
    } else {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  Widget _buildElementInfo() {
    String primaryText = widget.element.displayText;
    if (primaryText.isEmpty) {
      primaryText = widget.element.className.split('.').last;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          primaryText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
            color: widget.isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (_shouldShowSecondaryInfo()) ...[
          const SizedBox(height: 2),
          Text(
            _getSecondaryText(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  bool _shouldShowSecondaryInfo() {
    return widget.element.resourceId.isNotEmpty || 
           widget.element.bounds != Rect.zero;
  }

  String _getSecondaryText() {
    final parts = <String>[];
    
    if (widget.element.resourceId.isNotEmpty) {
      final resourceId = widget.element.resourceId.split('/').last;
      parts.add('id: $resourceId');
    }
    
    if (widget.element.bounds != Rect.zero) {
      parts.add('${widget.element.width.toInt()}×${widget.element.height.toInt()}');
    }

    return parts.join(' • ');
  }

  Widget _buildElementBadges() {
    final badges = <Widget>[];

    if (widget.element.clickable) {
      badges.add(_buildBadge('C', 'Clickable', Theme.of(context).colorScheme.primary));
    }

    if (!widget.element.enabled) {
      badges.add(_buildBadge('D', 'Disabled', Theme.of(context).colorScheme.error));
    }

    if (widget.element.className.contains('EditText')) {
      badges.add(_buildBadge('I', 'Input', Theme.of(context).colorScheme.secondary));
    }

    if (widget.hasChildren) {
      badges.add(_buildBadge(
        widget.element.children.length.toString(),
        '${widget.element.children.length} children',
        Theme.of(context).colorScheme.tertiary,
      ));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: badges.map((badge) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: badge,
      )).toList(),
    );
  }

  Widget _buildBadge(String text, String tooltip, Color color) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}