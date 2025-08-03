/// Represents an Android device connected via ADB
class AndroidDevice {
  /// Unique device identifier (serial number)
  final String id;
  
  /// Human-readable device name
  final String name;
  
  /// Current connection status
  final DeviceStatus status;
  
  /// Device model information
  final String model;
  
  /// Android version
  final String androidVersion;
  
  /// API level
  final int apiLevel;
  
  /// Last time the device was connected
  final DateTime? lastConnected;
  
  /// Additional device properties
  final Map<String, String> properties;
  
  /// Constructor
  const AndroidDevice({
    required this.id,
    required this.name,
    this.status = DeviceStatus.unknown,
    this.model = '',
    this.androidVersion = '',
    this.apiLevel = 0,
    this.lastConnected,
    this.properties = const {},
  });
  
  /// Check if device is currently connected
  bool get isConnected => status == DeviceStatus.device;
  
  /// Check if device is available for debugging
  bool get isAvailable => status == DeviceStatus.device || status == DeviceStatus.emulator;
  
  /// Get display name for UI
  String get displayName {
    if (name.isNotEmpty && name != id) {
      return '$name ($id)';
    }
    return id;
  }
  
  /// Get detailed device information
  String get deviceInfo {
    final info = StringBuffer();
    info.write(displayName);
    
    if (model.isNotEmpty) {
      info.write(' - $model');
    }
    
    if (androidVersion.isNotEmpty) {
      info.write(' (Android $androidVersion');
      if (apiLevel > 0) {
        info.write(', API $apiLevel');
      }
      info.write(')');
    }
    
    return info.toString();
  }
  
  /// Create a copy with updated status
  AndroidDevice copyWithStatus(DeviceStatus newStatus) {
    return AndroidDevice(
      id: id,
      name: name,
      status: newStatus,
      model: model,
      androidVersion: androidVersion,
      apiLevel: apiLevel,
      lastConnected: newStatus == DeviceStatus.device ? DateTime.now() : lastConnected,
      properties: properties,
    );
  }
  
  /// Create a copy with updated device information
  AndroidDevice copyWith({
    String? name,
    DeviceStatus? status,
    String? model,
    String? androidVersion,
    int? apiLevel,
    DateTime? lastConnected,
    Map<String, String>? properties,
  }) {
    return AndroidDevice(
      id: id,
      name: name ?? this.name,
      status: status ?? this.status,
      model: model ?? this.model,
      androidVersion: androidVersion ?? this.androidVersion,
      apiLevel: apiLevel ?? this.apiLevel,
      lastConnected: lastConnected ?? this.lastConnected,
      properties: properties ?? this.properties,
    );
  }
  
  /// Create device from ADB output line
  static AndroidDevice fromAdbLine(String adbLine) {
    final parts = adbLine.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      throw ArgumentError('Invalid ADB device line: $adbLine');
    }
    
    final deviceId = parts[0];
    final statusString = parts[1];
    final status = DeviceStatus.fromString(statusString);
    
    return AndroidDevice(
      id: deviceId,
      name: deviceId,
      status: status,
      lastConnected: status == DeviceStatus.device ? DateTime.now() : null,
    );
  }
  
  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status.name,
      'model': model,
      'androidVersion': androidVersion,
      'apiLevel': apiLevel,
      'lastConnected': lastConnected?.toIso8601String(),
      'properties': properties,
    };
  }
  
  /// Create from JSON map
  static AndroidDevice fromJson(Map<String, dynamic> json) {
    return AndroidDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      status: DeviceStatus.fromString(json['status'] as String),
      model: json['model'] as String? ?? '',
      androidVersion: json['androidVersion'] as String? ?? '',
      apiLevel: json['apiLevel'] as int? ?? 0,
      lastConnected: json['lastConnected'] != null 
          ? DateTime.parse(json['lastConnected'] as String)
          : null,
      properties: Map<String, String>.from(json['properties'] as Map? ?? {}),
    );
  }
  
  @override
  String toString() {
    return 'AndroidDevice(id: $id, name: $name, status: ${status.name})';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AndroidDevice && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

/// Enum representing device connection status
enum DeviceStatus {
  /// Device is connected and ready for debugging
  device,
  
  /// Device is an emulator
  emulator,
  
  /// Device is offline
  offline,
  
  /// Device is unauthorized (needs USB debugging approval)
  unauthorized,
  
  /// Device is in bootloader mode
  bootloader,
  
  /// Device is in recovery mode
  recovery,
  
  /// Device is in sideload mode
  sideload,
  
  /// Unknown status
  unknown;
  
  /// Create DeviceStatus from string
  static DeviceStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'device':
        return DeviceStatus.device;
      case 'emulator':
        return DeviceStatus.emulator;
      case 'offline':
        return DeviceStatus.offline;
      case 'unauthorized':
        return DeviceStatus.unauthorized;
      case 'bootloader':
        return DeviceStatus.bootloader;
      case 'recovery':
        return DeviceStatus.recovery;
      case 'sideload':
        return DeviceStatus.sideload;
      default:
        return DeviceStatus.unknown;
    }
  }
  
  /// Get display name for UI
  String get displayName {
    switch (this) {
      case DeviceStatus.device:
        return '已连接';
      case DeviceStatus.emulator:
        return '模拟器';
      case DeviceStatus.offline:
        return '离线';
      case DeviceStatus.unauthorized:
        return '未授权';
      case DeviceStatus.bootloader:
        return '引导模式';
      case DeviceStatus.recovery:
        return '恢复模式';
      case DeviceStatus.sideload:
        return '侧载模式';
      case DeviceStatus.unknown:
        return '未知';
    }
  }
  
  /// Check if status indicates device is usable
  bool get isUsable {
    return this == DeviceStatus.device || this == DeviceStatus.emulator;
  }
}