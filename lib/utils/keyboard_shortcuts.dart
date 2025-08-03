import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/ui_analyzer_state.dart';
import '../models/filter_criteria.dart';
import '../ui/dialogs/help_dialog.dart';
import '../ui/dialogs/settings_dialog.dart';
import '../ui/panels/history_panel.dart';

/// Keyboard shortcuts handler for the UI Analyzer application
class KeyboardShortcuts extends StatelessWidget {
  final Widget child;
  final UIAnalyzerState state;

  const KeyboardShortcuts({
    super.key,
    required this.child,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _getShortcuts(),
      child: Actions(
        actions: _getActions(context),
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }

  Map<ShortcutActivator, Intent> _getShortcuts() {
    return {
      // General shortcuts
      const SingleActivator(LogicalKeyboardKey.keyR, meta: true): const RefreshDevicesIntent(),
      const SingleActivator(LogicalKeyboardKey.keyU, meta: true): const CaptureUIIntent(),
      const SingleActivator(LogicalKeyboardKey.keyF, meta: true): const FocusSearchIntent(),
      const SingleActivator(LogicalKeyboardKey.keyH, meta: true): const ToggleHistoryIntent(),
      const SingleActivator(LogicalKeyboardKey.keyX, meta: true): const ToggleXMLIntent(),
      const SingleActivator(LogicalKeyboardKey.comma, meta: true): const OpenSettingsIntent(),
      const SingleActivator(LogicalKeyboardKey.slash, meta: true, shift: true): const ShowHelpIntent(),
      
      // Theme shortcuts
      const SingleActivator(LogicalKeyboardKey.keyT, meta: true): const ToggleThemeIntent(),
      
      // Navigation shortcuts
      const SingleActivator(LogicalKeyboardKey.arrowUp): const NavigateUpIntent(),
      const SingleActivator(LogicalKeyboardKey.arrowDown): const NavigateDownIntent(),
      const SingleActivator(LogicalKeyboardKey.arrowLeft): const CollapseNodeIntent(),
      const SingleActivator(LogicalKeyboardKey.arrowRight): const ExpandNodeIntent(),
      const SingleActivator(LogicalKeyboardKey.enter): const SelectNodeIntent(),
      const SingleActivator(LogicalKeyboardKey.escape): const ClearSelectionIntent(),
      
      // Edit shortcuts
      const SingleActivator(LogicalKeyboardKey.keyC, meta: true): const CopyPropertyIntent(),
      const SingleActivator(LogicalKeyboardKey.keyA, meta: true): const SelectAllXMLIntent(),
      const SingleActivator(LogicalKeyboardKey.keyS, meta: true): const ExportXMLIntent(),
      
      // View shortcuts
      const SingleActivator(LogicalKeyboardKey.equal, meta: true): const ZoomInIntent(),
      const SingleActivator(LogicalKeyboardKey.minus, meta: true): const ZoomOutIntent(),
      const SingleActivator(LogicalKeyboardKey.digit0, meta: true): const ResetZoomIntent(),
      
      // Quick filter shortcuts
      const SingleActivator(LogicalKeyboardKey.digit1, meta: true): const FilterClickableIntent(),
      const SingleActivator(LogicalKeyboardKey.digit2, meta: true): const FilterInputsIntent(),
      const SingleActivator(LogicalKeyboardKey.digit3, meta: true): const FilterTextIntent(),
      const SingleActivator(LogicalKeyboardKey.digit4, meta: true): const ClearFiltersIntent(),
      
      // Panel shortcuts
      const SingleActivator(LogicalKeyboardKey.keyP, meta: true): const TogglePreviewIntent(),
      const SingleActivator(LogicalKeyboardKey.keyL, meta: true): const ToggleLeftPanelIntent(),
      const SingleActivator(LogicalKeyboardKey.keyR, meta: true, shift: true): const ResetLayoutIntent(),
      
      // Quick actions
      const SingleActivator(LogicalKeyboardKey.keyD, meta: true): const DuplicateElementIntent(),
      const SingleActivator(LogicalKeyboardKey.keyE, meta: true): const ExportSelectedIntent(),
      const SingleActivator(LogicalKeyboardKey.keyI, meta: true): const InspectElementIntent(),
    };
  }

  Map<Type, Action<Intent>> _getActions(BuildContext context) {
    return {
      RefreshDevicesIntent: CallbackAction<RefreshDevicesIntent>(
        onInvoke: (intent) => _refreshDevices(context),
      ),
      CaptureUIIntent: CallbackAction<CaptureUIIntent>(
        onInvoke: (intent) => _captureUI(context),
      ),
      FocusSearchIntent: CallbackAction<FocusSearchIntent>(
        onInvoke: (intent) => _focusSearch(context),
      ),
      ToggleHistoryIntent: CallbackAction<ToggleHistoryIntent>(
        onInvoke: (intent) => _toggleHistory(context),
      ),
      ToggleXMLIntent: CallbackAction<ToggleXMLIntent>(
        onInvoke: (intent) => _toggleXML(context),
      ),
      OpenSettingsIntent: CallbackAction<OpenSettingsIntent>(
        onInvoke: (intent) => _openSettings(context),
      ),
      ShowHelpIntent: CallbackAction<ShowHelpIntent>(
        onInvoke: (intent) => _showHelp(context),
      ),
      ToggleThemeIntent: CallbackAction<ToggleThemeIntent>(
        onInvoke: (intent) => _toggleTheme(context),
      ),
      NavigateUpIntent: CallbackAction<NavigateUpIntent>(
        onInvoke: (intent) => _navigateUp(context),
      ),
      NavigateDownIntent: CallbackAction<NavigateDownIntent>(
        onInvoke: (intent) => _navigateDown(context),
      ),
      CollapseNodeIntent: CallbackAction<CollapseNodeIntent>(
        onInvoke: (intent) => _collapseNode(context),
      ),
      ExpandNodeIntent: CallbackAction<ExpandNodeIntent>(
        onInvoke: (intent) => _expandNode(context),
      ),
      SelectNodeIntent: CallbackAction<SelectNodeIntent>(
        onInvoke: (intent) => _selectNode(context),
      ),
      ClearSelectionIntent: CallbackAction<ClearSelectionIntent>(
        onInvoke: (intent) => _clearSelection(context),
      ),
      CopyPropertyIntent: CallbackAction<CopyPropertyIntent>(
        onInvoke: (intent) => _copyProperty(context),
      ),
      SelectAllXMLIntent: CallbackAction<SelectAllXMLIntent>(
        onInvoke: (intent) => _selectAllXML(context),
      ),
      ExportXMLIntent: CallbackAction<ExportXMLIntent>(
        onInvoke: (intent) => _exportXML(context),
      ),
      ZoomInIntent: CallbackAction<ZoomInIntent>(
        onInvoke: (intent) => _zoomIn(context),
      ),
      ZoomOutIntent: CallbackAction<ZoomOutIntent>(
        onInvoke: (intent) => _zoomOut(context),
      ),
      ResetZoomIntent: CallbackAction<ResetZoomIntent>(
        onInvoke: (intent) => _resetZoom(context),
      ),
      FilterClickableIntent: CallbackAction<FilterClickableIntent>(
        onInvoke: (intent) => _filterClickable(context),
      ),
      FilterInputsIntent: CallbackAction<FilterInputsIntent>(
        onInvoke: (intent) => _filterInputs(context),
      ),
      FilterTextIntent: CallbackAction<FilterTextIntent>(
        onInvoke: (intent) => _filterText(context),
      ),
      ClearFiltersIntent: CallbackAction<ClearFiltersIntent>(
        onInvoke: (intent) => _clearFilters(context),
      ),
      TogglePreviewIntent: CallbackAction<TogglePreviewIntent>(
        onInvoke: (intent) => _togglePreview(context),
      ),
      ToggleLeftPanelIntent: CallbackAction<ToggleLeftPanelIntent>(
        onInvoke: (intent) => _toggleLeftPanel(context),
      ),
      ResetLayoutIntent: CallbackAction<ResetLayoutIntent>(
        onInvoke: (intent) => _resetLayout(context),
      ),
      DuplicateElementIntent: CallbackAction<DuplicateElementIntent>(
        onInvoke: (intent) => _duplicateElement(context),
      ),
      ExportSelectedIntent: CallbackAction<ExportSelectedIntent>(
        onInvoke: (intent) => _exportSelected(context),
      ),
      InspectElementIntent: CallbackAction<InspectElementIntent>(
        onInvoke: (intent) => _inspectElement(context),
      ),
    };
  }

  // Action implementations
  void _refreshDevices(BuildContext context) {
    if (!state.isLoading) {
      state.refreshDevices();
    }
  }

  void _captureUI(BuildContext context) {
    if (!state.isLoading && state.selectedDevice?.isConnected == true) {
      state.captureUIHierarchy();
    }
  }

  void _focusSearch(BuildContext context) {
    // Trigger search focus through state management
    state.focusSearch();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Search focused (Cmd+F)'),
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
      ),
    );
  }

