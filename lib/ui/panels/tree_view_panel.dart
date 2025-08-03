import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/ui_analyzer_state.dart';
import '../../models/ui_element.dart';
import '../../models/filter_criteria.dart';
import '../widgets/virtual_tree_view.dart';

/// Tree view panel that displays UI hierarchy with search and filter functionality
class TreeViewPanel extends StatefulWidget {
  const TreeViewPanel({super.key});

  @override
  State<TreeViewPanel> createState() => _TreeViewPanelState();
}

class _TreeViewPanelState extends State<TreeViewPanel> {
  final ScrollController _scrollController = ScrollController();
  final Set<String> _expandedElements = <String>{};
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UIAnalyzerState>(
      builder: (context, state, child) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context, state),
              if (state.hasUIHierarchy) ...[
                _buildSearchBar(context, state),
                _buildFilterChips(context, state),
              ],
              _buildTreeContent(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, UIAnalyzerState state) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            Icons.account_tree,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'UI Hierarchy',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (state.hasUIHierarchy) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.filteredElementCount}/${state.totalElementCount}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, UIAnalyzerState state) {
    return SearchBarWidget(
      onSearchChanged: (query) {
        state.setSearchQuery(query);
      },
    );
  }

  Widget _buildFilterChips(BuildContext context, UIAnalyzerState state) {
    return FilterChipsWidget(
      onFilterChanged: (criteria) {
        state.setFilterCriteria(criteria);
      },
    );
  }

  Widget _buildTreeContent(BuildContext context, UIAnalyzerState state) {
    if (!state.hasUIHierarchy) {
      return _buildEmptyState(context);
    }

    if (state.isLoading) {
      return _buildLoadingState(context, state);
    }

    return _buildTreeView(context, state);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.device_hub,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No UI hierarchy loaded',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect a device and capture UI',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, UIAnalyzerState state) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              state.loadingMessage.isNotEmpty ? state.loadingMessage : 'Loading...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeView(BuildContext context, UIAnalyzerState state) {
    final displayElements = state.getDisplayElements();
    
    if (displayElements.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_list_off,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No elements match current filters',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  state.setFilterCriteria(FilterCriteria.empty);
                  state.setSearchQuery('');
                },
                child: const Text('Clear filters'),
              ),
            ],
          ),
        ),
      );
    }

    // Use virtual scrolling for better performance with large hierarchies
    return Expanded(
      child: VirtualTreeView(
        root: state.rootElement,
        selectedElement: state.selectedElement,
        expandedElements: _expandedElements,
        onElementSelected: (element) => state.selectElement(element),
        onElementExpanded: (element) => _handleElementExpansion(element),
        onElementCollapsed: (element) => _handleElementExpansion(element),
        itemHeight: 48.0,
        padding: const EdgeInsets.all(8),
        showRoot: true,
      ),
    );
  }

  List<Widget> _buildTreeTiles(UIElement? element, UIAnalyzerState state, int depth) {
    if (element == null) return [];
    
    final tiles = <Widget>[];
    final isSelected = state.selectedElement == element;
    final isHighlighted = state.isElementInSearchResults(element);
    final isExpanded = _shouldExpandNode(element, state);
    
    // Add the current element tile
    tiles.add(
      UIElementTile(
        key: ValueKey(element.id),
        element: element,
        isSelected: isSelected,
        isHighlighted: isHighlighted,
        isExpanded: isExpanded,
        depth: depth,
        onTap: () => state.selectElement(element),
        onExpandToggle: () => _handleElementExpansion(element),
      ),
    );
    
    // Add children if expanded
    if (isExpanded) {
      for (final child in element.children) {
        tiles.addAll(_buildTreeTiles(child, state, depth + 1));
      }
    }
    
    return tiles;
  }

  bool _shouldExpandNode(UIElement element, UIAnalyzerState state) {
    // Check manual expansion state first
    if (_expandedElements.contains(element.id)) {
      return true;
    }
    
    // Expand if element is in search results path
    if (state.hasSearchResults) {
      final searchResults = state.searchResults;
      for (final result in searchResults) {
        final path = result.getPathFromRoot();
        if (path.contains(element) && element != result) {
          return true;
        }
      }
    }
    
    // Expand if element is in selected element path
    if (state.hasSelectedElement) {
      final selectedPath = state.getSelectedElementPath();
      if (selectedPath.contains(element) && element != state.selectedElement) {
        return true;
      }
    }
    
    return false;
  }

  void _handleElementExpansion(UIElement element) {
    setState(() {
      if (_expandedElements.contains(element.id)) {
        _expandedElements.remove(element.id);
      } else {
        _expandedElements.add(element.id);
      }
    });
  }
}

