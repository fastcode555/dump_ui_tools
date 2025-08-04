import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/ui_analyzer_state.dart';

/// Status bar widget that shows app status, statistics, and performance info
class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UIAnalyzerState>(
      builder: (context, state, child) {
        return Container(
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Connection status
              _buildStatusItem(
                context,
                icon: _getConnectionIcon(state),
                text: _getConnectionText(state),
                color: _getConnectionColor(context, state),
              ),
              
              _buildDivider(context),
              
              // Element count
              if (state.hasUIHierarchy) ...[
                _buildStatusItem(
                  context,
                  icon: Icons.account_tree,
                  text: '${state.filteredElementCount}/${state.totalElementCount} elements',
                ),
                
                _buildDivider(context),
              ],
              
              // Search results
              if (state.searchQuery.isNotEmpty) ...[
                _buildStatusItem(
                  context,
                  icon: Icons.search,
                  text: state.hasSearchResults 
                      ? '${state.searchResults.length} found'
                      : 'No results',
                  color: state.hasSearchResults 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
                
                _buildDivider(context),
              ],
              
              // Active filters
              if (state.hasActiveFilters) ...[
                _buildStatusItem(
                  context,
                  icon: Icons.filter_list,
                  text: _getActiveFiltersText(state),
                  color: Theme.of(context).colorScheme.primary,
                ),
                
                _buildDivider(context),
              ],
              
              const Spacer(),
              
              // Performance info (debug mode only)
              if (_isDebugMode()) ...[
                _buildStatusItem(
                  context,
                  icon: Icons.speed,
                  text: 'Debug Mode',
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                
                _buildDivider(context),
              ],
              
              // Current time
              _buildStatusItem(
                context,
                icon: Icons.access_time,
                text: _getCurrentTime(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurfaceVariant;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: effectiveColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: effectiveColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      color: Theme.of(context).dividerColor,
    );
  }

  IconData _getConnectionIcon(UIAnalyzerState state) {
    if (state.isLoading) {
      return Icons.sync;
    } else if (state.hasError) {
      return Icons.error;
    } else if (state.isDeviceConnected) {
      return Icons.smartphone;
    } else {
      return Icons.smartphone_outlined;
    }
  }

  String _getConnectionText(UIAnalyzerState state) {
    if (state.isLoading) {
      return 'Loading...';
    } else if (state.hasError) {
      return 'Error';
    } else if (state.isDeviceConnected) {
      return 'Connected: ${state.selectedDevice?.name ?? 'Unknown'}';
    } else {
      return 'No device';
    }
  }

  Color _getConnectionColor(BuildContext context, UIAnalyzerState state) {
    final theme = Theme.of(context);
    
    if (state.isLoading) {
      return theme.colorScheme.primary;
    } else if (state.hasError) {
      return theme.colorScheme.error;
    } else if (state.isDeviceConnected) {
      return Colors.green;
    } else {
      return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _getActiveFiltersText(UIAnalyzerState state) {
    final criteria = state.filterCriteria;
    final filters = <String>[];
    
    if (criteria.showOnlyClickable) filters.add('Clickable');
    if (criteria.showOnlyInputs) filters.add('Inputs');
    if (criteria.showOnlyWithText) filters.add('Text');
    
    return '${filters.length} filter${filters.length != 1 ? 's' : ''}';
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  bool _isDebugMode() {
    bool isDebug = false;
    assert(() {
      isDebug = true;
      return true;
    }());
    return isDebug;
  }
}

/// Navigation service for accessing context globally
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

/// Extension to add context to UIAnalyzerState
extension UIAnalyzerStateContext on UIAnalyzerState {
  BuildContext? get context => NavigationService.navigatorKey.currentContext;
}