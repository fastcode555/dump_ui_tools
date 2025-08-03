import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/ui_analyzer_state.dart';
import '../../models/ui_element.dart';

class PropertyPanel extends StatelessWidget {
  const PropertyPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
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
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Properties',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Consumer<UIAnalyzerState>(
              builder: (context, state, child) {
                final selectedElement = state.selectedElement;
                
                if (selectedElement == null) {
                  return _buildEmptyState(context);
                }
                
                return _buildPropertiesView(context, selectedElement);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.list_alt,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No element selected',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select an element to view properties',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesView(BuildContext context, UIElement element) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Element identification section
          _buildPropertyGroup(
            context,
            'Element Identification',
            Icons.fingerprint,
            [
              _PropertyItem('ID', element.id),
              _PropertyItem('Class', element.className),
              _PropertyItem('Package', element.packageName),
              _PropertyItem('Resource ID', element.resourceId),
              _PropertyItem('Index', element.index.toString()),
              _PropertyItem('Depth', element.depth.toString()),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Content section
          _buildPropertyGroup(
            context,
            'Content',
            Icons.text_fields,
            [
              _PropertyItem('Text', element.text),
              _PropertyItem('Content Description', element.contentDesc),
              _PropertyItem('Display Text', element.displayText),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // State section
          _buildPropertyGroup(
            context,
            'State',
            Icons.toggle_on,
            [
              _PropertyItem('Clickable', element.clickable ? 'true' : 'false'),
              _PropertyItem('Enabled', element.enabled ? 'true' : 'false'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Layout section
          _buildPropertyGroup(
            context,
            'Layout & Position',
            Icons.crop_free,
            [
              _PropertyItem('Bounds', element.boundsString),
              _BoundsPropertyItem('Coordinates & Size', element.bounds),
              _PropertyItem('Width', '${element.width.toInt()}px'),
              _PropertyItem('Height', '${element.height.toInt()}px'),
              _PropertyItem('Center', '(${element.center.dx.toInt()}, ${element.center.dy.toInt()})'),
              _PropertyItem('Left', element.bounds.left.toInt().toString()),
              _PropertyItem('Top', element.bounds.top.toInt().toString()),
              _PropertyItem('Right', element.bounds.right.toInt().toString()),
              _PropertyItem('Bottom', element.bounds.bottom.toInt().toString()),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Hierarchy section
          _buildPropertyGroup(
            context,
            'Hierarchy',
            Icons.account_tree,
            [
              _PropertyItem('Has Children', element.hasChildren ? 'true' : 'false'),
              _PropertyItem('Child Count', element.childCount.toString()),
              _PropertyItem('Has Parent', (element.parent != null) ? 'true' : 'false'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyGroup(
    BuildContext context,
    String title,
    IconData icon,
    List<_PropertyItem> properties,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Properties list
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          child: Column(
            children: properties
                .where((prop) => _shouldShowProperty(prop)) // Only show non-empty properties
                .map((prop) => _buildPropertyRow(context, prop))
                .toList(),
          ),
        ),
      ],
    );
  }

  bool _shouldShowProperty(_PropertyItem property) {
    if (property is _BoundsPropertyItem) {
      return true; // Always show bounds property
    }
    return property.value.isNotEmpty;
  }

  Widget _buildPropertyRow(BuildContext context, _PropertyItem property) {
    if (property is _BoundsPropertyItem) {
      return _buildBoundsPropertyRow(context, property);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property name
          SizedBox(
            width: 120,
            child: Text(
              property.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Property value
          Expanded(
            child: GestureDetector(
              onTap: () => _copyToClipboard(context, property.value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.5),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        property.value,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                        softWrap: true,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.copy,
                      size: 14,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoundsPropertyRow(BuildContext context, _BoundsPropertyItem property) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property name
          Text(
            property.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Bounds details in a grid
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                // Top row: Left, Top, Right, Bottom
                Row(
                  children: [
                    Expanded(child: _buildBoundsDetail(context, 'Left', property.bounds.left.toInt().toString())),
                    const SizedBox(width: 8),
                    Expanded(child: _buildBoundsDetail(context, 'Top', property.bounds.top.toInt().toString())),
                    const SizedBox(width: 8),
                    Expanded(child: _buildBoundsDetail(context, 'Right', property.bounds.right.toInt().toString())),
                    const SizedBox(width: 8),
                    Expanded(child: _buildBoundsDetail(context, 'Bottom', property.bounds.bottom.toInt().toString())),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Bottom row: Width, Height
                Row(
                  children: [
                    Expanded(child: _buildBoundsDetail(context, 'Width', '${property.bounds.width.toInt()}px')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildBoundsDetail(context, 'Height', '${property.bounds.height.toInt()}px')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildBoundsDetail(context, 'Center X', property.bounds.center.dx.toInt().toString())),
                    const SizedBox(width: 8),
                    Expanded(child: _buildBoundsDetail(context, 'Center Y', property.bounds.center.dy.toInt().toString())),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Copy button for full bounds string
                GestureDetector(
                  onTap: () => _copyToClipboard(context, property.boundsString),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.copy,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Copy bounds: ${property.boundsString}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoundsDetail(BuildContext context, String label, String value) {
    return GestureDetector(
      onTap: () => _copyToClipboard(context, value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String value) {
    if (value.isEmpty) return;
    
    Clipboard.setData(ClipboardData(text: value));
    
    // Create a more informative message
    String message;
    if (value.length <= 50) {
      message = 'Copied: $value';
    } else {
      message = 'Copied: ${value.substring(0, 47)}...';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
      ),
    );
  }
}

class _PropertyItem {
  final String name;
  final String value;

  const _PropertyItem(this.name, this.value);
}

class _BoundsPropertyItem extends _PropertyItem {
  final Rect bounds;

  const _BoundsPropertyItem(String name, this.bounds) : super(name, '');

  String get boundsString {
    return '[${bounds.left.toInt()},${bounds.top.toInt()}][${bounds.right.toInt()},${bounds.bottom.toInt()}]';
  }
}