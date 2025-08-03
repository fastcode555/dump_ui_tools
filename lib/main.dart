import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'ui/themes/app_theme.dart';
import 'ui/widgets/main_window.dart';
import 'ui/widgets/performance_monitor.dart';
import 'ui/widgets/status_bar.dart';
import 'controllers/ui_analyzer_state.dart';
import 'integration/app_integration.dart';
import 'services/user_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize user preferences first
  await UserPreferences.initialize();
  
  // Configure window for desktop with saved preferences
  await windowManager.ensureInitialized();
  
  final savedWidth = UserPreferences.getWindowWidth();
  final savedHeight = UserPreferences.getWindowHeight();
  final savedX = UserPreferences.getWindowX();
  final savedY = UserPreferences.getWindowY();
  final isMaximized = UserPreferences.getIsWindowMaximized();
  
  WindowOptions windowOptions = WindowOptions(
    size: Size(savedWidth, savedHeight),
    minimumSize: const Size(800, 600),
    center: savedX == null || savedY == null,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Android UI Analyzer',
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    // Restore window position if saved
    if (savedX != null && savedY != null) {
      await windowManager.setPosition(Offset(savedX, savedY));
    }
    
    // Restore maximized state
    if (isMaximized) {
      await windowManager.maximize();
    }
    
    await windowManager.show();
    await windowManager.focus();
  });
  
  // Initialize application state and integration
  final uiState = UIAnalyzerState();
  final appIntegration = AppIntegration();
  
  // Initialize all components
  await appIntegration.initialize(uiState);
  
  // Load user preferences into state
  await uiState.loadUserPreferences();
  
  runApp(
    ChangeNotifierProvider.value(
      value: uiState,
      child: const UIAnalyzerApp(),
    ),
  );
}

class UIAnalyzerApp extends StatelessWidget {
  const UIAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UIAnalyzerState>(
      builder: (context, state, child) {
        return MaterialApp(
          title: 'Android UI Analyzer',
          debugShowCheckedModeBanner: false,
          navigatorKey: NavigationService.navigatorKey,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: state.themeMode,
          home: DebugPerformanceOverlay(
            child: const MainWindow(),
          ),
        );
      },
    );
  }
}


