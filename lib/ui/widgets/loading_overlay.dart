import 'package:flutter/material.dart';

/// Loading overlay widget that shows progress indicators and loading messages
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final double? progress;
  final Widget child;
  final Color? backgroundColor;
  final bool showProgressBar;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.progress,
    this.backgroundColor,
    this.showProgressBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withOpacity(0.3),
            child: Center(
              child: LoadingIndicator(
                message: message,
                progress: progress,
                showProgressBar: showProgressBar,
              ),
            ),
          ),
      ],
    );
  }
}

/// Loading indicator widget with customizable appearance
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double? progress;
  final bool showProgressBar;
  final IconData? icon;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.message,
    this.progress,
    this.showProgressBar = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Loading icon or spinner
            if (icon != null)
              Icon(
                icon,
                size: 48,
                color: color ?? colorScheme.primary,
              )
            else if (showProgressBar && progress != null)
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  color: color ?? colorScheme.primary,
                ),
              )
            else
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: color ?? colorScheme.primary,
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Loading message
            if (message != null)
              Text(
                message!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            
            // Progress bar
            if (showProgressBar && progress != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: colorScheme.surfaceVariant,
                  color: color ?? colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress! * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Specialized loading indicator for UI capture operations
class UICaptureLoadingIndicator extends StatefulWidget {
  final String? currentStep;
  final double? progress;
  final List<String> steps;
  final int currentStepIndex;

  const UICaptureLoadingIndicator({
    super.key,
    this.currentStep,
    this.progress,
    this.steps = const [],
    this.currentStepIndex = 0,
  });

  @override
  State<UICaptureLoadingIndicator> createState() => _UICaptureLoadingIndicatorState();
}

class _UICaptureLoadingIndicatorState extends State<UICaptureLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated phone icon
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_animation.value * 0.1),
                  child: Icon(
                    Icons.screenshot_monitor,
                    size: 48,
                    color: colorScheme.primary.withOpacity(0.7 + (_animation.value * 0.3)),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Current step message
            Text(
              widget.currentStep ?? '正在获取UI结构...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Progress indicator
            if (widget.progress != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: 250,
                child: LinearProgressIndicator(
                  value: widget.progress,
                  backgroundColor: colorScheme.surfaceVariant,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(widget.progress! * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            
            // Steps list
            if (widget.steps.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...widget.steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                final isCompleted = index < widget.currentStepIndex;
                final isCurrent = index == widget.currentStepIndex;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        isCompleted
                            ? Icons.check_circle
                            : isCurrent
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                        size: 16,
                        color: isCompleted
                            ? Colors.green
                            : isCurrent
                                ? colorScheme.primary
                                : colorScheme.outline,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          step,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isCompleted || isCurrent
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                            fontWeight: isCurrent ? FontWeight.w500 : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

/// Simple loading button that shows spinner when loading
class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final String? loadingText;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.child,
    this.style,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                if (loadingText != null) ...[
                  const SizedBox(width: 8),
                  Text(loadingText!),
                ],
              ],
            )
          : child,
    );
  }
}

/// Loading state mixin for stateful widgets
mixin LoadingStateMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  String? _loadingMessage;
  double? _loadingProgress;

  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;
  double? get loadingProgress => _loadingProgress;

  void setLoading(bool loading, {String? message, double? progress}) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
        _loadingMessage = message;
        _loadingProgress = progress;
      });
    }
  }

  void updateLoadingProgress(double progress, {String? message}) {
    if (mounted) {
      setState(() {
        _loadingProgress = progress;
        if (message != null) {
          _loadingMessage = message;
        }
      });
    }
  }

  void clearLoading() {
    setLoading(false, message: null, progress: null);
  }
}