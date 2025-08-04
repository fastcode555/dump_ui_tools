import 'dart:io';
import 'dart:convert';
import 'dart:async';
import '../models/android_device.dart';

/// Progress callback for long-running operations
typedef ProgressCallback = void Function(double progress, String message);

/// Step callback for multi-step operations
typedef StepCallback = void Function(int currentStep, int totalSteps, String stepName);

/// Exception thrown when ADB operations fail
class ADBException implements Exception {
  final String message;
  final String? details;
  final int? exitCode;
  
  const ADBException(this.message, [this.details, this.exitCode]);
  
  @override
  String toString() {
    final buffer = StringBuffer('ADBException: $message');
    if (details != null) {
      buffer.write('\nDetails: $details');
    }
    if (exitCode != null) {
      buffer.write('\nExit code: $exitCode');
    }
    return buffer.toString();
  }
}

/// Service for interacting with Android Debug Bridge (ADB)
class ADBService {
  static const String _adbCommand = 'adb';
  static const Duration _defaultTimeout = Duration(seconds: 30);
  
  // Common ADB paths to try
  static const List<String> _adbPaths = [
    'adb', // System PATH
    '/Users/\$USER/Library/Android/sdk/platform-tools/adb', // macOS default
    '/usr/local/bin/adb', // Homebrew
    '/opt/homebrew/bin/adb', // Apple Silicon Homebrew
  ];
  
  /// Singleton instance
  static final ADBService _instance = ADBService._internal();
  factory ADBService() => _instance;
  ADBService._internal();
  
  /// Find available ADB executable path
  Future<String?> _findAdbPath() async {
    // Get the real user home directory (not sandboxed)
    String? realHomeDir;
    try {
      final result = await Process.run('sh', ['-c', 'echo \$HOME']);
      if (result.exitCode == 0) {
        realHomeDir = result.stdout.toString().trim();
      }
    } catch (e) {
      print('Error getting real home directory: $e');
    }
    
    // Fallback to environment variable
    realHomeDir ??= Platform.environment['HOME'];
    
    // Get current user name for path construction
    String? userName;
    try {
      final result = await Process.run('whoami', []);
      if (result.exitCode == 0) {
        userName = result.stdout.toString().trim();
      }
    } catch (e) {
      print('Error getting username: $e');
    }
    
    // Try common installation paths with real paths
    final commonPaths = <String>[
      // Try with full path using username
      if (userName != null) '/Users/$userName/Library/Android/sdk/platform-tools/adb',
      // Try with home directory
      if (realHomeDir != null) '$realHomeDir/Library/Android/sdk/platform-tools/adb',
      // System paths
      '/usr/local/bin/adb',
      '/opt/homebrew/bin/adb',
      // Try adb in PATH (might work if permissions allow)
      'adb',
    ];
    
    print('Real home dir: $realHomeDir, Username: $userName');
    print('Trying ADB paths...');
    
    for (final path in commonPaths) {
      try {
        print('Trying path: $path');
        final result = await Process.run(path, ['version'], runInShell: true);
        print('Path $path result: exitCode=${result.exitCode}');
        if (result.exitCode == 0) {
          print('Found working ADB at: $path');
          return path;
        }
      } catch (e) {
        print('Error trying path $path: $e');
      }
    }
    
    // Try using shell to find adb
    try {
      print('Trying to find adb using shell...');
      final result = await Process.run('sh', ['-c', 'which adb'], runInShell: true);
      if (result.exitCode == 0) {
        final path = result.stdout.toString().trim();
        if (path.isNotEmpty) {
          print('Found ADB via shell: $path');
          // Test if it works
          final testResult = await Process.run(path, ['version'], runInShell: true);
          if (testResult.exitCode == 0) {
            return path;
          }
        }
      }
    } catch (e) {
      print('Error finding adb via shell: $e');
    }
    
    print('No working ADB path found');
    return null;
  }

  /// Check if ADB is available on the system
  Future<bool> isADBAvailable() async {
    try {
      final adbPath = await _findAdbPath();
      return adbPath != null;
    } catch (e) {
      return false;
    }
  }
  
  /// Get list of connected Android devices
  Future<List<AndroidDevice>> getConnectedDevices() async {
    try {
      final result = await _runADBCommand(['devices', '-l']);
      
      if (result.exitCode != 0) {
        throw ADBException(
          'Failed to get device list',
          result.stderr.toString(),
          result.exitCode,
        );
      }
      
      return _parseDeviceList(result.stdout.toString());
    } catch (e) {
      if (e is ADBException) rethrow;
      throw ADBException('Error getting connected devices: ${e.toString()}');
    }
  }
  
