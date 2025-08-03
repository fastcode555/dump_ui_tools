# Android UI Analyzer Tool - Developer Guide

## Architecture Overview

The Android UI Analyzer Tool is built using Flutter with a clean architecture pattern, separating concerns across multiple layers.

### Project Structure

```
lib/
├── main.dart                 # Application entry point
├── controllers/              # State management and business logic
│   ├── ui_analyzer_state.dart
│   ├── search_controller.dart
│   └── filter_controller.dart
├── models/                   # Data models and entities
│   ├── ui_element.dart
│   ├── android_device.dart
│   └── filter_criteria.dart
├── services/                 # External service integrations
│   ├── adb_service.dart
│   ├── xml_parser.dart
│   ├── file_manager.dart
│   └── user_preferences.dart
├── ui/                       # User interface components
│   ├── panels/              # Main UI panels
│   ├── widgets/             # Reusable components
│   ├── dialogs/             # Modal dialogs
│   └── themes/              # Theme configuration
└── utils/                   # Utility functions and helpers
    ├── error_handler.dart
    ├── keyboard_shortcuts.dart
    └── integration_verifier.dart
```

## Core Components

### State Management

The application uses Provider for state management with a centralized `UIAnalyzerState` class:

```dart
class UIAnalyzerState extends ChangeNotifier {
  // Core state properties
  UIElement? _rootElement;
  AndroidDevice? _selectedDevice;
  FilterCriteria _filterCriteria;
  
  // State management methods
  void setUIHierarchy(UIElement root) { /* ... */ }
  void selectDevice(AndroidDevice device) { /* ... */ }
  void updateFilterCriteria(FilterCriteria criteria) { /* ... */ }
}
```

### Data Models

#### UIElement
Represents a single UI element from the Android hierarchy:

```dart
class UIElement {
  final String id;
  final int depth;
  final String text;
  final String contentDesc;
  final String className;
  final String resourceId;
  final bool clickable;
  final bool enabled;
  final Rect bounds;
  final List<UIElement> children;
  final UIElement? parent;
}
```

#### AndroidDevice
Represents a connected Android device:

```dart
class AndroidDevice {
  final String id;
  final String name;
  final DeviceStatus status;
  final String model;
  final String androidVersion;
}
```

### Services Layer

#### ADBService
Handles all Android Debug Bridge interactions:

```dart
class ADBService {
  Future<List<AndroidDevice>> getConnectedDevices();
  Future<String> dumpUIHierarchy(String deviceId);
  Future<bool> isDeviceConnected(String deviceId);
  Future<String> getCurrentActivity(String deviceId);
}
```

#### XMLParser
Processes UI dump XML files:

```dart
class XMLParser {
  Future<UIElement> parseXMLFile(String filePath);
  Future<UIElement> parseXMLString(String xmlContent);
  List<UIElement> flattenHierarchy(UIElement root);
  String formatXMLWithHighlight(String xmlContent);
}
```

#### FileManager
Manages file operations and history:

```dart
class FileManager {
  Future<String> saveUIdump(String content, {String? filename});
  Future<List<String>> getHistoryFiles();
  Future<String> readFile(String filePath);
  Future<void> deleteFile(String filePath);
  Future<String> exportToXML(UIElement root, String filePath);
}
```

## UI Architecture

### Panel System

The application uses a flexible panel system with the following main components:

1. **TreeViewPanel**: Displays UI hierarchy in tree format
2. **PropertyPanel**: Shows detailed element properties
3. **PreviewPanel**: Visual representation of device screen
4. **XMLViewerPanel**: Syntax-highlighted XML display

### Widget Hierarchy

```
MaterialApp
└── MainWindow
    ├── CustomAppBar
    │   ├── DeviceSelector
    │   ├── CaptureButton
    │   └── ThemeToggle
    └── PanelLayout
        ├── TreeViewPanel
        │   ├── SearchBar
        │   ├── FilterChips
        │   └── VirtualTreeView
        ├── PropertyPanel
        │   └── PropertyList
        ├── PreviewPanel
        │   └── InteractiveCanvas
        └── XMLViewerPanel
            └── HighlightedCodeView
```

## Development Setup

### Prerequisites

- Flutter SDK 3.7.2 or later
- Dart SDK 2.19.0 or later
- macOS development environment
- Xcode (for macOS builds)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd android-ui-analyzer
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run -d macos
```

### Development Tools

#### Code Analysis
```bash
flutter analyze
```

#### Testing
```bash
flutter test
flutter test --coverage
```

#### Building
```bash
flutter build macos --release
```

## Testing Strategy

### Test Structure

```
test/
├── controllers/          # State management tests
├── models/              # Data model tests
├── services/            # Service layer tests
├── ui/                  # Widget tests
└── integration/         # End-to-end tests
```

### Test Categories

#### Unit Tests
- Model validation and behavior
- Service method functionality
- Utility function correctness

#### Widget Tests
- UI component rendering
- User interaction handling
- State change responses

#### Integration Tests
- Complete user workflows
- Service integration
- Error handling scenarios

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/xml_parser_test.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Performance Considerations

### Memory Management

1. **Large XML Files**: Use streaming parsers for files > 10MB
2. **UI Elements**: Implement lazy loading for large hierarchies
3. **History Files**: Automatic cleanup of old files

### UI Performance

1. **Virtual Scrolling**: Used in tree view for large datasets
2. **Debounced Search**: Prevents excessive filtering operations
3. **Cached Rendering**: Reuse widgets where possible

### Optimization Techniques

```dart
// Example: Lazy loading tree nodes
class LazyTreeNode extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UIElement>>(
      future: _loadChildrenWhenNeeded(),
      builder: (context, snapshot) {
        // Render only when needed
      },
    );
  }
}
```

## Error Handling

### Exception Hierarchy

```dart
abstract class UIAnalyzerException implements Exception {
  final String message;
  final String? details;
}

