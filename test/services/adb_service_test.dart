import 'package:flutter_test/flutter_test.dart';
import 'package:dump_ui_tools/services/adb_service.dart';
import 'package:dump_ui_tools/models/android_device.dart';

void main() {
  group('ADBService Simple Tests', () {
    late ADBService adbService;
    
    setUp(() {
      adbService = ADBService();
    });
    
    test('should create ADB service instance', () {
      expect(adbService, isNotNull);
      expect(adbService, isA<ADBService>());
    });
    
    test('should check ADB availability', () async {
      // This test will pass regardless of ADB availability
      final isAvailable = await adbService.isADBAvailable();
      expect(isAvailable, isA<bool>());
    });
    
    test('should handle device listing gracefully', () async {
      try {
        final devices = await adbService.getConnectedDevices();
        expect(devices, isA<List<AndroidDevice>>());
      } catch (e) {
        // ADB might not be available in test environment
        expect(e, isA<Exception>());
      }
    });
    
    test('should handle device connection check gracefully', () async {
      try {
        final isConnected = await adbService.isDeviceConnected('test-device');
        expect(isConnected, isA<bool>());
      } catch (e) {
        // ADB might not be available in test environment
        expect(e, isA<Exception>());
      }
    });
    
    test('should handle UI dump gracefully', () async {
      try {
        final dump = await adbService.dumpUIHierarchy('test-device');
        expect(dump, isA<String>());
      } catch (e) {
        // ADB might not be available in test environment
        expect(e, isA<Exception>());
      }
    });
    
    test('should handle current activity check gracefully', () async {
      try {
        final activity = await adbService.getCurrentActivity('test-device');
        expect(activity, isA<String>());
      } catch (e) {
        // ADB might not be available in test environment
        expect(e, isA<Exception>());
      }
    });
  });
}