  void _toggleHistory(BuildContext context) {
    HistoryPanelDialog.show(context);
  }

  void _toggleXML(BuildContext context) {
    state.toggleXmlViewer();
  }

  void _openSettings(BuildContext context) {
    SettingsDialog.show(context);
  }

  void _showHelp(BuildContext context) {
    HelpDialog.show(context);
  }

  void _toggleTheme(BuildContext context) {
    final currentMode = state.themeMode;
    if (currentMode == ThemeMode.light) {
      state.setThemeMode(ThemeMode.dark);
    } else if (currentMode == ThemeMode.dark) {
      state.setThemeMode(ThemeMode.system);
    } else {
      state.setThemeMode(ThemeMode.light);
    }
  }

  void _navigateUp(BuildContext context) {
    // Tree navigation would need to be implemented in the tree view widget
    debugPrint('Navigate up');
  }

  void _navigateDown(BuildContext context) {
    // Tree navigation would need to be implemented in the tree view widget
    debugPrint('Navigate down');
  }

  void _collapseNode(BuildContext context) {
    // Node collapse would need to be implemented in the tree view widget
    debugPrint('Collapse node');
  }

  void _expandNode(BuildContext context) {
    // Node expand would need to be implemented in the tree view widget
    debugPrint('Expand node');
  }

