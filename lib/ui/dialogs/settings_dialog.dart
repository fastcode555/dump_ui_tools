import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/ui_analyzer_state.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UIAnalyzerState>(
      builder: (context, state, child) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Settings'),
            ],
          ),
          content: SizedBox(
            width: 400,
            height: 500, // Set a fixed height to enable scrolling
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Theme Settings Section
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Theme Mode Selection
                _buildThemeSelector(context, state),
                
                const SizedBox(height: 24),
                
                // UI Settings Section
                Text(
                  'Interface',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Preview Panel Toggle
                SwitchListTile(
                  title: const Text('Show Preview Panel'),
                  subtitle: const Text('Display screen layout preview'),
                  value: state.isPreviewVisible,
                  onChanged: (value) => state.togglePreviewVisibility(),
                  contentPadding: EdgeInsets.zero,
                ),
                
                // XML Viewer Toggle
                SwitchListTile(
                  title: const Text('Auto-show XML Viewer'),
                  subtitle: const Text('Automatically open XML viewer when capturing UI'),
                  value: state.isXmlViewerVisible,
                  onChanged: (value) => state.setXmlViewerVisible(value),
                  contentPadding: EdgeInsets.zero,
                ),
                
                const SizedBox(height: 24),
                
                // Performance Settings Section
                Text(
                  'Performance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Search Debounce Setting
                ListTile(
                  title: const Text('Search Delay'),
                  subtitle: Text('${state.searchDebounceDuration.inMilliseconds}ms delay for search'),
                  trailing: SizedBox(
                    width: 100,
                    child: Slider(
                      value: state.searchDebounceDuration.inMilliseconds.toDouble(),
                      min: 100,
                      max: 1000,
                      divisions: 9,
                      label: '${state.searchDebounceDuration.inMilliseconds}ms',
                      onChanged: (value) {
                        state.updatePerformanceSettings(
                          searchDebounceMs: value.round(),
                        );
                      },
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                
                // Animation Duration Setting
                ListTile(
                  title: const Text('Animation Speed'),
                  subtitle: Text('${state.animationDuration.inMilliseconds}ms for UI transitions'),
                  trailing: SizedBox(
                    width: 100,
                    child: Slider(
                      value: state.animationDuration.inMilliseconds.toDouble(),
                      min: 100,
                      max: 500,
                      divisions: 8,
                      label: '${state.animationDuration.inMilliseconds}ms',
                      onChanged: (value) {
                        state.updatePerformanceSettings(
                          animationDurationMs: value.round(),
                        );
                      },
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                
                // Virtual Scrolling Toggle
                SwitchListTile(
                  title: const Text('Virtual Scrolling'),
                  subtitle: const Text('Optimize performance for large UI hierarchies'),
                  value: true, // Always enabled for now
                  onChanged: null, // Disabled for now
                  contentPadding: EdgeInsets.zero,
                ),
                
                // Widget Caching Toggle
                SwitchListTile(
                  title: const Text('Widget Caching'),
                  subtitle: const Text('Cache rendered widgets for better performance'),
                  value: true, // Always enabled for now
                  onChanged: null, // Disabled for now
                  contentPadding: EdgeInsets.zero,
                ),
                
                const SizedBox(height: 24),
                
                // About Section
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.android,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Android UI Analyzer',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Version 1.0.0',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A Flutter desktop application for analyzing Android UI hierarchy',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeSelector(BuildContext context, UIAnalyzerState state) {
    return Column(
      children: [
        RadioListTile<ThemeMode>(
          title: const Text('System'),
          subtitle: const Text('Follow system theme'),
          value: ThemeMode.system,
          groupValue: state.themeMode,
          onChanged: (value) => state.setThemeMode(value!),
          contentPadding: EdgeInsets.zero,
          secondary: Icon(
            Icons.brightness_auto,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Light'),
          subtitle: const Text('Light theme'),
          value: ThemeMode.light,
          groupValue: state.themeMode,
          onChanged: (value) => state.setThemeMode(value!),
          contentPadding: EdgeInsets.zero,
          secondary: Icon(
            Icons.light_mode,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Dark'),
          subtitle: const Text('Dark theme'),
          value: ThemeMode.dark,
          groupValue: state.themeMode,
          onChanged: (value) => state.setThemeMode(value!),
          contentPadding: EdgeInsets.zero,
          secondary: Icon(
            Icons.dark_mode,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }
}