/// Search bar widget with debounced search functionality
class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;

  const SearchBarWidget({
    super.key,
    required this.onSearchChanged,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UIAnalyzerState>(
      builder: (context, state, child) {
        // Listen for focus search requests
        if (state.shouldFocusSearch) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _focusNode.requestFocus();
          });
        }
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search UI elements... (Cmd+F)',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _textController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: _clearSearch,
                            tooltip: 'Clear search (Esc)',
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  onChanged: _onSearchChanged,
                  onSubmitted: (value) {
                    // Navigate to first search result on Enter
                    if (state.hasSearchResults) {
                      state.selectElement(state.searchResults.first);
                    }
                  },
                ),
              ),
          const SizedBox(width: 8),
          Consumer<UIAnalyzerState>(
            builder: (context, state, child) {
              if (!state.hasSearchResults && state.searchQuery.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: state.hasSearchResults 
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  state.hasSearchResults 
                      ? '${state.searchResults.length} found'
                      : 'No results',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: state.hasSearchResults
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
      },
    );
  }
  
  /// Focus the search field (called from keyboard shortcuts)
  void focusSearch() {
    _focusNode.requestFocus();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      widget.onSearchChanged(value);
    });
  }

  void _clearSearch() {
    _textController.clear();
    setState(() {});
    widget.onSearchChanged('');
  }
}

/// Filter chips widget for displaying and managing filter options
class FilterChipsWidget extends StatelessWidget {
  final ValueChanged<FilterCriteria> onFilterChanged;