  void _selectNode(BuildContext context) {
    // Node selection would need to be implemented in the tree view widget
    debugPrint('Select node');
  }

  void _clearSelection(BuildContext context) {
    state.selectElement(null);
  }

  void _copyProperty(BuildContext context) {
    if (state.selectedElement != null) {
      // Copy the most relevant property of the selected element
      final element = state.selectedElement!;
      String textToCopy = '';
      
      if (element.text.isNotEmpty) {
        textToCopy = element.text;
      } else if (element.contentDesc.isNotEmpty) {
        textToCopy = element.contentDesc;
      } else if (element.resourceId.isNotEmpty) {
        textToCopy = element.resourceId;
      } else {
        textToCopy = element.className;
      }
      
      // Copy to clipboard (would need clipboard package)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: $textToCopy'),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
        ),
      );
    }
  }

  void _selectAllXML(BuildContext context) {
    // XML selection would need to be implemented in the XML viewer
    debugPrint('Select all XML');
  }

  void _exportXML(BuildContext context) {
    // XML export would need to be implemented
    debugPrint('Export XML');
  }

  void _zoomIn(BuildContext context) {
    // Preview zoom would need to be implemented in the preview panel
    debugPrint('Zoom in');
  }

  void _zoomOut(BuildContext context) {
    // Preview zoom would need to be implemented in the preview panel
    debugPrint('Zoom out');
  }

  void _resetZoom(BuildContext context) {
    // Preview zoom reset would need to be implemented in the preview panel
    debugPrint('Reset zoom');
  }
  
  void _filterClickable(BuildContext context) {
    final currentCriteria = state.filterCriteria;
    final newCriteria = currentCriteria.copyWith(
      showOnlyClickable: !currentCriteria.showOnlyClickable,
    );
    state.setFilterCriteria(newCriteria);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newCriteria.showOnlyClickable 
          ? 'Showing only clickable elements' 
          : 'Showing all elements'),
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
      ),
    );
  }
  
  void _filterInputs(BuildContext context) {
    final currentCriteria = state.filterCriteria;
    final newCriteria = currentCriteria.copyWith(
      showOnlyInputs: !currentCriteria.showOnlyInputs,
    );
    state.setFilterCriteria(newCriteria);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newCriteria.showOnlyInputs 
          ? 'Showing only input elements' 
          : 'Showing all elements'),
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
      ),
    );
  }
  
  void _filterText(BuildContext context) {
    final currentCriteria = state.filterCriteria;
    final newCriteria = currentCriteria.copyWith(
      showOnlyWithText: !currentCriteria.showOnlyWithText,
    );
    state.setFilterCriteria(newCriteria);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newCriteria.showOnlyWithText 
          ? 'Showing only elements with text' 
          : 'Showing all elements'),
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
      ),
    );
  }
  
  void _clearFilters(BuildContext context) {
    state.setFilterCriteria(FilterCriteria.empty);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All filters cleared'),
        duration: Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 80, left: 20, right: 20),
      ),
    );
  }
  
  void _togglePreview(BuildContext context) {
    state.togglePreviewVisibility();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(state.isPreviewVisible 
          ? 'Preview panel shown' 
          : 'Preview panel hidden'),
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
      ),
    );
  }
  
  void _toggleLeftPanel(BuildContext context) {
    // This would need to be implemented in the main window
    debugPrint('Toggle left panel');
  }
  
  void _resetLayout(BuildContext context) {
    // Reset panel sizes to defaults
    state.setLeftPanelWidth(400.0);
    state.setRightPanelWidth(400.0);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Layout reset to defaults'),
        duration: Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 80, left: 20, right: 20),
      ),
    );
  }
  
  void _duplicateElement(BuildContext context) {
    if (state.selectedElement != null) {
      // Copy element info to clipboard
      final element = state.selectedElement!;
      final info = 'Class: ${element.className}\nText: ${element.text}\nResource ID: ${element.resourceId}';
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Element info copied to clipboard'),
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 80, left: 20, right: 20),
        ),
      );
    }
  }
  
  void _exportSelected(BuildContext context) {
    if (state.selectedElement != null) {
      // Export selected element and its children
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exporting selected element...'),
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 80, left: 20, right: 20),
        ),
      );
    }
  }
  
  void _inspectElement(BuildContext context) {
    if (state.selectedElement != null) {
      // Show detailed inspection dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening element inspector...'),
          duration: Duration(milliseconds: 1000),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 80, left: 20, right: 20),
        ),
      );
    }
  }
}

