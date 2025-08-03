import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/adb_service.dart';
import '../services/file_manager.dart';
import '../services/xml_parser.dart';

/// Global error handler for the UI Analyzer application
class ErrorHandler {
  static const Duration _snackBarDuration = Duration(seconds: 4);
  static const Duration _dialogDismissDelay = Duration(seconds: 10);

  /// Handle any exception and show appropriate user interface
  static void handleError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    VoidCallback? onRetry,
    bool showSnackBar = false,
  }) {
    final errorInfo = _analyzeError(error);
    
    if (showSnackBar) {
      _showErrorSnackBar(context, errorInfo, onRetry);
    } else {
      _showErrorDialog(context, errorInfo, customMessage, onRetry);
    }
    
    // Log error for debugging
    debugPrint('Error handled: ${errorInfo.type} - ${errorInfo.message}');
    if (errorInfo.details != null) {
      debugPrint('Details: ${errorInfo.details}');
    }
  }

  /// Show error as a snack bar for less critical errors
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: _snackBarDuration,
        action: onRetry != null
            ? SnackBarAction(
                label: '重试',
                onPressed: onRetry,
              )
            : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show success message as a snack bar
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Analyze error and return structured error information
  static ErrorInfo _analyzeError(dynamic error) {
    if (error is ADBException) {
      return ErrorInfo(
        type: ErrorType.adb,
        title: 'ADB连接错误',
        message: error.message,
        details: error.details,
        icon: Icons.phone_android,
        severity: ErrorSeverity.high,
        solutions: _getADBSolutions(),
      );
    }
    
    if (error is XMLParseException) {
      return ErrorInfo(
        type: ErrorType.xmlParse,
        title: 'XML解析错误',
        message: error.message,
        details: error.details,
        icon: Icons.code,
        severity: ErrorSeverity.medium,
        solutions: _getXMLSolutions(),
      );
    }
    
    if (error is FileOperationException) {
      return ErrorInfo(
        type: ErrorType.fileOperation,
        title: '文件操作错误',
        message: error.message,
        details: error.details,
        icon: Icons.folder,
        severity: ErrorSeverity.medium,
        solutions: _getFileSolutions(),
      );
    }
    
    if (error is PlatformException) {
      return ErrorInfo(
        type: ErrorType.platform,
        title: '系统错误',
        message: error.message ?? '发生了系统级错误',
        details: error.details?.toString(),
        icon: Icons.error,
        severity: ErrorSeverity.high,
        solutions: _getPlatformSolutions(),
      );
    }
    
    // Generic error
    return ErrorInfo(
      type: ErrorType.generic,
      title: '未知错误',
      message: error.toString(),
      details: null,
      icon: Icons.error_outline,
      severity: ErrorSeverity.medium,
      solutions: _getGenericSolutions(),
    );
  }

  /// Show error dialog with detailed information and solutions
  static void _showErrorDialog(
    BuildContext context,
    ErrorInfo errorInfo,
    String? customMessage,
    VoidCallback? onRetry,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        errorInfo: errorInfo,
        customMessage: customMessage,
        onRetry: onRetry,
      ),
    );
  }

  /// Show error as snack bar
  static void _showErrorSnackBar(
    BuildContext context,
    ErrorInfo errorInfo,
    VoidCallback? onRetry,
  ) {
    showErrorSnackBar(
      context,
      errorInfo.message,
      onRetry: onRetry,
    );
  }

  /// Get ADB-specific solutions
  static List<String> _getADBSolutions() {
    return [
      '确保Android设备已连接到电脑',
      '检查设备是否已启用USB调试',
      '尝试重新连接USB线缆',
      '在设备上允许USB调试授权',
      '检查ADB驱动是否正确安装',
    ];
  }

  /// Get XML parsing solutions
  static List<String> _getXMLSolutions() {
    return [
      '检查UI dump文件是否完整',
      '尝试重新获取UI结构',
      '确保应用界面已完全加载',
      '检查设备屏幕是否处于活动状态',
    ];
  }

  /// Get file operation solutions
  static List<String> _getFileSolutions() {
    return [
      '检查文件路径是否正确',
      '确保有足够的磁盘空间',
      '检查文件访问权限',
      '尝试选择不同的保存位置',
    ];
  }

  /// Get platform-specific solutions
  static List<String> _getPlatformSolutions() {
    return [
      '重启应用程序',
      '检查系统权限设置',
      '确保macOS版本兼容',
      '联系技术支持',
    ];
  }

  /// Get generic error solutions
  static List<String> _getGenericSolutions() {
    return [
      '重试当前操作',
      '重启应用程序',
      '检查网络连接',
      '联系技术支持',
    ];
  }
}

