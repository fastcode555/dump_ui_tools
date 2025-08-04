import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/ui_element.dart';
import '../models/android_device.dart';
import '../models/filter_criteria.dart';
import '../services/adb_service.dart';
import '../services/xml_parser.dart';
import '../services/file_manager.dart';
import '../services/user_preferences.dart';

/// Global state management for the UI Analyzer application
/// Manages current UI hierarchy, selected device, filter criteria, and other app state
class UIAnalyzerState extends ChangeNotifier {
  // Private fields
  UIElement? _rootElement;
  List<UIElement> _flatElements = [];
  List<UIElement> _filteredElements = [];
  AndroidDevice? _selectedDevice;
  List<AndroidDevice> _availableDevices = [];
  FilterCriteria _filterCriteria = FilterCriteria.empty;
  UIElement? _selectedElement;
  String _xmlContent = '';
  bool _isLoading = false;
  String? _errorMessage;
  double? _loadingProgress;
  int _currentStep = 0;
  int _totalSteps = 0;
  String _currentStepName = '';
  bool _isXmlViewerVisible = false;
  bool _isDarkMode = false;
  ThemeMode _themeMode = ThemeMode.system;
  
  // Search and filter state
  String _searchQuery = '';
  List<UIElement> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounceTimer;
  bool _shouldFocusSearch = false;
  
  // Performance settings
  int _searchDebounceMs = 300;
  int _animationDurationMs = 200;
  
  // UI state
  double _leftPanelWidth = 400.0;
  double _rightPanelWidth = 400.0;
  bool _isPreviewVisible = true;
  
  // History state
  List<String> _historyFiles = [];
  String? _currentHistoryFile;
  
  // Getters for UI hierarchy
  UIElement? get rootElement => _rootElement;
  List<UIElement> get flatElements => List.unmodifiable(_flatElements);
  List<UIElement> get filteredElements => List.unmodifiable(_filteredElements);
  bool get hasUIHierarchy => _rootElement != null;
  int get totalElementCount => _flatElements.length;
  int get filteredElementCount => _filteredElements.length;
  
  // Getters for device management
  AndroidDevice? get selectedDevice => _selectedDevice;
  List<AndroidDevice> get availableDevices => List.unmodifiable(_availableDevices);
  bool get hasSelectedDevice => _selectedDevice != null;
  bool get isDeviceConnected => _selectedDevice?.isConnected ?? false;
  
  // Getters for filter and search
  FilterCriteria get filterCriteria => _filterCriteria;
  String get searchQuery => _searchQuery;
  List<UIElement> get searchResults => List.unmodifiable(_searchResults);
  bool get hasActiveFilters => _filterCriteria.hasActiveFilters;
  bool get isSearching => _isSearching;
  bool get hasSearchResults => _searchResults.isNotEmpty;
  
  // Getters for selected element
  UIElement? get selectedElement => _selectedElement;
  bool get hasSelectedElement => _selectedElement != null;
  
  // Getters for XML content
  String get xmlContent => _xmlContent;
  bool get hasXmlContent => _xmlContent.isNotEmpty;
  bool get isXmlViewerVisible => _isXmlViewerVisible;
  
  // Getters for app state
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  double? get loadingProgress => _loadingProgress;
  int get currentStep => _currentStep;
  int get totalSteps => _totalSteps;
  String get currentStepName => _currentStepName;
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _themeMode;
  String _loadingMessage = '';
  String get loadingMessage => _loadingMessage;
  
  // Getters for UI layout
  double get leftPanelWidth => _leftPanelWidth;
  double get rightPanelWidth => _rightPanelWidth;
  bool get isPreviewVisible => _isPreviewVisible;
  
  // Getters for history
  List<String> get historyFiles => List.unmodifiable(_historyFiles);
  String? get currentHistoryFile => _currentHistoryFile;
  bool get hasHistoryFiles => _historyFiles.isNotEmpty;
  
  /// Set the root UI element and update related state
  void setUIHierarchy(UIElement? root, {String? xmlContent}) {
    _rootElement = root;
    _xmlContent = xmlContent ?? '';
    
    if (root != null) {
      // Generate flat list of all elements
      _flatElements = [root, ...root.getAllDescendants()];
      
      // Apply current filters
      _applyFilters();
      
      // Clear any previous error
      _errorMessage = null;
    } else {
      _flatElements = [];
      _filteredElements = [];
      _searchResults = [];
      _selectedElement = null;
    }
    
    notifyListeners();
  }
  
