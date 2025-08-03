import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';

/// Performance monitoring widget that tracks FPS and memory usage
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.enabled = false,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _performanceTimer;
  
  // Performance metrics
  double _currentFPS = 0.0;
  int _frameCount = 0;
  DateTime _lastFrameTime = DateTime.now();
  List<double> _fpsHistory = [];
  
  // Memory metrics (simplified)
  int _widgetCount = 0;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    if (widget.enabled) {
      _startMonitoring();
    }
  }

  @override
  void didUpdateWidget(PerformanceMonitor oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _startMonitoring();
      } else {
        _stopMonitoring();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stopMonitoring();
    super.dispose();
  }

  void _startMonitoring() {
    // Start FPS monitoring
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
    
    // Start periodic performance updates
    _performanceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Update widget count (simplified)
          _widgetCount = context.findRenderObject()?.debugDescribeChildren()?.length ?? 0;
        });
      }
    });
  }

  void _stopMonitoring() {
    _performanceTimer?.cancel();
    _performanceTimer = null;
  }

  void _onFrame(Duration timestamp) {
    if (!widget.enabled || !mounted) return;
    
    final now = DateTime.now();
    final timeDiff = now.difference(_lastFrameTime).inMicroseconds;
    
    if (timeDiff > 0) {
      final fps = 1000000 / timeDiff; // Convert to FPS
      _frameCount++;
      
      setState(() {
        _currentFPS = fps;
        _fpsHistory.add(fps);
        
        // Keep only last 60 FPS readings
        if (_fpsHistory.length > 60) {
          _fpsHistory.removeAt(0);
        }
      });
    }
    
    _lastFrameTime = now;
    
    // Schedule next frame callback
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.enabled)
          Positioned(
            top: 10,
            right: 10,
            child: _buildPerformanceOverlay(),
          ),
      ],
    );
  }

  Widget _buildPerformanceOverlay() {
    final theme = Theme.of(context);
    final avgFPS = _fpsHistory.isNotEmpty 
        ? _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length 
        : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Performance',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'FPS: ${_currentFPS.toStringAsFixed(1)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: _getFPSColor(avgFPS),
              fontFamily: 'monospace',
            ),
          ),
          Text(
            'Avg: ${avgFPS.toStringAsFixed(1)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            'Widgets: $_widgetCount',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          _buildFPSGraph(),
        ],
      ),
    );
  }

  Widget _buildFPSGraph() {
    if (_fpsHistory.isEmpty) {
      return const SizedBox(width: 100, height: 20);
    }
    
    return CustomPaint(
      size: const Size(100, 20),
      painter: FPSGraphPainter(
        fpsHistory: _fpsHistory,
        maxFPS: 60.0,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Color _getFPSColor(double fps) {
    if (fps >= 55) {
      return Colors.green;
    } else if (fps >= 30) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}

/// Custom painter for FPS graph
class FPSGraphPainter extends CustomPainter {
  final List<double> fpsHistory;
  final double maxFPS;
  final Color color;

  FPSGraphPainter({
    required this.fpsHistory,
    required this.maxFPS,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fpsHistory.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    for (int i = 0; i < fpsHistory.length; i++) {
      final x = (i / (fpsHistory.length - 1)) * size.width;
      final y = size.height - (fpsHistory[i] / maxFPS) * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
    
    // Draw baseline at 60 FPS
    final baselinePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 0.5;
    
    canvas.drawLine(
      Offset(0, size.height - (60 / maxFPS) * size.height),
      Offset(size.width, size.height - (60 / maxFPS) * size.height),
      baselinePaint,
    );
  }

  @override
  bool shouldRepaint(FPSGraphPainter oldDelegate) {
    return oldDelegate.fpsHistory != fpsHistory;
  }
}

/// Debug performance overlay for development
class DebugPerformanceOverlay extends StatelessWidget {
  final Widget child;

  const DebugPerformanceOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    bool showOverlay = false;
    assert(() {
      showOverlay = true;
      return true;
    }());

    return PerformanceMonitor(
      enabled: showOverlay,
      child: child,
    );
  }
}