/// Error information structure
class ErrorInfo {
  final ErrorType type;
  final String title;
  final String message;
  final String? details;
  final IconData icon;
  final ErrorSeverity severity;
  final List<String> solutions;

  const ErrorInfo({
    required this.type,
    required this.title,
    required this.message,
    this.details,
    required this.icon,
    required this.severity,
    required this.solutions,
  });
}

/// Error types
enum ErrorType {
  adb,
  xmlParse,
  fileOperation,
  platform,
  generic,
}

/// Error severity levels
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

/// Custom error dialog widget
class ErrorDialog extends StatelessWidget {
  final ErrorInfo errorInfo;
  final String? customMessage;
  final VoidCallback? onRetry;

  const ErrorDialog({
    super.key,
    required this.errorInfo,
    this.customMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AlertDialog(
      icon: Icon(
        errorInfo.icon,
        size: 48,
        color: _getSeverityColor(colorScheme, errorInfo.severity),
      ),
      title: Text(
        errorInfo.title,
        style: theme.textTheme.headlineSmall,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error message
            Text(
              customMessage ?? errorInfo.message,
              style: theme.textTheme.bodyMedium,
            ),
            
            // Error details (if available)
            if (errorInfo.details != null) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('详细信息'),
                initiallyExpanded: false,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      errorInfo.details!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Solutions
            if (errorInfo.solutions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '解决方案:',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...errorInfo.solutions.map((solution) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_right,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        solution,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
      actions: [
        // Copy error details button
        if (errorInfo.details != null)
          TextButton.icon(
            onPressed: () => _copyErrorDetails(context),
            icon: const Icon(Icons.copy),
            label: const Text('复制详情'),
          ),
        
        // Help button for ADB errors
        if (errorInfo.type == ErrorType.adb)
          TextButton.icon(
            onPressed: () => _showADBHelp(context),
            icon: const Icon(Icons.help),
            label: const Text('帮助'),
          ),
        
        // Retry button
        if (onRetry != null)
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry?.call();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        
        // Close button
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  /// Copy error details to clipboard
  void _copyErrorDetails(BuildContext context) {
    final details = '''
错误类型: ${errorInfo.title}
错误信息: ${errorInfo.message}
详细信息: ${errorInfo.details ?? '无'}
时间: ${DateTime.now().toString()}
''';
    
    Clipboard.setData(ClipboardData(text: details));
    ErrorHandler.showSuccessSnackBar(context, '错误详情已复制到剪贴板');
  }

  /// Show ADB help dialog
  void _showADBHelp(BuildContext context) {
    Navigator.of(context).pop(); // Close current dialog
    showDialog(
      context: context,
      builder: (context) => const ADBHelpDialog(),
    );
  }

  /// Get color based on error severity
  Color _getSeverityColor(ColorScheme colorScheme, ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return colorScheme.primary;
      case ErrorSeverity.medium:
        return Colors.orange;
      case ErrorSeverity.high:
        return colorScheme.error;
      case ErrorSeverity.critical:
        return Colors.red.shade700;
    }
  }
}

/// ADB help dialog
class ADBHelpDialog extends StatelessWidget {
  const ADBHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('ADB连接帮助'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpSection(
              theme,
              '1. 启用USB调试',
              [
                '打开设备的"设置" > "关于手机"',
                '连续点击"版本号"7次启用开发者选项',
                '返回设置，进入"开发者选项"',
                '启用"USB调试"选项',
              ],
            ),
            const SizedBox(height: 16),
            _buildHelpSection(
              theme,
              '2. 连接设备',
              [
                '使用USB线缆连接设备到电脑',
                '在设备上允许USB调试授权',
                '选择"始终允许来自此计算机"',
              ],
            ),
            const SizedBox(height: 16),
            _buildHelpSection(
              theme,
              '3. 验证连接',
              [
                '打开终端应用',
                '输入命令: adb devices',
                '应该看到设备ID和"device"状态',
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildHelpSection(ThemeData theme, String title, List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ...steps.map((step) => Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
              Expanded(
                child: Text(
                  step,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}