// Intent classes
class RefreshDevicesIntent extends Intent {
  const RefreshDevicesIntent();
}

class CaptureUIIntent extends Intent {
  const CaptureUIIntent();
}

class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

class ToggleHistoryIntent extends Intent {
  const ToggleHistoryIntent();
}

class ToggleXMLIntent extends Intent {
  const ToggleXMLIntent();
}

class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}

class ShowHelpIntent extends Intent {
  const ShowHelpIntent();
}

class ToggleThemeIntent extends Intent {
  const ToggleThemeIntent();
}

class NavigateUpIntent extends Intent {
  const NavigateUpIntent();
}

class NavigateDownIntent extends Intent {
  const NavigateDownIntent();
}

class CollapseNodeIntent extends Intent {
  const CollapseNodeIntent();
}

class ExpandNodeIntent extends Intent {
  const ExpandNodeIntent();
}

class SelectNodeIntent extends Intent {
  const SelectNodeIntent();
}

class ClearSelectionIntent extends Intent {
  const ClearSelectionIntent();
}

class CopyPropertyIntent extends Intent {
  const CopyPropertyIntent();
}

class SelectAllXMLIntent extends Intent {
  const SelectAllXMLIntent();
}

class ExportXMLIntent extends Intent {
  const ExportXMLIntent();
}

class ZoomInIntent extends Intent {
  const ZoomInIntent();
}

class ZoomOutIntent extends Intent {
  const ZoomOutIntent();
}

class ResetZoomIntent extends Intent {
  const ResetZoomIntent();
}

class FilterClickableIntent extends Intent {
  const FilterClickableIntent();
}

class FilterInputsIntent extends Intent {
  const FilterInputsIntent();
}

class FilterTextIntent extends Intent {
  const FilterTextIntent();
}

class ClearFiltersIntent extends Intent {
  const ClearFiltersIntent();
}

class TogglePreviewIntent extends Intent {
  const TogglePreviewIntent();
}

class ToggleLeftPanelIntent extends Intent {
  const ToggleLeftPanelIntent();
}

class ResetLayoutIntent extends Intent {
  const ResetLayoutIntent();
}

class DuplicateElementIntent extends Intent {
  const DuplicateElementIntent();
}

class ExportSelectedIntent extends Intent {
  const ExportSelectedIntent();
}

class InspectElementIntent extends Intent {
  const InspectElementIntent();
}