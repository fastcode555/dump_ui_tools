import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user preferences and settings persistence
class UserPreferences {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLeftPanelWidth = 'left_panel_width';
  static const String _keyRightPanelWidth = 'right_panel_width';
  static const String _keyXmlPanelHeight = 'xml_panel_height';
  static const String _keyIsPreviewVisible = 'is_preview_visible';
  static const String _keyAutoShowXmlViewer = 'auto_show_xml_viewer';
  static const String _keySearchDebounceMs = 'search_debounce_ms';
  static const String _keyAnimationDuration = 'animation_duration_ms';
  static const String _keyMaxHistoryFiles = 'max_history_files';
  static const String _keyAutoSaveInterval = 'auto_save_interval_minutes';
  static const String _keyShowOnboarding = 'show_onboarding';
  static const String _keyLastSelectedDevice = 'last_selected_device';
  static const String _keyWindowWidth = 'window_width';
  static const String _keyWindowHeight = 'window_height';
  static const String _keyWindowX = 'window_x';
  static const String _keyWindowY = 'window_y';
  static const String _keyIsWindowMaximized = 'is_window_maximized';

  static SharedPreferences? _prefs;

  /// Initialize the preferences service
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  static SharedPreferences get _preferences {
    if (_prefs == null) {
      throw Exception('UserPreferences not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  // Theme preferences
  static ThemeMode getThemeMode() {
    final themeName = _preferences.getString(_keyThemeMode) ?? 'system';
    switch (themeName) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    await _preferences.setString(_keyThemeMode, mode.name);
  }

  // Panel size preferences
  static double getLeftPanelWidth() {
    return _preferences.getDouble(_keyLeftPanelWidth) ?? 400.0;
  }

  static Future<void> setLeftPanelWidth(double width) async {
    await _preferences.setDouble(_keyLeftPanelWidth, width);
  }

  static double getRightPanelWidth() {
    return _preferences.getDouble(_keyRightPanelWidth) ?? 400.0;
  }

  static Future<void> setRightPanelWidth(double width) async {
    await _preferences.setDouble(_keyRightPanelWidth, width);
  }

  static double getXmlPanelHeight() {
    return _preferences.getDouble(_keyXmlPanelHeight) ?? 200.0;
  }

  static Future<void> setXmlPanelHeight(double height) async {
    await _preferences.setDouble(_keyXmlPanelHeight, height);
  }

  // UI visibility preferences
  static bool getIsPreviewVisible() {
    return _preferences.getBool(_keyIsPreviewVisible) ?? true;
  }

  static Future<void> setIsPreviewVisible(bool visible) async {
    await _preferences.setBool(_keyIsPreviewVisible, visible);
  }

  static bool getAutoShowXmlViewer() {
    return _preferences.getBool(_keyAutoShowXmlViewer) ?? false;
  }

  static Future<void> setAutoShowXmlViewer(bool autoShow) async {
    await _preferences.setBool(_keyAutoShowXmlViewer, autoShow);
  }

  // Performance preferences
  static int getSearchDebounceMs() {
    return _preferences.getInt(_keySearchDebounceMs) ?? 300;
  }

  static Future<void> setSearchDebounceMs(int ms) async {
    await _preferences.setInt(_keySearchDebounceMs, ms);
  }

  static int getAnimationDurationMs() {
    return _preferences.getInt(_keyAnimationDuration) ?? 200;
  }

  static Future<void> setAnimationDurationMs(int ms) async {
    await _preferences.setInt(_keyAnimationDuration, ms);
  }

  // History preferences
  static int getMaxHistoryFiles() {
    return _preferences.getInt(_keyMaxHistoryFiles) ?? 50;
  }

  static Future<void> setMaxHistoryFiles(int count) async {
    await _preferences.setInt(_keyMaxHistoryFiles, count);
  }

  static int getAutoSaveIntervalMinutes() {
    return _preferences.getInt(_keyAutoSaveInterval) ?? 5;
  }

  static Future<void> setAutoSaveIntervalMinutes(int minutes) async {
    await _preferences.setInt(_keyAutoSaveInterval, minutes);
  }

  // Onboarding preferences
  static bool getShowOnboarding() {
    return _preferences.getBool(_keyShowOnboarding) ?? true;
  }

  static Future<void> setShowOnboarding(bool show) async {
    await _preferences.setBool(_keyShowOnboarding, show);
  }

  // Device preferences
  static String? getLastSelectedDevice() {
    return _preferences.getString(_keyLastSelectedDevice);
  }

  static Future<void> setLastSelectedDevice(String? deviceId) async {
    if (deviceId != null) {
      await _preferences.setString(_keyLastSelectedDevice, deviceId);
    } else {
      await _preferences.remove(_keyLastSelectedDevice);
    }
  }

  // Window preferences
  static double getWindowWidth() {
    return _preferences.getDouble(_keyWindowWidth) ?? 1200.0;
  }

  static Future<void> setWindowWidth(double width) async {
    await _preferences.setDouble(_keyWindowWidth, width);
  }

  static double getWindowHeight() {
    return _preferences.getDouble(_keyWindowHeight) ?? 800.0;
  }

  static Future<void> setWindowHeight(double height) async {
    await _preferences.setDouble(_keyWindowHeight, height);
  }

  static double? getWindowX() {
    return _preferences.getDouble(_keyWindowX);
  }

  static Future<void> setWindowX(double x) async {
    await _preferences.setDouble(_keyWindowX, x);
  }

  static double? getWindowY() {
    return _preferences.getDouble(_keyWindowY);
  }

  static Future<void> setWindowY(double y) async {
    await _preferences.setDouble(_keyWindowY, y);
  }

  static bool getIsWindowMaximized() {
    return _preferences.getBool(_keyIsWindowMaximized) ?? false;
  }

  static Future<void> setIsWindowMaximized(bool maximized) async {
    await _preferences.setBool(_keyIsWindowMaximized, maximized);
  }

  // Bulk operations
  static Future<void> saveWindowState({
    required double width,
    required double height,
    double? x,
    double? y,
    required bool isMaximized,
  }) async {
    await Future.wait([
      setWindowWidth(width),
      setWindowHeight(height),
      setIsWindowMaximized(isMaximized),
      if (x != null) setWindowX(x),
      if (y != null) setWindowY(y),
    ]);
  }

  static Future<void> savePanelSizes({
    required double leftPanelWidth,
    required double rightPanelWidth,
    required double xmlPanelHeight,
  }) async {
    await Future.wait([
      setLeftPanelWidth(leftPanelWidth),
      setRightPanelWidth(rightPanelWidth),
      setXmlPanelHeight(xmlPanelHeight),
    ]);
  }

  /// Reset all preferences to defaults
  static Future<void> resetToDefaults() async {
    await _preferences.clear();
  }

  /// Get all preferences as a map (for debugging/export)
  static Map<String, dynamic> getAllPreferences() {
    final keys = _preferences.getKeys();
    final Map<String, dynamic> prefs = {};
    
    for (final key in keys) {
      final value = _preferences.get(key);
      prefs[key] = value;
    }
    
    return prefs;
  }

  /// Import preferences from a map
  static Future<void> importPreferences(Map<String, dynamic> prefs) async {
    for (final entry in prefs.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is String) {
        await _preferences.setString(key, value);
      } else if (value is int) {
        await _preferences.setInt(key, value);
      } else if (value is double) {
        await _preferences.setDouble(key, value);
      } else if (value is bool) {
        await _preferences.setBool(key, value);
      } else if (value is List<String>) {
        await _preferences.setStringList(key, value);
      }
    }
  }
}