import 'dart:async';
import 'package:flutter/foundation.dart';
import '../controllers/ui_analyzer_state.dart';
import '../services/adb_service.dart';
import '../services/xml_parser.dart';
import '../services/file_manager.dart';
import '../models/android_device.dart';
import '../models/ui_element.dart';
import '../models/filter_criteria.dart';
import '../utils/error_handler.dart';

/// Integration manager that coordinates all app components
class AppIntegration {
  static final AppIntegration _instance = AppIntegration._internal();
  factory AppIntegration() => _instance;
  AppIntegration._internal();

  late final UIAnalyzerState _state;
  late final ADBService _adbService;
  late final XMLParser _xmlParser;
  late final FileManagerImpl _fileManager;

  bool _isInitialized = false;

  /// Initialize all services and components
  Future<void> initialize(UIAnalyzerState state) async {
    if (_isInitialized) return;

    _state = state;
    _adbService = ADBService();
    _xmlParser = XMLParser();
    _fileManager = FileManagerImpl();

    // Load user preferences
    await _loadUserPreferences();

    // Initialize services
    await _initializeServices();

    _isInitialized = true;
    debugPrint('AppIntegration: All components initialized successfully');
  }

  /// Load user preferences and settings
  Future<void> _loadUserPreferences() async {
    try {
      // Load theme preference
      await _state.loadThemePreference();

      // Load history files
      final historyFiles = await _fileManager.getHistoryFiles();
      _state.setHistoryFiles(historyFiles);

      debugPrint('AppIntegration: User preferences loaded');
    } catch (e) {
      debugPrint('AppIntegration: Failed to load user preferences: $e');
    }
  }

  /// Initialize all services
  Future<void> _initializeServices() async {
    try {
      // Check ADB availability
      final isAdbAvailable = await _adbService.isADBAvailable();
      if (!isAdbAvailable) {
        debugPrint('AppIntegration: ADB is not available on this system');
      }

      // Refresh device list
      await refreshDevices();

      debugPrint('AppIntegration: Services initialized');
    } catch (e) {
      debugPrint('AppIntegration: Failed to initialize services: $e');
    }
  }

  /// Refresh available Android devices
  Future<void> refreshDevices() async {
    try {
      _state.setLoading(true, 'Refreshing devices...');

      final devices = await _adbService.getConnectedDevices();
      _state.setAvailableDevices(devices);

      debugPrint('AppIntegration: Found ${devices.length} devices');
    } catch (e) {
      _state.setErrorFromException(e);
      debugPrint('AppIntegration: Failed to refresh devices: $e');
      rethrow;
    } finally {
      _state.setLoading(false);
    }
  }

  /// Complete UI capture workflow
  Future<void> captureUIHierarchy() async {
    if (!_state.hasSelectedDevice || !_state.isDeviceConnected) {
      throw Exception('No connected device selected');
    }

    try {
      _state.setLoading(true, 'Starting UI capture...', 0.0);

      // Step 1: Capture UI dump from device
      final xmlContent = await _adbService.dumpUIHierarchy(
        _state.selectedDevice!.id,
        onProgress: (progress, message) {
          _state.updateProgress(progress, message);
        },
        onStep: (currentStep, totalSteps, stepName) {
          _state.updateStep(currentStep, totalSteps, stepName);
        },
      );

      // Step 2: Parse XML content
      _state.updateProgress(0.8, 'Parsing UI hierarchy...');
      final rootElement = await _xmlParser.parseXMLString(xmlContent);

      // Step 3: Save to history
      _state.updateProgress(0.9, 'Saving to history...');
      final savedPath = await _fileManager.saveUIdump(xmlContent);

      // Step 4: Update application state
      _state.setUIHierarchy(rootElement, xmlContent: xmlContent);
      _state.addHistoryFile(savedPath);
      _state.setCurrentHistoryFile(savedPath);

      _state.updateProgress(1.0, 'UI capture completed successfully!');

      debugPrint('AppIntegration: UI hierarchy captured successfully');
    } catch (e) {
      _state.setErrorFromException(e);
      debugPrint('AppIntegration: Failed to capture UI hierarchy: $e');
      rethrow;
    } finally {
      _state.setLoading(false);
    }
  }

