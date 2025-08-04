import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/ui_analyzer_state.dart';
import '../../models/android_device.dart';
import '../../utils/error_handler.dart';
import '../dialogs/settings_dialog.dart';
import '../dialogs/help_dialog.dart';
import '../panels/history_panel.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UIAnalyzerState>(
      builder: (context, state, child) {
        return AppBar(
          title: Row(
            children: [
              Icon(
                Icons.android,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('Android UI Analyzer'),
            ],
          ),
          actions: [
            // Device selection dropdown
            _buildDeviceSelector(context, state),
            
            const SizedBox(width: 16),
            
            // Device connection status
            _buildConnectionStatus(context, state),
            
            const SizedBox(width: 16),
            
            // Capture UI button
            _buildCaptureButton(context, state),
            
            const SizedBox(width: 8),
            
            // Refresh devices button
            IconButton(
              onPressed: state.isLoading ? null : () => _refreshDevices(context, state),
              icon: state.isLoading && state.loadingMessage.contains('device')
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Refresh Devices',
            ),
            
            // History button
            IconButton(
              onPressed: () => _showHistory(context),
              icon: const Icon(Icons.history),
              tooltip: 'View History',
            ),
            
            // Theme toggle button
            IconButton(
              onPressed: () {
                final currentMode = state.themeMode;
                if (currentMode == ThemeMode.light) {
                  state.setThemeMode(ThemeMode.dark);
                } else if (currentMode == ThemeMode.dark) {
                  state.setThemeMode(ThemeMode.system);
                } else {
                  state.setThemeMode(ThemeMode.light);
                }
              },
              icon: Icon(_getThemeIcon(state.themeMode)),
              tooltip: 'Toggle Theme (${_getThemeLabel(state.themeMode)})',
            ),
            
            // Help button
            IconButton(
              onPressed: () => HelpDialog.show(context),
              icon: const Icon(Icons.help),
              tooltip: 'Help (Cmd+?)',
            ),
            
            // Settings button
            IconButton(
              onPressed: () => SettingsDialog.show(context),
              icon: const Icon(Icons.settings),
              tooltip: 'Settings (Cmd+,)',
            ),
            
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }

  Widget _buildDeviceSelector(BuildContext context, UIAnalyzerState state) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 250),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AndroidDevice?>(
          value: state.selectedDevice,
          hint: Text(
            'Select Device',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          items: [
            // No device option
            DropdownMenuItem<AndroidDevice?>(
              value: null,
              child: Row(
                children: [
                  Icon(
                    Icons.smartphone_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No Device',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            // Available devices
            ...state.availableDevices.map((device) => DropdownMenuItem<AndroidDevice?>(
              value: device,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    device.isConnected ? Icons.smartphone : Icons.smartphone_outlined,
                    size: 16,
                    color: device.isConnected 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      device.name.isNotEmpty ? device.name : device.id,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: device.isConnected 
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
          onChanged: state.isLoading ? null : (device) => _selectDevice(context, state, device),
          icon: Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context, UIAnalyzerState state) {
    final device = state.selectedDevice;
    final isConnected = device?.isConnected ?? false;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isConnected 
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: isConnected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isConnected 
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onErrorContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton(BuildContext context, UIAnalyzerState state) {
    final canCapture = state.selectedDevice?.isConnected ?? false;
    final isCapturing = state.isLoading && state.loadingMessage.contains('UI');
    
    return ElevatedButton.icon(
      onPressed: canCapture && !state.isLoading ? () => _captureUI(context, state) : null,
      icon: isCapturing
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : const Icon(Icons.screenshot_monitor, size: 18),
      label: Text(isCapturing ? 'Capturing...' : 'Capture UI'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _selectDevice(BuildContext context, UIAnalyzerState state, AndroidDevice? device) {
    state.selectDevice(device);
    
    if (device != null) {
      // Show device selected feedback
      ErrorHandler.showSuccessSnackBar(
        context,
        '已选择设备: ${device.name.isNotEmpty ? device.name : device.id}',
        icon: Icons.smartphone,
      );
    }
  }

  void _refreshDevices(BuildContext context, UIAnalyzerState state) async {
    try {
      await state.refreshDevices();
      
      if (state.availableDevices.isEmpty) {
        if (context.mounted) {
          ErrorHandler.showErrorSnackBar(
            context,
            '未找到设备。请确保ADB已安装且设备已连接。',
          );
        }
      } else {
        if (context.mounted) {
          ErrorHandler.showSuccessSnackBar(
            context,
            '找到 ${state.availableDevices.length} 个设备',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.handleError(
          context,
          e,
          customMessage: '刷新设备列表失败',
          onRetry: () => _refreshDevices(context, state),
          showSnackBar: true,
        );
      }
    }
  }

  void _captureUI(BuildContext context, UIAnalyzerState state) async {
    try {
      await state.captureUIHierarchy();
      
      if (context.mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'UI层次结构获取成功！',
          icon: Icons.screenshot_monitor,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.handleError(
          context,
          e,
          customMessage: '获取UI结构失败',
          onRetry: () => _captureUI(context, state),
        );
      }
    }
  }

  void _showHistory(BuildContext context) {
    HistoryPanelDialog.show(context);
  }



  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
  
  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}