  /// Check if a specific device is connected and available
  Future<bool> isDeviceConnected(String deviceId) async {
    try {
      final devices = await getConnectedDevices();
      final device = devices.where((d) => d.id == deviceId).firstOrNull;
      return device?.isAvailable ?? false;
    } catch (e) {
      return false;
    }
  }
  
  /// Get current activity information for a device
  Future<String> getCurrentActivity(String deviceId) async {
    try {
      // First check if device is connected
      if (!await isDeviceConnected(deviceId)) {
        throw ADBException('Device $deviceId is not connected or available');
      }
      
      // Try multiple methods to get current activity
      String? activity = await _getCurrentActivityMethod1(deviceId);
      activity ??= await _getCurrentActivityMethod2(deviceId);
      activity ??= await _getCurrentActivityMethod3(deviceId);
      
      return activity ?? 'Unknown Activity';
    } catch (e) {
      if (e is ADBException) rethrow;
      throw ADBException('Error getting current activity: ${e.toString()}');
    }
  }
  
  /// Method 1: Using dumpsys activity activities
  Future<String?> _getCurrentActivityMethod1(String deviceId) async {
    try {
      final result = await _runADBCommand([
        '-s', deviceId,
        'shell',
        'dumpsys', 'activity', 'activities'
      ], timeout: Duration(seconds: 15));
      
      if (result.exitCode == 0) {
        return _parseCurrentActivity(result.stdout.toString());
      }
    } catch (e) {
      // Try next method
    }
    return null;
  }
  
  /// Method 2: Using dumpsys activity top
  Future<String?> _getCurrentActivityMethod2(String deviceId) async {
    try {
      final result = await _runADBCommand([
        '-s', deviceId,
        'shell',
        'dumpsys', 'activity', 'top'
      ], timeout: Duration(seconds: 15));
      
      if (result.exitCode == 0) {
        return _parseTopActivity(result.stdout.toString());
      }
    } catch (e) {
      // Try next method
    }
    return null;
  }
  
  /// Method 3: Using dumpsys window windows
  Future<String?> _getCurrentActivityMethod3(String deviceId) async {
    try {
      final result = await _runADBCommand([
        '-s', deviceId,
        'shell',
        'dumpsys', 'window', 'windows'
      ], timeout: Duration(seconds: 15));
      
      if (result.exitCode == 0) {
        return _parseWindowActivity(result.stdout.toString());
      }
    } catch (e) {
      // All methods failed
    }
    return null;
  }
  
  /// Get comprehensive device information
  Future<Map<String, String>> getDeviceDetails(String deviceId) async {
    try {
      if (!await isDeviceConnected(deviceId)) {
        throw ADBException('Device $deviceId is not connected or available');
      }
      
      final details = <String, String>{};
      
      // Get basic device properties
      final properties = await _getDeviceProperties(deviceId);
      details.addAll(properties);
      
      // Get current activity
      try {
        final activity = await getCurrentActivity(deviceId);
        details['current_activity'] = activity;
      } catch (e) {
        details['current_activity'] = 'Unknown';
      }
      
      // Get screen resolution
      try {
        final resolution = await _getScreenResolution(deviceId);
        details['screen_resolution'] = resolution;
      } catch (e) {
        details['screen_resolution'] = 'Unknown';
      }
      
      // Get battery level
      try {
        final battery = await _getBatteryLevel(deviceId);
        details['battery_level'] = battery;
      } catch (e) {
        details['battery_level'] = 'Unknown';
      }
      
      // Get WiFi status
      try {
        final wifi = await _getWiFiStatus(deviceId);
        details['wifi_status'] = wifi;
      } catch (e) {
        details['wifi_status'] = 'Unknown';
      }
      
      return details;
    } catch (e) {
      if (e is ADBException) rethrow;
      throw ADBException('Error getting device details: ${e.toString()}');
    }
  }
  
  /// Get device properties
  Future<Map<String, String>> _getDeviceProperties(String deviceId) async {
    final result = await _runADBCommand([
      '-s', deviceId,
      'shell',
      'getprop'
    ]);
    
    if (result.exitCode != 0) {
      throw ADBException(
        'Failed to get device properties for $deviceId',
        result.stderr.toString(),
        result.exitCode,
      );
    }
    
    return _parseDeviceProperties(result.stdout.toString());
  }
  