  /// Set the list of available devices
  void setAvailableDevices(List<AndroidDevice> devices) {
    _availableDevices = List.from(devices);
    
    // If current selected device is not in the new list, clear selection
    if (_selectedDevice != null && 
        !devices.any((device) => device.id == _selectedDevice!.id)) {
      _selectedDevice = null;
    }
    
    notifyListeners();
  }
  
  /// Select a device
  void selectDevice(AndroidDevice? device) {
    if (_selectedDevice != device) {
      _selectedDevice = device;
      
      // Save last selected device
      UserPreferences.setLastSelectedDevice(device?.id);
      
      // Clear UI hierarchy when switching devices
      if (device == null) {
        setUIHierarchy(null);
      }
      
      notifyListeners();
    }
  }
  
  /// Update device status
  void updateDeviceStatus(String deviceId, DeviceStatus status) {
    final deviceIndex = _availableDevices.indexWhere((d) => d.id == deviceId);
    if (deviceIndex != -1) {
      _availableDevices[deviceIndex] = _availableDevices[deviceIndex].copyWithStatus(status);
      
      // Update selected device if it matches
      if (_selectedDevice?.id == deviceId) {
        _selectedDevice = _availableDevices[deviceIndex];
      }
      
      notifyListeners();
    }
  }
  
  /// Set filter criteria and apply filters
  void setFilterCriteria(FilterCriteria criteria) {
    if (_filterCriteria != criteria) {
      _filterCriteria = criteria;
      _applyFilters();
      notifyListeners();
    }
  }
  
  /// Update search query with debouncing for better performance
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      
      // Cancel previous timer
      _searchDebounceTimer?.cancel();
      
      // Set up debounced search
      _searchDebounceTimer = Timer(Duration(milliseconds: _searchDebounceMs), () {
        _performSearch();
        notifyListeners();
      });
      
