import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding overlay that guides first-time users through the application
class OnboardingOverlay extends StatefulWidget {
  final Widget child;
  final VoidCallback? onComplete;

  const OnboardingOverlay({
    super.key,
    required this.child,
    this.onComplete,
  });

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay>
    with TickerProviderStateMixin {
  static const String _onboardingKey = 'onboarding_completed';
  
  bool _showOnboarding = false;
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: '欢迎使用 Android UI Analyzer',
      description: '这是一个强大的Android UI分析工具，帮助您快速分析和理解Android应用的界面结构。',
      targetKey: null,
      position: OnboardingPosition.center,
      icon: Icons.android,
    ),
    OnboardingStep(
      title: '设备选择',
      description: '首先，在这里选择您要分析的Android设备。确保设备已连接并启用了USB调试。',
      targetKey: 'device_selector',
      position: OnboardingPosition.bottom,
      icon: Icons.smartphone,
    ),
    OnboardingStep(
      title: '获取UI结构',
      description: '点击这个按钮来获取当前屏幕的UI层次结构。确保设备屏幕显示您要分析的界面。',
      targetKey: 'capture_button',
      position: OnboardingPosition.bottom,
      icon: Icons.screenshot_monitor,
    ),
    OnboardingStep(
      title: '树形视图',
      description: '获取UI结构后，您可以在左侧的树形视图中浏览所有UI元素。点击元素可以查看详细信息。',
      targetKey: 'tree_view',
      position: OnboardingPosition.right,
      icon: Icons.account_tree,
    ),
    OnboardingStep(
      title: '属性面板',
      description: '选中的UI元素的详细属性会显示在这里。您可以点击属性值来复制到剪贴板。',
      targetKey: 'property_panel',
      position: OnboardingPosition.left,
      icon: Icons.info,
    ),
    OnboardingStep(
      title: '屏幕预览',
      description: '这里显示设备屏幕的可视化预览。选中的元素会在预览中高亮显示，您也可以点击预览来选择元素。',
      targetKey: 'preview_panel',
      position: OnboardingPosition.left,
      icon: Icons.preview,
    ),
    OnboardingStep(
      title: '搜索和过滤',
      description: '使用搜索框和过滤选项来快速找到您需要的UI元素。支持按文本、类型等条件过滤。',
      targetKey: 'search_bar',
      position: OnboardingPosition.bottom,
      icon: Icons.search,
    ),
    OnboardingStep(
      title: '开始使用',
      description: '现在您已经了解了基本功能！点击右上角的帮助按钮可以查看更详细的使用说明。',
      targetKey: null,
      position: OnboardingPosition.center,
      icon: Icons.check_circle,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _checkOnboardingStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_onboardingKey) ?? false;
    
    if (!completed) {
      setState(() {
        _showOnboarding = true;
      });
      _animationController.forward();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    
    await _animationController.reverse();
    setState(() {
      _showOnboarding = false;
    });
    
    widget.onComplete?.call();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showOnboarding)
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: _buildOnboardingOverlay(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildOnboardingOverlay() {
    final step = _steps[_currentStep];
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: Stack(
        children: [
          // Backdrop
          GestureDetector(
            onTap: () {}, // Prevent taps from going through
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
          
          // Highlight target element
          if (step.targetKey != null)
            _buildTargetHighlight(step.targetKey!),
          
          // Onboarding card
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: _buildOnboardingCard(step, theme),
          ),
          
          // Progress indicator
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: _buildProgressIndicator(theme),
          ),
          
          // Skip button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _skipOnboarding,
              child: Text(
                '跳过',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetHighlight(String targetKey) {
    // This would need to be implemented with a global key system
    // For now, return an empty container
    return Container();
  }

  Widget _buildOnboardingCard(OnboardingStep step, ThemeData theme) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      step.icon,
                      color: theme.colorScheme.onPrimary,
                      size: 32,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    step.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    step.description,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous button
                      if (_currentStep > 0)
                        TextButton.icon(
                          onPressed: _previousStep,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('上一步'),
                        )
                      else
                        const SizedBox.shrink(),
                      
                      // Next/Finish button
                      ElevatedButton.icon(
                        onPressed: _nextStep,
                        icon: Icon(_currentStep == _steps.length - 1
                            ? Icons.check
                            : Icons.arrow_forward),
                        label: Text(_currentStep == _steps.length - 1
                            ? '完成'
                            : '下一步'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_currentStep + 1} / ${_steps.length}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              height: 4,
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _steps.length,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reset onboarding status (for testing purposes)
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
  }
}

class OnboardingStep {
  final String title;
  final String description;
  final String? targetKey;
  final OnboardingPosition position;
  final IconData icon;

  const OnboardingStep({
    required this.title,
    required this.description,
    this.targetKey,
    required this.position,
    required this.icon,
  });
}

enum OnboardingPosition {
  top,
  bottom,
  left,
  right,
  center,
}

/// Widget to show quick tips and hints
class QuickTip extends StatelessWidget {
  final String message;
  final IconData? icon;
  final VoidCallback? onDismiss;

  const QuickTip({
    super.key,
    required this.message,
    this.icon,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                size: 16,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }
}