  /// Get screen resolution
  Future<String> _getScreenResolution(String deviceId) async {
    final result = await _runADBCommand([
      '-s', deviceId,
      'shell',
      'wm', 'size'
    ]);
    
    if (result.exitCode == 0) {
      final output = result.stdout.toString();
      final match = RegExp(r'Physical size: (\d+x\d+)').firstMatch(output);
      if (match != null) {
        return match.group(1) ?? 'Unknown';
      }
    }
    
    return 'Unknown';
  }
  
  /// Get battery level
  Future<String> _getBatteryLevel(String deviceId) async {
    final result = await _runADBCommand([
      '-s', deviceId,
      'shell',
      'dumpsys', 'battery'
    ]);
    
    if (result.exitCode == 0) {
      final output = result.stdout.toString();
      final match = RegExp(r'level: (\d+)').firstMatch(output);
      if (match != null) {
        return '${match.group(1)}%';
      }
    }
    
    return 'Unknown';
  }
  
  /// Get WiFi status
  Future<String> _getWiFiStatus(String deviceId) async {
    final result = await _runADBCommand([
      '-s', deviceId,
      'shell',
      'dumpsys', 'wifi'
    ]);
    
    if (result.exitCode == 0) {
      final output = result.stdout.toString();
      if (output.contains('Wi-Fi is enabled')) {
        return 'Enabled';
      } else if (output.contains('Wi-Fi is disabled')) {
        return 'Disabled';
      }
    }
    
    return 'Unknown';
  }
  
  /// Dump UI hierarchy for a specific device with retry mechanism
  Future<String> dumpUIHierarchy(
    String deviceId, {
    int maxRetries = 3,
    ProgressCallback? onProgress,
    StepCallback? onStep,
  }) async {
    int attempts = 0;
    ADBException? lastException;
    
    while (attempts < maxRetries) {
      attempts++;
      
      try {
        // Step 1: Check device connection
        onStep?.call(1, 5, '检查设备连接');
        onProgress?.call(0.1, '检查设备连接状态...');
        
        if (!await isDeviceConnected(deviceId)) {
          throw ADBException('Device $deviceId is not connected or available');
        }
        
        // Step 2: Clear existing dump file
        onStep?.call(2, 5, '清理旧文件');
        onProgress?.call(0.2, '清理设备上的旧dump文件...');
        
        await _clearExistingDumpFile(deviceId);
        
        // Step 3: Execute dump command
        onStep?.call(3, 5, '执行UI dump');
        onProgress?.call(0.4, '正在获取UI层次结构...');
        
        final dumpResult = await _runADBCommand([
          '-s', deviceId,
          'shell',
          'uiautomator', 'dump', '/sdcard/window_dump.xml'
        ], timeout: Duration(seconds: 45));
        
        if (dumpResult.exitCode != 0) {
          final errorMsg = dumpResult.stderr.toString();
          throw ADBException(
            'Failed to dump UI hierarchy for device $deviceId (attempt $attempts/$maxRetries)',
            errorMsg,
            dumpResult.exitCode,
          );
        }
        
        // Wait a moment for the file to be written
        onProgress?.call(0.6, '等待文件写入完成...');
        await Future.delayed(Duration(milliseconds: 500));
        
        // Step 4: Verify dump file
        onStep?.call(4, 5, '验证dump文件');
        onProgress?.call(0.7, '验证dump文件是否创建成功...');
        
        final verifyResult = await _runADBCommand([
          '-s', deviceId,
          'shell',
          'test', '-s', '/sdcard/window_dump.xml', '&&', 'echo', 'exists'
        ]);
        
        if (verifyResult.exitCode != 0 || !verifyResult.stdout.toString().contains('exists')) {
          throw ADBException('UI dump file was not created or is empty');
        }
        
        // Step 5: Pull XML file
        onStep?.call(5, 5, '下载XML文件');
        onProgress?.call(0.8, '从设备下载XML文件...');
        
        final xmlContent = await _pullDumpFile(deviceId);
        
        if (xmlContent.trim().isEmpty) {
          throw ADBException('UI dump file is empty or could not be read');
        }
        
        // Validate XML content
        onProgress?.call(0.9, '验证XML内容...');
        if (!_isValidXMLContent(xmlContent)) {
          throw ADBException('UI dump file contains invalid XML content');
        }
        
        onProgress?.call(1.0, 'UI结构获取完成！');
        return xmlContent;
        
      } catch (e) {
        lastException = e is ADBException ? e : ADBException('Error dumping UI hierarchy: ${e.toString()}');
        
        if (attempts < maxRetries) {
          // Wait before retrying
          await Future.delayed(Duration(seconds: attempts));
          continue;
        }
      }
    }
    
    throw lastException ?? ADBException('Failed to dump UI hierarchy after $maxRetries attempts');
  }
  