  /// Load UI hierarchy from history file
  Future<void> loadFromHistory(String filePath) async {
    try {
      _state.setLoading(true, 'Loading from history...');

      // Read XML content from file
      final xmlContent = await _fileManager.readFile(filePath);

      // Parse XML content
      final rootElement = await _xmlParser.parseXMLString(xmlContent);

      // Update application state
      _state.setUIHierarchy(rootElement, xmlContent: xmlContent);
      _state.setCurrentHistoryFile(filePath);

      debugPrint('AppIntegration: Loaded UI hierarchy from history: $filePath');
    } catch (e) {
      _state.setErrorFromException(e);
      debugPrint('AppIntegration: Failed to load from history: $e');
      rethrow;
    } finally {
      _state.setLoading(false);
    }
  }

  /// Export current UI hierarchy to XML file
  Future<String> exportToXML(String filePath) async {
    if (!_state.hasUIHierarchy) {
      throw Exception('No UI hierarchy to export');
    }

    try {
      _state.setLoading(true, 'Exporting XML...');

      final exportedPath = await _fileManager.exportToXML(
        _state.rootElement!,
        filePath,
      );

      debugPrint('AppIntegration: Exported UI hierarchy to: $exportedPath');
      return exportedPath;
    } catch (e) {
      _state.setErrorFromException(e);
      debugPrint('AppIntegration: Failed to export XML: $e');
      rethrow;
    } finally {
      _state.setLoading(false);
    }
  }

  /// Perform comprehensive search across UI hierarchy
  Future<List<UIElement>> performSearch(String query) async {
    if (!_state.hasUIHierarchy || query.trim().isEmpty) {
      return [];
    }

    try {
      final results = <UIElement>[];
      final allElements = _state.flatElements;

      for (final element in allElements) {
        if (_matchesSearchQuery(element, query)) {
          results.add(element);
        }
      }

      debugPrint('AppIntegration: Search for "$query" found ${results.length} results');
      return results;
    } catch (e) {
      debugPrint('AppIntegration: Search failed: $e');
      return [];
    }
  }

  /// Check if element matches search query
  bool _matchesSearchQuery(UIElement element, String query) {
    final lowerQuery = query.toLowerCase();
    
    return element.text.toLowerCase().contains(lowerQuery) ||
           element.contentDesc.toLowerCase().contains(lowerQuery) ||
           element.resourceId.toLowerCase().contains(lowerQuery) ||
           element.className.toLowerCase().contains(lowerQuery) ||
           element.packageName.toLowerCase().contains(lowerQuery);
  }

  /// Apply filters to UI hierarchy
  List<UIElement> applyFilters(FilterCriteria criteria) {
    if (!_state.hasUIHierarchy) {
      return [];
    }

    try {
      final filteredElements = criteria.filterElements(_state.flatElements);
      debugPrint('AppIntegration: Applied filters, ${filteredElements.length} elements match');
      return filteredElements;
    } catch (e) {
      debugPrint('AppIntegration: Filter application failed: $e');
      return _state.flatElements;
    }
  }

  /// Get detailed device information
  Future<Map<String, String>> getDeviceDetails(String deviceId) async {
    try {
      return await _adbService.getDeviceDetails(deviceId);
    } catch (e) {
      debugPrint('AppIntegration: Failed to get device details: $e');
      return {};
    }
  }

  /// Get UI hierarchy statistics
  Map<String, dynamic> getHierarchyStatistics() {
    if (!_state.hasUIHierarchy) {
      return {};
    }

    try {
      return _xmlParser.getHierarchyStats(_state.rootElement!);
    } catch (e) {
      debugPrint('AppIntegration: Failed to get hierarchy statistics: $e');
      return {};
    }
  }

  /// Validate current UI hierarchy integrity
  bool validateHierarchyIntegrity() {
    if (!_state.hasUIHierarchy) {
      return false;
    }

    try {
      return _xmlParser.validateHierarchyIntegrity(_state.rootElement!);
    } catch (e) {
      debugPrint('AppIntegration: Hierarchy validation failed: $e');
      return false;
    }
  }

  /// Clean up old history files
  Future<void> cleanupHistory({int keepCount = 50}) async {
    try {
      await _fileManager.cleanupOldFiles(keepCount: keepCount);
      
      // Refresh history list
      final historyFiles = await _fileManager.getHistoryFiles();
      _state.setHistoryFiles(historyFiles);

      debugPrint('AppIntegration: History cleanup completed');
    } catch (e) {
      debugPrint('AppIntegration: History cleanup failed: $e');
    }
  }

