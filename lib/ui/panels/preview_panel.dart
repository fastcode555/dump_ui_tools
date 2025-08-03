import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/ui_analyzer_state.dart';
import '../../models/ui_element.dart';

class PreviewPanel extends StatefulWidget {
  const PreviewPanel({super.key});

  @override
  State<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<PreviewPanel> {
  // Transform controller for pan and zoom
  final TransformationController _transformationController = TransformationController();
  
  // Default device dimensions (can be updated based on actual device)
  static const double _defaultDeviceWidth = 1080.0;
  static const double _defaultDeviceHeight = 1920.0;
  
  // Hover state for element highlighting
  UIElement? _hoveredElement;
  Offset _mousePosition = Offset.zero;
  
  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        children: [
          // Header with controls
          _buildHeader(context),
          
          // Preview content
          Expanded(
            child: Consumer<UIAnalyzerState>(
              builder: (context, state, child) {
                if (!state.hasUIHierarchy) {
                  return _buildEmptyState(context);
                }
                
                return _buildPreviewContent(context, state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            Icons.preview,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Screen Preview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          
          // Zoom controls
          Consumer<UIAnalyzerState>(
            builder: (context, state, child) {
              if (!state.hasUIHierarchy) return const SizedBox.shrink();
              
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _zoomOut,
                    icon: const Icon(Icons.zoom_out),
                    tooltip: 'Zoom Out',
                    iconSize: 18,
                  ),
                  IconButton(
                    onPressed: _resetZoom,
                    icon: const Icon(Icons.center_focus_strong),
                    tooltip: 'Reset Zoom',
                    iconSize: 18,
                  ),
                  IconButton(
                    onPressed: _zoomIn,
                    icon: const Icon(Icons.zoom_in),
                    tooltip: 'Zoom In',
                    iconSize: 18,
                  ),
                ],
              );
            },
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
            Icons.phone_android,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No screen preview available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Capture UI to see screen layout',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(BuildContext context, UIAnalyzerState state) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.1,
        maxScale: 5.0,
        constrained: false,
        child: Center(
          child: _buildDeviceCanvas(context, state),
        ),
      ),
    );
  }

  Widget _buildDeviceCanvas(BuildContext context, UIAnalyzerState state) {
    final rootElement = state.rootElement;
    if (rootElement == null) return const SizedBox.shrink();

    // Calculate device dimensions from root element bounds
    final deviceBounds = rootElement.bounds;
    final deviceWidth = deviceBounds.width > 0 ? deviceBounds.width : _defaultDeviceWidth;
    final deviceHeight = deviceBounds.height > 0 ? deviceBounds.height : _defaultDeviceHeight;

    // Calculate scale to fit the available space with some padding
    final availableSize = MediaQuery.of(context).size;
    final maxWidth = availableSize.width * 0.8; // 80% of available width
    final maxHeight = availableSize.height * 0.8; // 80% of available height
    
    final scaleX = maxWidth / deviceWidth;
    final scaleY = maxHeight / deviceHeight;
    final scale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.1, 2.0);

    final scaledWidth = deviceWidth * scale;
    final scaledHeight = deviceHeight * scale;

    return Container(
      width: scaledWidth,
      height: scaledHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CustomPaint(
          size: Size(scaledWidth, scaledHeight),
          painter: UIElementsPainter(
            elements: state.flatElements,
            selectedElement: state.selectedElement,
            hoveredElement: _hoveredElement,
            deviceBounds: deviceBounds,
            scale: scale,
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: Stack(
            children: [
              MouseRegion(
                onHover: (event) => _handleMouseHover(event, state, scale, deviceBounds),
                onExit: (_) => _handleMouseExit(),
                child: GestureDetector(
                  onTapDown: (details) => _handleTapDown(details, state, scale, deviceBounds),
                  child: Container(
                    width: scaledWidth,
                    height: scaledHeight,
                    color: Colors.transparent,
                  ),
                ),
              ),
              
              // Element info tooltip
              if (_hoveredElement != null)
                _buildElementTooltip(context, _hoveredElement!, scale, deviceBounds),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMouseHover(PointerEvent event, UIAnalyzerState state, double scale, Rect deviceBounds) {
    final localPosition = event.localPosition;
    final devicePosition = Offset(
      localPosition.dx / scale + deviceBounds.left,
      localPosition.dy / scale + deviceBounds.top,
    );

    // Find the topmost element at this position
    UIElement? hoveredElement;
    for (final element in state.flatElements.reversed) {
      if (element.bounds.contains(devicePosition)) {
        hoveredElement = element;
        break;
      }
    }

    if (_hoveredElement != hoveredElement || _mousePosition != localPosition) {
      setState(() {
        _hoveredElement = hoveredElement;
        _mousePosition = localPosition;
      });
    }
  }

  void _handleMouseExit() {
    if (_hoveredElement != null) {
      setState(() {
        _hoveredElement = null;
      });
    }
  }

  void _handleTapDown(TapDownDetails details, UIAnalyzerState state, double scale, Rect deviceBounds) {
    final localPosition = details.localPosition;
    final devicePosition = Offset(
      localPosition.dx / scale + deviceBounds.left,
      localPosition.dy / scale + deviceBounds.top,
    );

    // Find the topmost clickable element at this position
    UIElement? tappedElement;
    for (final element in state.flatElements.reversed) {
      if (element.bounds.contains(devicePosition)) {
        tappedElement = element;
        break;
      }
    }

    if (tappedElement != null) {
      state.selectElement(tappedElement);
    }
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.2).clamp(0.1, 5.0);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.2).clamp(0.1, 5.0);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  Widget _buildElementTooltip(BuildContext context, UIElement element, double scale, Rect deviceBounds) {
    final elementBounds = Rect.fromLTWH(
      (element.bounds.left - deviceBounds.left) * scale,
      (element.bounds.top - deviceBounds.top) * scale,
      element.bounds.width * scale,
      element.bounds.height * scale,
    );

    // Position tooltip above the element, or below if not enough space
    final tooltipTop = elementBounds.top > 100 ? elementBounds.top - 80 : elementBounds.bottom + 10;
    final tooltipLeft = elementBounds.left.clamp(10.0, MediaQuery.of(context).size.width - 250);

    return Positioned(
      left: tooltipLeft,
      top: tooltipTop,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.inverseSurface,
        child: Container(
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxWidth: 240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Element type
              Text(
                element.className.split('.').last,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              if (element.text.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Text: "${element.text}"',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onInverseSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              if (element.resourceId.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'ID: ${element.resourceId.split('/').last}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onInverseSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 4),
              Text(
                'Bounds: ${element.boundsString}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onInverseSurface.withOpacity(0.8),
                ),
              ),
              
              if (element.clickable) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Clickable',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for drawing UI elements on the preview canvas
class UIElementsPainter extends CustomPainter {
  final List<UIElement> elements;
  final UIElement? selectedElement;
  final UIElement? hoveredElement;
  final Rect deviceBounds;
  final double scale;
  final ColorScheme colorScheme;

  UIElementsPainter({
    required this.elements,
    this.selectedElement,
    this.hoveredElement,
    required this.deviceBounds,
    required this.scale,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw elements from back to front (parents before children)
    for (final element in elements) {
      _drawElement(canvas, element);
    }

    // Draw selected element highlight
    if (selectedElement != null) {
      _drawElementHighlight(canvas, selectedElement!, colorScheme.primary, 2.0);
    }

    // Draw hovered element highlight
    if (hoveredElement != null && hoveredElement != selectedElement) {
      _drawElementHighlight(canvas, hoveredElement!, colorScheme.secondary, 1.0);
    }
  }

  void _drawElement(Canvas canvas, UIElement element) {
    final bounds = _scaleRect(element.bounds);
    
    // Choose color based on element type
    Color elementColor = _getElementColor(element);
    
    // Draw element background with transparency
    final paint = Paint()
      ..color = elementColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(bounds, paint);
    
    // Draw element border
    final borderPaint = Paint()
      ..color = elementColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    canvas.drawRect(bounds, borderPaint);
    
    // Draw text if element has text and is large enough
    if (element.text.isNotEmpty && bounds.width > 20 && bounds.height > 15) {
      _drawElementText(canvas, element, bounds);
    }
  }

  void _drawElementHighlight(Canvas canvas, UIElement element, Color color, double strokeWidth) {
    final bounds = _scaleRect(element.bounds);
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    
    canvas.drawRect(bounds, paint);
    
    // Draw corner indicators for better visibility
    final cornerSize = 8.0;
    final cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Top-left corner
    canvas.drawRect(
      Rect.fromLTWH(bounds.left - strokeWidth, bounds.top - strokeWidth, cornerSize, strokeWidth * 2),
      cornerPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(bounds.left - strokeWidth, bounds.top - strokeWidth, strokeWidth * 2, cornerSize),
      cornerPaint,
    );
    
    // Top-right corner
    canvas.drawRect(
      Rect.fromLTWH(bounds.right - cornerSize + strokeWidth, bounds.top - strokeWidth, cornerSize, strokeWidth * 2),
      cornerPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(bounds.right - strokeWidth, bounds.top - strokeWidth, strokeWidth * 2, cornerSize),
      cornerPaint,
    );
    
    // Bottom-left corner
    canvas.drawRect(
      Rect.fromLTWH(bounds.left - strokeWidth, bounds.bottom - strokeWidth, cornerSize, strokeWidth * 2),
      cornerPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(bounds.left - strokeWidth, bounds.bottom - cornerSize + strokeWidth, strokeWidth * 2, cornerSize),
      cornerPaint,
    );
    
    // Bottom-right corner
    canvas.drawRect(
      Rect.fromLTWH(bounds.right - cornerSize + strokeWidth, bounds.bottom - strokeWidth, cornerSize, strokeWidth * 2),
      cornerPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(bounds.right - strokeWidth, bounds.bottom - cornerSize + strokeWidth, strokeWidth * 2, cornerSize),
      cornerPaint,
    );
  }

  void _drawElementText(Canvas canvas, UIElement element, Rect bounds) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: element.text,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: (12 * scale).clamp(8.0, 16.0),
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    
    textPainter.layout(maxWidth: bounds.width - 4);
    
    if (textPainter.size.width <= bounds.width - 4 && textPainter.size.height <= bounds.height - 4) {
      final textOffset = Offset(
        bounds.left + (bounds.width - textPainter.size.width) / 2,
        bounds.top + (bounds.height - textPainter.size.height) / 2,
      );
      
      textPainter.paint(canvas, textOffset);
    }
  }

  Color _getElementColor(UIElement element) {
    // Color coding based on element type and properties
    if (element.clickable) {
      return colorScheme.primary;
    } else if (element.className.contains('EditText')) {
      return colorScheme.secondary;
    } else if (element.className.contains('TextView')) {
      return colorScheme.tertiary;
    } else if (element.className.contains('Button')) {
      return colorScheme.primary;
    } else if (element.className.contains('ImageView')) {
      return colorScheme.error;
    } else if (element.className.contains('Layout')) {
      return colorScheme.outline;
    } else {
      return colorScheme.onSurfaceVariant;
    }
  }

  Rect _scaleRect(Rect rect) {
    return Rect.fromLTWH(
      (rect.left - deviceBounds.left) * scale,
      (rect.top - deviceBounds.top) * scale,
      rect.width * scale,
      rect.height * scale,
    );
  }

  @override
  bool shouldRepaint(UIElementsPainter oldDelegate) {
    return elements != oldDelegate.elements ||
           selectedElement != oldDelegate.selectedElement ||
           hoveredElement != oldDelegate.hoveredElement ||
           scale != oldDelegate.scale ||
           colorScheme != oldDelegate.colorScheme;
  }
}