  /// Clear existing dump file from device
  Future<void> _clearExistingDumpFile(String deviceId) async {
    try {
      await _runADBCommand([
        '-s', deviceId,
        'shell',
        'rm', '-f', '/sdcard/window_dump.xml'
      ], timeout: Duration(seconds: 10));
    } catch (e) {
      // Ignore errors when clearing - file might not exist
    }
  }
  
  /// Pull dump file from device with multiple methods
  Future<String> _pullDumpFile(String deviceId) async {
    // Method 1: Try pulling to stdout
    try {
      final pullResult = await _runADBCommand([
        '-s', deviceId,
        'shell',
        'cat', '/sdcard/window_dump.xml'
      ], timeout: Duration(seconds: 30));
      
      if (pullResult.exitCode == 0 && pullResult.stdout.toString().trim().isNotEmpty) {
        return pullResult.stdout.toString();
      }
    } catch (e) {
      // Try alternative method
    }
    
    // Method 2: Try traditional pull command
    final tempFile = '${Directory.systemTemp.path}/window_dump_${DateTime.now().millisecondsSinceEpoch}.xml';
    
    try {
      final pullResult = await _runADBCommand([
        '-s', deviceId,
        'pull', '/sdcard/window_dump.xml', tempFile
      ], timeout: Duration(seconds: 30));
      
      if (pullResult.exitCode != 0) {
        throw ADBException(
          'Failed to pull UI dump file from device $deviceId',
          pullResult.stderr.toString(),
          pullResult.exitCode,
        );
      }
      
      // Read the pulled file
      final file = File(tempFile);
      if (!await file.exists()) {
        throw ADBException('Pulled file does not exist: $tempFile');
      }
      
      final content = await file.readAsString();
      
      // Clean up temp file
      try {
        await file.delete();
      } catch (e) {
        // Ignore cleanup errors
      }
      
      return content;
      
    } catch (e) {
      // Clean up temp file on error
      try {
        await File(tempFile).delete();
      } catch (e) {
        // Ignore cleanup errors
      }
      
      if (e is ADBException) rethrow;
      throw ADBException('Error pulling dump file: ${e.toString()}');
    }
  }
  
  /// Validate XML content structure
  bool _isValidXMLContent(String content) {
    final trimmed = content.trim();
    
    // Check for basic XML structure
    if (!trimmed.startsWith('<?xml') && !trimmed.startsWith('<hierarchy')) {
      return false;
    }
    
    // Check for hierarchy root element
    if (!trimmed.contains('<hierarchy') || !trimmed.contains('</hierarchy>')) {
      return false;
    }
    
    // Check minimum content length
    if (trimmed.length < 100) {
      return false;
    }
    
    return true;
  }
  
  /// Get detailed device information
  Future<AndroidDevice> getDeviceInfo(String deviceId) async {
    try {
      if (!await isDeviceConnected(deviceId)) {
        throw ADBException('Device $deviceId is not connected or available');
      }
      
      // Get device properties
      final propsResult = await _runADBCommand([
        '-s', deviceId,
        'shell',
        'getprop'
      ]);
      
      if (propsResult.exitCode != 0) {
        throw ADBException(
          'Failed to get device properties for $deviceId',
          propsResult.stderr.toString(),
          propsResult.exitCode,
        );
      }
      
      final properties = _parseDeviceProperties(propsResult.stdout.toString());
      
      // Extract key information
      final model = properties['ro.product.model'] ?? '';
      final androidVersion = properties['ro.build.version.release'] ?? '';
      final apiLevel = int.tryParse(properties['ro.build.version.sdk'] ?? '0') ?? 0;
      final deviceName = properties['ro.product.name'] ?? deviceId;
      
      return AndroidDevice(
        id: deviceId,
        name: deviceName,
        status: DeviceStatus.device,
        model: model,
        androidVersion: androidVersion,
        apiLevel: apiLevel,
        lastConnected: DateTime.now(),
        properties: properties,
      );
    } catch (e) {
      if (e is ADBException) rethrow;
      throw ADBException('Error getting device info: ${e.toString()}');
    }
  }
  