      // Immediately notify for UI updates (like clearing results)
      if (query.isEmpty) {
        _searchResults = [];
        notifyListeners();
      }
    }
  }
  
  /// Select a UI element
  void selectElement(UIElement? element) {
    if (_selectedElement != element) {
      _selectedElement = element;
      notifyListeners();
    }
  }
  
  /// Set loading state with optional message and progress
  void setLoading(bool loading, [String message = '', double? progress]) {
    if (_isLoading != loading || _loadingMessage != message || _loadingProgress != progress) {
      _isLoading = loading;
      _loadingMessage = message;
      _loadingProgress = progress;
      
      // Clear error when starting to load
      if (loading) {
        _errorMessage = null;
      } else {
        // Clear progress when not loading
        _loadingProgress = null;
        _currentStep = 0;
        _totalSteps = 0;
        _currentStepName = '';
      }
      
      notifyListeners();
    }
  }
  
  /// Update loading progress
  void updateProgress(double progress, String message) {
    if (_loadingProgress != progress || _loadingMessage != message) {
      _loadingProgress = progress;
      _loadingMessage = message;
      notifyListeners();
    }
  }
  
  /// Update current step
  void updateStep(int currentStep, int totalSteps, String stepName) {
    if (_currentStep != currentStep || _totalSteps != totalSteps || _currentStepName != stepName) {
      _currentStep = currentStep;
      _totalSteps = totalSteps;
      _currentStepName = stepName;
      notifyListeners();
    }
  }
  
  /// Set error message
  void setError(String? error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      _isLoading = false; // Stop loading on error
      notifyListeners();
    }
  }
  
  /// Clear error message
  void clearError() {
    setError(null);
  }
  
  /// Set error from exception (for internal use)
  void setErrorFromException(dynamic exception) {
    if (exception != null) {
      setError(exception.toString());
    }
  }
  
  /// Toggle XML viewer visibility
  void toggleXmlViewer() {
    _isXmlViewerVisible = !_isXmlViewerVisible;
    notifyListeners();
  }
  
  /// Set XML viewer visibility
  void setXmlViewerVisible(bool visible) {
    if (_isXmlViewerVisible != visible) {
      _isXmlViewerVisible = visible;
      _saveUIPreferences(); // Auto-save
      notifyListeners();
    }
  }
  
  /// Toggle dark mode
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _themeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _saveThemePreference();
    notifyListeners();
  }
  
  /// Set dark mode
  void setDarkMode(bool darkMode) {
    if (_isDarkMode != darkMode) {
      _isDarkMode = darkMode;
      _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
      _saveThemePreference();
      notifyListeners();
    }
  }
  
  /// Set theme mode
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _isDarkMode = mode == ThemeMode.dark;
      _saveThemePreference();
      notifyListeners();
    }
  }
  
  /// Load all user preferences from storage
  Future<void> loadUserPreferences() async {
    try {
      // Load theme preferences
      _themeMode = UserPreferences.getThemeMode();
      _isDarkMode = _themeMode == ThemeMode.dark;
      
      // Load panel sizes
      _leftPanelWidth = UserPreferences.getLeftPanelWidth();
      _rightPanelWidth = UserPreferences.getRightPanelWidth();
      
      // Load UI preferences
      _isPreviewVisible = UserPreferences.getIsPreviewVisible();
      _isXmlViewerVisible = UserPreferences.getAutoShowXmlViewer();
      
      // Load performance settings
      _searchDebounceMs = UserPreferences.getSearchDebounceMs();
      _animationDurationMs = UserPreferences.getAnimationDurationMs();
      
      // Try to restore last selected device
      final lastDeviceId = UserPreferences.getLastSelectedDevice();
      if (lastDeviceId != null) {
        // This will be used when devices are loaded
        debugPrint('Last selected device: $lastDeviceId');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load user preferences: $e');
      // Continue with defaults
    }
  }
  
  /// Load theme preference from storage
  Future<void> loadThemePreference() async {
    try {
      _themeMode = UserPreferences.getThemeMode();
      _isDarkMode = _themeMode == ThemeMode.dark;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load theme preference: $e');
    }
  }

  /// Save theme preference to storage
  Future<void> _saveThemePreference() async {
    try {
      await UserPreferences.setThemeMode(_themeMode);
    } catch (e) {
      debugPrint('Failed to save theme preference: $e');
    }
  }
  
  /// Save panel sizes to storage
  Future<void> _savePanelSizes() async {
    try {
      await UserPreferences.savePanelSizes(
        leftPanelWidth: _leftPanelWidth,
        rightPanelWidth: _rightPanelWidth,
        xmlPanelHeight: 200.0, // This would need to be tracked separately
      );
    } catch (e) {
      debugPrint('Failed to save panel sizes: $e');
    }
  }
  
  /// Save UI preferences to storage
  Future<void> _saveUIPreferences() async {
    try {
      await UserPreferences.setIsPreviewVisible(_isPreviewVisible);
      await UserPreferences.setAutoShowXmlViewer(_isXmlViewerVisible);
    } catch (e) {
      debugPrint('Failed to save UI preferences: $e');
    }
  }
  
  /// Update panel widths
  void setLeftPanelWidth(double width) {
    if (_leftPanelWidth != width && width > 200 && width < 800) {
      _leftPanelWidth = width;
      _savePanelSizes(); // Auto-save
      notifyListeners();
    }
  }
  
  void setRightPanelWidth(double width) {
    if (_rightPanelWidth != width && width > 200 && width < 800) {
      _rightPanelWidth = width;
      _savePanelSizes(); // Auto-save
      notifyListeners();
    }
  }
  
  /// Toggle preview panel visibility
  void togglePreviewVisibility() {
    _isPreviewVisible = !_isPreviewVisible;
    _saveUIPreferences(); // Auto-save
    notifyListeners();
  }
  
  /// Set history files
  void setHistoryFiles(List<String> files) {
    _historyFiles = List.from(files);
    notifyListeners();
  }
  
  /// Set current history file
  void setCurrentHistoryFile(String? filePath) {
    if (_currentHistoryFile != filePath) {
      _currentHistoryFile = filePath;
      notifyListeners();
    }
  }
  
  /// Add a new history file
  void addHistoryFile(String filePath) {
    if (!_historyFiles.contains(filePath)) {
      _historyFiles.insert(0, filePath); // Add to beginning
      notifyListeners();
    }
  }
  
  /// Remove a history file
  void removeHistoryFile(String filePath) {
    if (_historyFiles.remove(filePath)) {
      if (_currentHistoryFile == filePath) {
        _currentHistoryFile = null;
      }
      notifyListeners();
    }
  }
  
  /// Clear all history files
  void clearHistoryFiles() {
    _historyFiles.clear();
    _currentHistoryFile = null;
    notifyListeners();
  }
  
  /// Apply current filter criteria to elements
  void _applyFilters() {
    if (!hasUIHierarchy) {
      _filteredElements = [];
      return;
    }
    
    if (!_filterCriteria.hasActiveFilters) {
      _filteredElements = List.from(_flatElements);
    } else {
      _filteredElements = _filterCriteria.filterElements(_flatElements);
    }
    
    // Update search results if there's an active search
    if (_searchQuery.isNotEmpty) {
      _performSearch();
    }
  }
  
  /// Perform search on current elements
  void _performSearch() {
    _isSearching = true;
    
    if (_searchQuery.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      return;
    }
    
    // Search in filtered elements
    final elementsToSearch = _filteredElements.isNotEmpty ? _filteredElements : _flatElements;
    
    _searchResults = elementsToSearch.where((element) {
      final query = _searchQuery.toLowerCase();
      return element.text.toLowerCase().contains(query) ||
             element.contentDesc.toLowerCase().contains(query) ||
             element.resourceId.toLowerCase().contains(query) ||
             element.className.toLowerCase().contains(query);
    }).toList();
    
    _isSearching = false;
  }
  
  /// Get elements that match current search and filters
  List<UIElement> getDisplayElements() {
    if (_searchQuery.isNotEmpty && _searchResults.isNotEmpty) {
      return _searchResults;
    }
    return _filteredElements;
  }
  
  /// Find element by ID
  UIElement? findElementById(String id) {
    return _flatElements.cast<UIElement?>().firstWhere(
      (element) => element?.id == id,
      orElse: () => null,
    );
  }
  
  /// Get path to selected element
  List<UIElement> getSelectedElementPath() {
    if (_selectedElement == null) return [];
    return _selectedElement!.getPathFromRoot();
  }
  
  /// Check if element is in current search results
  bool isElementInSearchResults(UIElement element) {
    return _searchResults.contains(element);
  }
  
  /// Check if element matches current filters
  bool doesElementMatchFilters(UIElement element) {
    return _filterCriteria.matches(element);
  }
  
  /// Get statistics about current state
  Map<String, dynamic> getStatistics() {
    return {
      'totalElements': totalElementCount,
      'filteredElements': filteredElementCount,
      'searchResults': _searchResults.length,
      'hasActiveFilters': hasActiveFilters,
      'isSearchActive': _searchQuery.isNotEmpty,
      'selectedDevice': _selectedDevice?.displayName,
      'availableDevices': _availableDevices.length,
      'historyFiles': _historyFiles.length,
    };
  }
  
  /// Reset all state to initial values
  void reset() {
    _rootElement = null;
    _flatElements = [];
    _filteredElements = [];
    _selectedDevice = null;
    _availableDevices = [];
    _filterCriteria = FilterCriteria.empty;
    _selectedElement = null;
    _xmlContent = '';
    _isLoading = false;
    _errorMessage = null;
    _isXmlViewerVisible = false;
    _searchQuery = '';
    _searchResults = [];
    _isSearching = false;
    _historyFiles = [];
    _currentHistoryFile = null;
    
    notifyListeners();
  }
  
  /// Refresh available devices
  Future<void> refreshDevices() async {
    setLoading(true, 'Refreshing devices...');
    
    try {
      // Use actual ADB service to get connected devices
      final adbService = ADBService();
      
      // Check if ADB is available first
      final isAdbAvailable = await adbService.isADBAvailable();
      if (!isAdbAvailable) {
        throw Exception('ADB is not available. Please ensure Android SDK platform-tools are installed and in PATH.');
      }
      
      // Get real connected devices
      final devices = await adbService.getConnectedDevices();
      
      setAvailableDevices(devices);
      
      // Try to auto-select last used device
      _trySelectLastDevice();
    } catch (e) {
      setErrorFromException(e);
      rethrow;
    } finally {
      setLoading(false);
    }
  }
  
  /// Capture UI hierarchy from selected device
  Future<void> captureUIHierarchy() async {
    if (_selectedDevice == null || !_selectedDevice!.isConnected) {
      throw Exception('No connected device selected');
    }
    
    setLoading(true, '正在获取UI结构...', 0.0);
    
    try {
      final adbService = ADBService();
      final xmlParser = XMLParser();
      final fileManager = FileManagerImpl();
      
      // Get UI dump with progress tracking
      final xmlContent = await adbService.dumpUIHierarchy(
        _selectedDevice!.id,
        onProgress: (progress, message) {
          updateProgress(progress, message);
        },
        onStep: (currentStep, totalSteps, stepName) {
          updateStep(currentStep, totalSteps, stepName);
        },
      );
      
      // Parse XML content
      updateProgress(0.95, '解析XML内容...');
      final rootElement = await xmlParser.parseXMLString(xmlContent);
      
      // Save to history
      updateProgress(0.98, '保存到历史记录...');
      final savedPath = await fileManager.saveUIdump(xmlContent);
      
      // Update state
      setUIHierarchy(rootElement, xmlContent: xmlContent);
      
      // Add to history
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final historyFile = 'ui_dump_$timestamp.xml';
      addHistoryFile(historyFile);
      setCurrentHistoryFile(historyFile);
      
      updateProgress(1.0, 'UI结构获取完成！');
      
      // Create mock data for testing
      final mockRoot = UIElement(
        id: 'root',
        depth: 0,
        text: '',
        contentDesc: '',
        className: 'android.widget.FrameLayout',
        packageName: 'com.example.app',
        resourceId: '',
        clickable: false,
        enabled: true,
        bounds: const Rect.fromLTWH(0, 0, 1080, 1920),
        index: 0,
      );

      final mockChild1 = UIElement(
        id: 'child1',
        depth: 1,
        text: 'Hello World',
        contentDesc: 'Greeting text',
        className: 'android.widget.TextView',
        packageName: 'com.example.app',
        resourceId: 'com.example.app:id/greeting',
        clickable: false,
        enabled: true,
        bounds: const Rect.fromLTWH(100, 200, 880, 100),
        index: 0,
      );

      final mockChild2 = UIElement(
        id: 'child2',
        depth: 1,
        text: 'Click Me',
        contentDesc: 'Action button',
        className: 'android.widget.Button',
        packageName: 'com.example.app',
        resourceId: 'com.example.app:id/action_button',
        clickable: true,
        enabled: true,
        bounds: const Rect.fromLTWH(400, 400, 280, 80),
        index: 1,
      );

      mockRoot.addChild(mockChild1);
      mockRoot.addChild(mockChild2);
      
      const mockXml = '''<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>
<hierarchy rotation="0">
  <node index="0" text="" resource-id="" class="android.widget.FrameLayout" package="com.example.app" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,0][1080,1920]">
    <node index="0" text="Hello World" resource-id="com.example.app:id/greeting" class="android.widget.TextView" package="com.example.app" content-desc="Greeting text" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[100,200][980,300]" />
    <node index="1" text="Click Me" resource-id="com.example.app:id/action_button" class="android.widget.Button" package="com.example.app" content-desc="Action button" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[400,400][680,480]" />
  </node>
</hierarchy>''';
      
      setUIHierarchy(mockRoot, xmlContent: mockXml);
      
    } catch (e) {
      setErrorFromException(e);
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  /// Get animation duration for UI transitions
  Duration get animationDuration => Duration(milliseconds: _animationDurationMs);
  
  /// Get search debounce duration
  Duration get searchDebounceDuration => Duration(milliseconds: _searchDebounceMs);
  
  /// Update performance settings
  void updatePerformanceSettings({
    int? searchDebounceMs,
    int? animationDurationMs,
  }) {
    bool changed = false;
    
    if (searchDebounceMs != null && _searchDebounceMs != searchDebounceMs) {
      _searchDebounceMs = searchDebounceMs;
      UserPreferences.setSearchDebounceMs(searchDebounceMs);
      changed = true;
    }
    
    if (animationDurationMs != null && _animationDurationMs != animationDurationMs) {
      _animationDurationMs = animationDurationMs;
      UserPreferences.setAnimationDurationMs(animationDurationMs);
      changed = true;
    }
    
    if (changed) {
      notifyListeners();
    }
  }
  
  /// Auto-select last used device when devices are loaded
  void _trySelectLastDevice() {
    final lastDeviceId = UserPreferences.getLastSelectedDevice();
    if (lastDeviceId != null) {
      final device = _availableDevices.cast<AndroidDevice?>().firstWhere(
        (d) => d?.id == lastDeviceId,
        orElse: () => null,
      );
      if (device != null) {
        selectDevice(device);
      }
    }
  }
  
  /// Focus search field (for keyboard shortcuts)
  void focusSearch() {
    _shouldFocusSearch = true;
    notifyListeners();
    // Reset the flag after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _shouldFocusSearch = false;
    });
  }
  
  /// Check if search should be focused
  bool get shouldFocusSearch => _shouldFocusSearch;
  
  /// Dispose resources
  @override
  void dispose() {
    // Cancel any pending timers
    _searchDebounceTimer?.cancel();
    
    // Clear all references
    _rootElement = null;
    _flatElements.clear();
    _filteredElements.clear();
    _availableDevices.clear();
    _searchResults.clear();
    _historyFiles.clear();
    
    super.dispose();
  }
}