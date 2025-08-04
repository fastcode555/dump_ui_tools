import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../panels/tree_view_panel.dart';
import '../panels/property_panel.dart';
import '../panels/preview_panel.dart';
import '../panels/xml_viewer_panel.dart';
import '../../controllers/ui_analyzer_state.dart';
import '../../utils/keyboard_shortcuts.dart';
import '../../services/user_preferences.dart';
import 'custom_app_bar.dart';
import 'loading_overlay.dart';
import 'onboarding_overlay.dart';
import 'status_bar.dart';

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> with WindowListener {
  // Panel size ratios
  double _leftPanelRatio = 0.25; // 25% for UI hierarchy
  double _middlePanelRatio = 0.25; // 25% for properties
  double _xmlPanelHeight = 200.0; // Fixed height for XML panel
  // Right panel (preview) takes remaining space (about 50% minus resizers)

  // Minimum panel sizes
  static const double _minPanelWidth = 200.0;
  static const double _minPanelHeight = 150.0;
  
  // Performance optimization flags
  bool _isResizing = false;
  DateTime? _lastResizeTime;
  
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    // Don't load panel sizes here - will be done in didChangeDependencies
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe to access MediaQuery here
    _loadPanelSizes();
  }
  
  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }
  
  /// Load saved panel sizes from preferences
  void _loadPanelSizes() {
    try {
      final mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery == null) return;
      
      final screenWidth = mediaQuery.size.width;
      final leftWidth = UserPreferences.getLeftPanelWidth();
      final rightWidth = UserPreferences.getRightPanelWidth();
      final xmlHeight = UserPreferences.getXmlPanelHeight();
      
      if (mounted) {
        setState(() {
          _leftPanelRatio = leftWidth / screenWidth;
          _middlePanelRatio = rightWidth / screenWidth; // Reuse rightWidth for middle panel
          _xmlPanelHeight = xmlHeight;
        });
      }
    } catch (e) {
      // If MediaQuery is not available, use default values
      debugPrint('Could not load panel sizes: $e');
    }
  }
  
  /// Save panel sizes to preferences with debouncing
  void _savePanelSizes() {
    _lastResizeTime = DateTime.now();
    
    // Debounce saving to avoid excessive writes
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_lastResizeTime != null && 
          DateTime.now().difference(_lastResizeTime!).inMilliseconds >= 500 &&
          mounted) {
        try {
          final mediaQuery = MediaQuery.maybeOf(context);
          if (mediaQuery == null) return;
          
          final screenWidth = mediaQuery.size.width;
          final leftWidth = screenWidth * _leftPanelRatio;
          final middleWidth = screenWidth * _middlePanelRatio;
          
          UserPreferences.savePanelSizes(
            leftPanelWidth: leftWidth,
            rightPanelWidth: middleWidth, // Save middle panel width as rightPanelWidth
            xmlPanelHeight: _xmlPanelHeight,
          );
        } catch (e) {
          debugPrint('Could not save panel sizes: $e');
        }
      }
    });
  }
  
  @override
  void onWindowResize() {
    // Handle window resize events
    if (mounted) {
      setState(() {
        _isResizing = true;
      });
      
      // Stop resize indicator after a delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _isResizing = false;
          });
        }
      });
    }
  }
  
  @override
  void onWindowMoved() {
    // Save window position
    windowManager.getPosition().then((position) {
      UserPreferences.setWindowX(position.dx);
      UserPreferences.setWindowY(position.dy);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UIAnalyzerState>(
      builder: (context, state, child) {
        return KeyboardShortcuts(
          state: state,
          child: OnboardingOverlay(
            child: Scaffold(
          appBar: const CustomAppBar(),
          body: LoadingOverlay(
            isLoading: state.isLoading,
            message: state.loadingMessage,
            child: Stack(
              children: [
                Column(
                  children: [
                    // Main content area with resizable panels
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left panel - UI Hierarchy (Tree view)
                          SizedBox(
                            width: (MediaQuery.of(context).size.width * _leftPanelRatio).clamp(200.0, double.infinity),
                            child: const TreeViewPanel(),
                          ),
                          
                          // First vertical resizer (between hierarchy and properties)
                          _buildVerticalResizer(isFirstResizer: true),
                          
                          // Middle panel - Properties
                          SizedBox(
                            width: (MediaQuery.of(context).size.width * _middlePanelRatio).clamp(200.0, double.infinity),
                            child: const PropertyPanel(),
                          ),
                          
                          // Second vertical resizer (between properties and preview)
                          _buildVerticalResizer(isFirstResizer: false),
                          
                          // Right panel - Screen Preview
                          Expanded(
                            child: const PreviewPanel(),
                          ),
                        ],
                      ),
                    ),
                    
                    // XML viewer panel (collapsible bottom panel)
                    AnimatedSwitcher(
                      duration: state.animationDuration,
                      transitionBuilder: (child, animation) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 1),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          )),
                          child: child,
                        );
                      },
                      child: state.isXmlViewerVisible
                          ? Column(
                              key: const ValueKey('xml_panel'),
                              children: [
                                _buildXmlPanelResizer(),
                                SizedBox(
                                  height: _xmlPanelHeight,
                                  child: XMLViewerPanel(
                                    onClose: () {
                                      state.setXmlViewerVisible(false);
                                    },
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                    ),
                    
                    // Status bar at the bottom
                    const StatusBar(),
                  ],
                ),
                
                // Specialized loading indicator for UI capture
                if (state.isLoading && state.loadingMessage.contains('UI'))
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: UICaptureLoadingIndicator(
                        currentStep: state.loadingMessage,
                        progress: state.loadingProgress,
                        steps: const [
                          '检查设备连接',
                          '清理旧文件',
                          '执行UI dump',
                          '验证dump文件',
                          '下载XML文件',
                        ],
                        currentStepIndex: state.currentStep - 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Floating action button to toggle XML panel
          floatingActionButton: FloatingActionButton.small(
            onPressed: () {
              state.toggleXmlViewer();
            },
            tooltip: state.isXmlViewerVisible ? 'Hide XML' : 'Show XML',
            child: Icon(state.isXmlViewerVisible ? Icons.code_off : Icons.code),
          ),
        ),
        ),
        );
      },
    );
  }

  Widget _buildVerticalResizer({required bool isFirstResizer}) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isResizing = true;
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isResizing = false;
          });
          _savePanelSizes();
        },
        onPanUpdate: (details) {
          setState(() {
            final screenWidth = MediaQuery.of(context).size.width;
            final deltaRatio = details.delta.dx / screenWidth;
            
            if (isFirstResizer) {
              // First resizer: adjust left panel ratio
              final newLeftRatio = _leftPanelRatio + deltaRatio;
              
              // Ensure minimum panel sizes
              final minLeftRatio = _minPanelWidth / screenWidth;
              final maxLeftRatio = 1.0 - (2 * _minPanelWidth / screenWidth) - _middlePanelRatio;
              
              _leftPanelRatio = newLeftRatio.clamp(minLeftRatio, maxLeftRatio);
            } else {
              // Second resizer: adjust middle panel ratio
              final newMiddleRatio = _middlePanelRatio + deltaRatio;
              
              // Ensure minimum panel sizes
              final minMiddleRatio = _minPanelWidth / screenWidth;
              final maxMiddleRatio = 1.0 - _leftPanelRatio - (_minPanelWidth / screenWidth);
              
              _middlePanelRatio = newMiddleRatio.clamp(minMiddleRatio, maxMiddleRatio);
            }
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: _isResizing ? 0 : 200),
          width: _isResizing ? 6 : 4,
          color: _isResizing 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).dividerColor,
          child: Center(
            child: AnimatedContainer(
              duration: Duration(milliseconds: _isResizing ? 0 : 200),
              width: _isResizing ? 3 : 2,
              height: _isResizing ? 60 : 40,
              decoration: BoxDecoration(
                color: _isResizing 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildXmlPanelResizer() {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isResizing = true;
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isResizing = false;
          });
          _savePanelSizes();
        },
        onPanUpdate: (details) {
          setState(() {
            final newHeight = _xmlPanelHeight - details.delta.dy;
            _xmlPanelHeight = newHeight.clamp(100.0, 400.0);
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: _isResizing ? 0 : 200),
          height: _isResizing ? 6 : 4,
          color: _isResizing 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).dividerColor,
          child: Center(
            child: AnimatedContainer(
              duration: Duration(milliseconds: _isResizing ? 0 : 200),
              width: _isResizing ? 60 : 40,
              height: _isResizing ? 3 : 2,
              decoration: BoxDecoration(
                color: _isResizing 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}