  /// Get application health status
  Map<String, dynamic> getHealthStatus() {
    return {
      'isInitialized': _isInitialized,
      'hasSelectedDevice': _state.hasSelectedDevice,
      'deviceConnected': _state.isDeviceConnected,
      'hasUIHierarchy': _state.hasUIHierarchy,
      'isLoading': _state.isLoading,
      'hasError': _state.hasError,
      'availableDevices': _state.availableDevices.length,
      'totalElements': _state.totalElementCount,
      'filteredElements': _state.filteredElementCount,
      'historyFiles': _state.historyFiles.length,
      'memoryUsage': _getMemoryUsage(),
    };
  }

  /// Get approximate memory usage
  Map<String, dynamic> _getMemoryUsage() {
    return {
      'flatElements': _state.flatElements.length,
      'filteredElements': _state.filteredElements.length,
      'searchResults': _state.searchResults.length,
      'xmlContentSize': _state.xmlContent.length,
    };
  }

  /// Perform comprehensive system check
  Future<Map<String, dynamic>> performSystemCheck() async {
    final results = <String, dynamic>{};

    try {
      // Check ADB availability
      results['adbAvailable'] = await _adbService.isADBAvailable();

      // Check device connectivity
      if (_state.hasSelectedDevice) {
        results['deviceConnected'] = await _adbService.isDeviceConnected(
          _state.selectedDevice!.id,
        );
      } else {
        results['deviceConnected'] = false;
      }

      // Check file system access
      try {
        final historyFiles = await _fileManager.getHistoryFiles();
        results['fileSystemAccess'] = true;
        results['historyFilesCount'] = historyFiles.length;
      } catch (e) {
        results['fileSystemAccess'] = false;
        results['fileSystemError'] = e.toString();
      }

      // Check XML parser
      if (_state.hasXmlContent) {
        results['xmlParserWorking'] = _xmlParser.validateXMLContent(_state.xmlContent);
      } else {
        results['xmlParserWorking'] = true; // No content to validate
      }

      // Check hierarchy integrity
      if (_state.hasUIHierarchy) {
        results['hierarchyIntegrity'] = validateHierarchyIntegrity();
      } else {
        results['hierarchyIntegrity'] = true; // No hierarchy to validate
      }

      results['overallHealth'] = _calculateOverallHealth(results);

      debugPrint('AppIntegration: System check completed');
    } catch (e) {
      results['systemCheckError'] = e.toString();
      results['overallHealth'] = 'error';
      debugPrint('AppIntegration: System check failed: $e');
    }

    return results;
  }

  /// Calculate overall system health
  String _calculateOverallHealth(Map<String, dynamic> results) {
    final criticalChecks = [
      results['adbAvailable'] == true,
      results['fileSystemAccess'] == true,
      results['xmlParserWorking'] == true,
      results['hierarchyIntegrity'] == true,
    ];

    final passedChecks = criticalChecks.where((check) => check).length;
    final totalChecks = criticalChecks.length;

    if (passedChecks == totalChecks) {
      return 'excellent';
    } else if (passedChecks >= totalChecks * 0.75) {
      return 'good';
    } else if (passedChecks >= totalChecks * 0.5) {
      return 'fair';
    } else {
      return 'poor';
    }
  }

  /// Reset all application state
  Future<void> resetApplication() async {
    try {
      _state.reset();
      await _loadUserPreferences();
      debugPrint('AppIntegration: Application reset completed');
    } catch (e) {
      debugPrint('AppIntegration: Application reset failed: $e');
    }
  }

  /// Dispose all resources
  void dispose() {
    if (_isInitialized) {
      _state.dispose();
      _isInitialized = false;
      debugPrint('AppIntegration: Resources disposed');
    }
  }

  /// Get integration status for debugging
  Map<String, dynamic> getIntegrationStatus() {
    return {
      'initialized': _isInitialized,
      'stateValid': _state.toString().isNotEmpty,
      'servicesReady': {
        'adb': _adbService.toString().isNotEmpty,
        'xmlParser': _xmlParser.toString().isNotEmpty,
        'fileManager': _fileManager.toString().isNotEmpty,
      },
      'healthStatus': getHealthStatus(),
    };
  }
}