class ADBException extends UIAnalyzerException { /* ... */ }
class XMLParseException extends UIAnalyzerException { /* ... */ }
class FileOperationException extends UIAnalyzerException { /* ... */ }
```

### Error Recovery

1. **Graceful Degradation**: Continue operation when possible
2. **User Feedback**: Clear error messages with solutions
3. **Retry Mechanisms**: Automatic retry for transient failures
4. **Logging**: Comprehensive error logging for debugging

## Extending the Application

### Adding New Filters

1. Extend `FilterCriteria` model:
```dart
class FilterCriteria {
  // Add new filter property
  final bool showCustomElements;
  
  // Update constructor and methods
}
```

2. Update `FilterController`:
```dart
class FilterController {
  void toggleCustomFilter() {
    // Implement filter logic
  }
}
```

3. Add UI components:
```dart
class CustomFilterChip extends StatelessWidget {
  // Implement filter UI
}
```

### Adding New Export Formats

1. Extend `FileManager`:
```dart
Future<String> exportToJSON(UIElement root, String filePath) {
  // Implement JSON export
}
```

2. Update export dialog:
```dart
class ExportDialog extends StatefulWidget {
  // Add new format option
}
```

### Custom Themes

1. Extend `AppTheme`:
```dart
class AppTheme {
  static ThemeData customTheme() {
    // Define custom theme
  }
}
```

2. Update theme selector:
```dart
class ThemeSelector extends StatefulWidget {
  // Add custom theme option
}
```

## Build and Deployment

### Build Configuration

#### Debug Build
```bash
flutter build macos --debug
```

#### Release Build
```bash
flutter build macos --release --split-debug-info=debug-symbols
```

### Code Signing (macOS)

1. Configure signing in `macos/Runner.xcodeproj`
2. Set development team and bundle identifier
3. Enable hardened runtime for distribution

### Distribution

#### Development Distribution
- Use debug builds for internal testing
- Include debug symbols for crash analysis

#### Production Distribution
- Use release builds with optimizations
- Strip debug information
- Code sign for macOS distribution
- Create installer package if needed

## Debugging

### Common Debug Scenarios

#### ADB Connection Issues
```dart
// Enable ADB debugging
class ADBService {
  static bool debugMode = true;
  
  Future<ProcessResult> _runADBCommand(List<String> args) async {
    if (debugMode) {
      print('ADB Command: adb ${args.join(' ')}');
    }
    // ... rest of implementation
  }
}
```

#### XML Parsing Problems
```dart
// Add parsing debug information
class XMLParser {
  UIElement _parseNode(XmlElement element, int depth) {
    try {
      // Parsing logic
    } catch (e) {
      print('Parse error at depth $depth: $e');
      print('Element: ${element.toString()}');
      rethrow;
    }
  }
}
```

#### Performance Profiling
```bash
# Run with performance overlay
flutter run -d macos --profile

# Use Flutter Inspector
flutter inspector
```

## Contributing

### Code Style

- Follow Dart style guide
- Use meaningful variable names
- Add documentation comments for public APIs
- Keep functions focused and small

### Pull Request Process

1. Create feature branch from main
2. Implement changes with tests
3. Update documentation
4. Submit pull request with description
5. Address review feedback

### Commit Guidelines

```
type(scope): description

feat(ui): add new filter panel
fix(adb): handle device disconnection
docs(readme): update installation instructions
test(parser): add XML validation tests
```

## API Reference

### Core Classes

#### UIAnalyzerState
Main application state manager

**Methods:**
- `setUIHierarchy(UIElement root)`: Set current UI hierarchy
- `selectDevice(AndroidDevice device)`: Select active device
- `updateFilterCriteria(FilterCriteria criteria)`: Update filters

#### SearchController
Handles search functionality

**Methods:**
- `search(String query)`: Perform search
- `clearSearch()`: Clear current search
- `getSearchResults()`: Get current results

#### FilterController
Manages element filtering

**Methods:**
- `applyFilter(FilterCriteria criteria)`: Apply filter
- `clearFilters()`: Remove all filters
- `getFilteredElements()`: Get filtered results

### Utility Functions

#### Error Handling
```dart
void handleError(BuildContext context, Exception error) {
  // Display user-friendly error dialog
}
```

#### File Operations
```dart
Future<String> selectFile({String? initialDirectory}) {
  // Open file picker dialog
}
```

## Troubleshooting Development Issues

### Common Build Errors

#### Missing Dependencies
```bash
flutter pub get
flutter pub deps
```

#### Platform Issues
```bash
flutter clean
flutter pub get
flutter build macos
```

#### Code Generation
```bash
flutter packages pub run build_runner build
```

### Runtime Debugging

#### Enable Debug Logging
```dart
// In main.dart
void main() {
  if (kDebugMode) {
    Logger.root.level = Level.ALL;
  }
  runApp(MyApp());
}
```

#### Memory Leaks
```bash
flutter run --profile
# Use Flutter Inspector to monitor memory
```

---

*This developer guide provides comprehensive information for contributing to and extending the Android UI Analyzer Tool. For user-facing documentation, see the User Guide.*