  /// Execute ADB command with timeout
  Future<ProcessResult> _runADBCommand(
    List<String> arguments, {
    Duration timeout = _defaultTimeout,
  }) async {
    try {
      // Find ADB path first
      final adbPath = await _findAdbPath();
      if (adbPath == null) {
        throw ADBException('ADB not found in system PATH or common locations');
      }
      
      final process = await Process.start(adbPath, arguments, runInShell: true);
      
      // Set up timeout
      Timer? timeoutTimer;
      if (timeout != Duration.zero) {
        timeoutTimer = Timer(timeout, () {
          process.kill();
        });
      }
      
      final result = await process.exitCode;
      timeoutTimer?.cancel();
      
      final stdout = await process.stdout.transform(utf8.decoder).join();
      final stderr = await process.stderr.transform(utf8.decoder).join();
      
      return ProcessResult(process.pid, result, stdout, stderr);
    } catch (e) {
      throw ADBException('Failed to execute ADB command: ${arguments.join(' ')}', e.toString());
    }
  }
  
  /// Parse device list from ADB output
  List<AndroidDevice> _parseDeviceList(String output) {
    final devices = <AndroidDevice>[];
    final lines = output.split('\n');
    
    bool foundDevicesHeader = false;
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      if (trimmedLine == 'List of devices attached') {
        foundDevicesHeader = true;
        continue;
      }
      
      if (!foundDevicesHeader || trimmedLine.isEmpty) {
        continue;
      }
      
      try {
        final device = AndroidDevice.fromAdbLine(trimmedLine);
        devices.add(device);
      } catch (e) {
        // Skip invalid lines
        continue;
      }
    }
    
    return devices;
  }
  
  /// Parse current activity from dumpsys activity activities output
  String _parseCurrentActivity(String output) {
    final lines = output.split('\n');
    
    // Look for resumed activity first (most reliable)
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      final resumedMatch = RegExp(r'mResumedActivity.*?([a-zA-Z0-9_.]+/[a-zA-Z0-9_.]+)')
          .firstMatch(trimmedLine);
      
      if (resumedMatch != null) {
        return resumedMatch.group(1) ?? 'Unknown';
      }
    }
    
    // Fall back to focused activity
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      final focusedMatch = RegExp(r'mFocusedActivity.*?([a-zA-Z0-9_.]+/[a-zA-Z0-9_.]+)')
          .firstMatch(trimmedLine);
      
      if (focusedMatch != null) {
        return focusedMatch.group(1) ?? 'Unknown';
      }
    }
    
    // Look for any activity reference
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      final activityMatch = RegExp(r'ActivityRecord.*?([a-zA-Z0-9_.]+/[a-zA-Z0-9_.]+)')
          .firstMatch(trimmedLine);
      
      if (activityMatch != null) {
        return activityMatch.group(1) ?? 'Unknown';
      }
    }
    
    return 'Unknown Activity';
  }
  
  /// Parse activity from dumpsys activity top output
  String _parseTopActivity(String output) {
    final lines = output.split('\n');
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      // Look for ACTIVITY line
      if (trimmedLine.startsWith('ACTIVITY')) {
        final activityMatch = RegExp(r'ACTIVITY\s+([a-zA-Z0-9_.]+/[a-zA-Z0-9_.]+)')
            .firstMatch(trimmedLine);
        
        if (activityMatch != null) {
          return activityMatch.group(1) ?? 'Unknown';
        }
      }
      
      // Look for task activity
      final taskMatch = RegExp(r'TaskRecord.*?([a-zA-Z0-9_.]+/[a-zA-Z0-9_.]+)')
          .firstMatch(trimmedLine);
      
      if (taskMatch != null) {
        return taskMatch.group(1) ?? 'Unknown';
      }
    }
    
    return 'Unknown Activity';
  }
  
  /// Parse activity from dumpsys window windows output
  String _parseWindowActivity(String output) {
    final lines = output.split('\n');
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      // Look for focused window
      if (trimmedLine.contains('mCurrentFocus') || trimmedLine.contains('mFocusedApp')) {
        final activityMatch = RegExp(r'([a-zA-Z0-9_.]+/[a-zA-Z0-9_.]+)')
            .firstMatch(trimmedLine);
        
        if (activityMatch != null) {
          return activityMatch.group(1) ?? 'Unknown';
        }
      }
    }
    
    return 'Unknown Activity';
  }
  
  /// Parse device properties from getprop output
  Map<String, String> _parseDeviceProperties(String output) {
    final properties = <String, String>{};
    final lines = output.split('\n');
    
    for (final line in lines) {
      final match = RegExp(r'\[([^\]]+)\]:\s*\[([^\]]*)\]').firstMatch(line.trim());
      if (match != null) {
        final key = match.group(1);
        final value = match.group(2);
        if (key != null && value != null) {
          properties[key] = value;
        }
      }
    }
    
    return properties;
  }
}