  const FilterChipsWidget({
    super.key,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UIAnalyzerState>(
      builder: (context, state, child) {
        final criteria = state.filterCriteria;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Filters:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (criteria.hasActiveFilters)
                    TextButton(
                      onPressed: () {
                        onFilterChanged(FilterCriteria.empty);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Clear all',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildFilterChip(
                    context,
                    label: 'Clickable',
                    icon: Icons.touch_app,
                    isActive: criteria.showOnlyClickable,
                    count: _getClickableCount(state),
                    onTap: () {
                      final newCriteria = criteria.copyWithClickableFilter(!criteria.showOnlyClickable);
                      onFilterChanged(newCriteria);
                    },
                  ),
                  _buildFilterChip(
                    context,
                    label: 'Input',
                    icon: Icons.text_fields,
                    isActive: criteria.showOnlyInputs,
                    count: _getInputCount(state),
                    onTap: () {
                      final newCriteria = criteria.copyWithInputFilter(!criteria.showOnlyInputs);
                      onFilterChanged(newCriteria);
                    },
                  ),
                  _buildFilterChip(
                    context,
                    label: 'With Text',
                    icon: Icons.text_format,
                    isActive: criteria.showOnlyWithText,
                    count: _getTextCount(state),
                    onTap: () {
                      final newCriteria = criteria.copyWithTextFilter(!criteria.showOnlyWithText);
                      onFilterChanged(newCriteria);
                    },
                  ),
                  _buildFilterChip(
                    context,
                    label: 'Enabled',
                    icon: Icons.check_circle,
                    isActive: criteria.enabledOnly,
                    count: _getEnabledCount(state),
                    onTap: () {
                      final newCriteria = criteria.copyWith(enabledOnly: !criteria.enabledOnly);
                      onFilterChanged(newCriteria);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isActive,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isActive
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isActive
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _getClickableCount(UIAnalyzerState state) {
    return state.flatElements.where((e) => e.clickable).length;
  }

  int _getInputCount(UIAnalyzerState state) {
    return state.flatElements.where((e) => 
        e.className.contains('EditText') || 
        e.className.contains('TextInputLayout')).length;
  }

  int _getTextCount(UIAnalyzerState state) {
    return state.flatElements.where((e) => 
        e.text.isNotEmpty || e.contentDesc.isNotEmpty).length;
  }

  int _getEnabledCount(UIAnalyzerState state) {
    return state.flatElements.where((e) => e.enabled).length;
  }
}

/// Custom UI element tile for displaying individual UI elements in the tree
class UIElementTile extends StatefulWidget {
  final UIElement element;
  final bool isSelected;
  final bool isHighlighted;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onExpandToggle;
  final int depth;

  const UIElementTile({
    super.key,
    required this.element,
    this.isSelected = false,
    this.isHighlighted = false,
    this.isExpanded = false,
    this.onTap,
    this.onExpandToggle,
    this.depth = 0,
  });

  @override
  State<UIElementTile> createState() => _UIElementTileState();
}

class _UIElementTileState extends State<UIElementTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: EdgeInsets.only(left: widget.depth * 16.0),
          decoration: BoxDecoration(
            color: _getBackgroundColor(context),
            borderRadius: BorderRadius.circular(4),
            border: widget.isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _buildExpanderIcon(context),
                const SizedBox(width: 4),
                _buildElementIcon(context),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildElementInfo(context),
                ),
                _buildElementBadges(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    if (widget.isSelected) {
      return Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3);
    } else if (widget.isHighlighted) {
      return Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3);
    } else if (_isHovered) {
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    } else {
      return Colors.transparent;
    }
  }

  Widget _buildExpanderIcon(BuildContext context) {
    if (!widget.element.hasChildren) {
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

  Widget _buildElementIcon(BuildContext context) {
    return Icon(
      _getElementIcon(),
      size: 16,
      color: _getElementIconColor(context),
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

  Color _getElementIconColor(BuildContext context) {
    if (widget.element.clickable) {
      return Theme.of(context).colorScheme.primary;
    } else if (!widget.element.enabled) {
      return Theme.of(context).colorScheme.outline;
    } else {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  Widget _buildElementInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPrimaryText(context),
        if (_shouldShowSecondaryInfo()) ...[
          const SizedBox(height: 2),
          _buildSecondaryText(context),
        ],
      ],
    );
  }

  Widget _buildPrimaryText(BuildContext context) {
    String primaryText = widget.element.displayText;
    if (primaryText.isEmpty) {
      primaryText = widget.element.className.split('.').last;
    }

    return Text(
      primaryText,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
        color: widget.isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurface,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  bool _shouldShowSecondaryInfo() {
    return widget.element.resourceId.isNotEmpty || 
           widget.element.bounds != Rect.zero ||
           widget.element.className.isNotEmpty;
  }

  Widget _buildSecondaryText(BuildContext context) {
    final parts = <String>[];
    
    if (widget.element.resourceId.isNotEmpty) {
      final resourceId = widget.element.resourceId.split('/').last;
      parts.add('id: $resourceId');
    }
    
    if (widget.element.bounds != Rect.zero) {
      parts.add('${widget.element.width.toInt()}×${widget.element.height.toInt()}');
    }
    
    final className = widget.element.className.split('.').last;
    if (className.isNotEmpty && className != widget.element.displayText) {
      parts.add(className);
    }

    return Text(
      parts.join(' • '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildElementBadges(BuildContext context) {
    final badges = <Widget>[];

    if (widget.element.clickable) {
      badges.add(_buildBadge(
        context,
        'C',
        'Clickable',
        Theme.of(context).colorScheme.primary,
      ));
    }

    if (!widget.element.enabled) {
      badges.add(_buildBadge(
        context,
        'D',
        'Disabled',
        Theme.of(context).colorScheme.error,
      ));
    }

    if (widget.element.className.contains('EditText')) {
      badges.add(_buildBadge(
        context,
        'I',
        'Input',
        Theme.of(context).colorScheme.secondary,
      ));
    }

    if (widget.element.hasChildren) {
      badges.add(_buildBadge(
        context,
        widget.element.childCount.toString(),
        '${widget.element.childCount} children',
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

  Widget _buildBadge(BuildContext context, String text, String tooltip, Color color) {
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