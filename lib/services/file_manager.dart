import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/ui_element.dart';

/// Exception thrown when file operations fail
class FileOperationException implements Exception {
  final String message;
  final String? details;
  
  const FileOperationException(this.message, [this.details]);
  
  @override
  String toString() {
    return details != null 
        ? 'FileOperationException: $message\nDetails: $details'
        : 'FileOperationException: $message';
  }
}

/// Abstract interface for file management operations
abstract class FileManager {
  /// Save UI dump content to file with optional custom filename
  Future<String> saveUIdump(String content, {String? filename});
  
  /// Get list of all history dump files
  Future<List<String>> getHistoryFiles();
  
  /// Read content from a file
  Future<String> readFile(String filePath);
  
  /// Delete a specific file
  Future<void> deleteFile(String filePath);
  
  /// Export UI hierarchy to XML file
  Future<String> exportToXML(UIElement root, String filePath);
}

/// Concrete implementation of FileManager
class FileManagerImpl implements FileManager {
  static const String _dumpsDirectoryName = 'dumps';
  static const String _filePrefix = 'window_dump_';
  static const String _fileExtension = '.xml';
  
  /// Get the dumps directory path
  Future<String> get _dumpsDirectoryPath async {
    // For desktop applications, use the application documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final dumpsPath = path.join(appDir.path, 'UIAnalyzer', _dumpsDirectoryName);
    
    // Ensure the directory exists
    final directory = Directory(dumpsPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    return dumpsPath;
  }
  
  /// Generate filename with timestamp
  String _generateTimestampFilename() {
    final now = DateTime.now();
    final timestamp = '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    return '$_filePrefix$timestamp$_fileExtension';
  }
  
  @override
  Future<String> saveUIdump(String content, {String? filename}) async {
    try {
      final dumpsDir = await _dumpsDirectoryPath;
      final fileName = filename ?? _generateTimestampFilename();
      final filePath = path.join(dumpsDir, fileName);
      
      final file = File(filePath);
      await file.writeAsString(content, encoding: utf8);
      
      return filePath;
    } catch (e) {
      throw FileOperationException(
        'Failed to save UI dump file',
        'Error: $e',
      );
    }
  }
  
  @override
  Future<List<String>> getHistoryFiles() async {
    try {
      final dumpsDir = await _dumpsDirectoryPath;
      final directory = Directory(dumpsDir);
      
      if (!await directory.exists()) {
        return [];
      }
      
      final files = await directory
          .list()
          .where((entity) => 
              entity is File && 
              entity.path.endsWith(_fileExtension) &&
              path.basename(entity.path).startsWith(_filePrefix))
          .cast<File>()
          .toList();
      
      // Sort files by modification time (newest first)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      return files.map((file) => file.path).toList();
    } catch (e) {
      throw FileOperationException(
        'Failed to get history files',
        'Error: $e',
      );
    }
  }
  
  @override
  Future<String> readFile(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        throw FileOperationException(
          'File not found',
          'Path: $filePath',
        );
      }
      
      return await file.readAsString(encoding: utf8);
    } catch (e) {
      if (e is FileOperationException) {
        rethrow;
      }
      throw FileOperationException(
        'Failed to read file',
        'Path: $filePath\nError: $e',
      );
    }
  }
  
  @override
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw FileOperationException(
        'Failed to delete file',
        'Path: $filePath\nError: $e',
      );
    }
  }
  
  @override
  Future<String> exportToXML(UIElement root, String filePath) async {
    try {
      final xmlContent = _generateXMLFromUIElement(root);
      final file = File(filePath);
      
      // Ensure the directory exists
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      await file.writeAsString(xmlContent, encoding: utf8);
      return filePath;
    } catch (e) {
      throw FileOperationException(
        'Failed to export XML file',
        'Path: $filePath\nError: $e',
      );
    }
  }
  
  /// Generate XML content from UI element hierarchy
  String _generateXMLFromUIElement(UIElement root) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.writeln('<hierarchy rotation="0">');
    
    _writeElementToXML(root, buffer, 1);
    
    buffer.writeln('</hierarchy>');
    return buffer.toString();
  }
  
  /// Recursively write UI element and its children to XML
  void _writeElementToXML(UIElement element, StringBuffer buffer, int indentLevel) {
    final indent = '  ' * indentLevel;
    
    // Build attributes
    final attributes = <String>[];
    
    if (element.index >= 0) {
      attributes.add('index="${element.index}"');
    }
    
    if (element.text.isNotEmpty) {
      attributes.add('text="${_escapeXMLAttribute(element.text)}"');
    }
    
    if (element.resourceId.isNotEmpty) {
      attributes.add('resource-id="${_escapeXMLAttribute(element.resourceId)}"');
    }
    
    attributes.add('class="${_escapeXMLAttribute(element.className)}"');
    
    if (element.packageName.isNotEmpty) {
      attributes.add('package="${_escapeXMLAttribute(element.packageName)}"');
    }
    
    if (element.contentDesc.isNotEmpty) {
      attributes.add('content-desc="${_escapeXMLAttribute(element.contentDesc)}"');
    }
    
    attributes.add('checkable="false"');
    attributes.add('checked="false"');
    attributes.add('clickable="${element.clickable}"');
    attributes.add('enabled="${element.enabled}"');
    attributes.add('focusable="false"');
    attributes.add('focused="false"');
    attributes.add('scrollable="false"');
    attributes.add('long-clickable="false"');
    attributes.add('password="false"');
    attributes.add('selected="false"');
    attributes.add('bounds="${element.boundsString}"');
    
    if (element.hasChildren) {
      buffer.writeln('$indent<node ${attributes.join(' ')}>');
      
      for (final child in element.children) {
        _writeElementToXML(child, buffer, indentLevel + 1);
      }
      
      buffer.writeln('$indent</node>');
    } else {
      buffer.writeln('$indent<node ${attributes.join(' ')} />');
    }
  }
  
  /// Escape special XML characters in attribute values
  String _escapeXMLAttribute(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
  
  /// Get file info including size and modification date
  Future<Map<String, dynamic>> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        throw FileOperationException(
          'File not found',
          'Path: $filePath',
        );
      }
      
      final stat = await file.stat();
      final fileName = path.basename(filePath);
      
      return {
        'name': fileName,
        'path': filePath,
        'size': stat.size,
        'modified': stat.modified,
        'sizeFormatted': _formatFileSize(stat.size),
      };
    } catch (e) {
      if (e is FileOperationException) {
        rethrow;
      }
      throw FileOperationException(
        'Failed to get file info',
        'Path: $filePath\nError: $e',
      );
    }
  }
  
  /// Format file size in human readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// Clean up old files (keep only the most recent N files)
  Future<void> cleanupOldFiles({int keepCount = 50}) async {
    try {
      final historyFiles = await getHistoryFiles();
      
      if (historyFiles.length > keepCount) {
        final filesToDelete = historyFiles.skip(keepCount);
        
        for (final filePath in filesToDelete) {
          await deleteFile(filePath);
        }
      }
    } catch (e) {
      throw FileOperationException(
        'Failed to cleanup old files',
        'Error: $e',
      );
    }
  }
  
  /// Get files filtered by date range
  Future<List<String>> getFilesByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final allFiles = await getHistoryFiles();
      final filteredFiles = <String>[];
      
      for (final filePath in allFiles) {
        final file = File(filePath);
        final stat = await file.stat();
        
        if (stat.modified.isAfter(startDate) && stat.modified.isBefore(endDate)) {
          filteredFiles.add(filePath);
        }
      }
      
      return filteredFiles;
    } catch (e) {
      throw FileOperationException(
        'Failed to filter files by date range',
        'Error: $e',
      );
    }
  }
}

/// Utility class for file system operations and dialogs
class FileSystemUtils {
  /// Open file in system default application (macOS)
  static Future<bool> openFileInSystem(String filePath) async {
    try {
      final result = await Process.run('open', [filePath]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  /// Open directory in Finder (macOS)
  static Future<bool> openDirectoryInFinder(String directoryPath) async {
    try {
      final result = await Process.run('open', [directoryPath]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  /// Get default export directory (Desktop)
  static Future<String> getDefaultExportDirectory() async {
    try {
      // Try to get Desktop directory
      final result = await Process.run('echo', [r'$HOME/Desktop']);
      if (result.exitCode == 0) {
        final desktopPath = result.stdout.toString().trim();
        final directory = Directory(desktopPath);
        if (await directory.exists()) {
          return desktopPath;
        }
      }
    } catch (e) {
      // Fallback to documents directory
    }
    
    // Fallback to documents directory
    final documentsDir = await getApplicationDocumentsDirectory();
    return documentsDir.path;
  }
  
  /// Generate unique filename if file already exists
  static Future<String> generateUniqueFilename(String basePath, String filename) async {
    String finalPath = path.join(basePath, filename);
    
    if (!await File(finalPath).exists()) {
      return finalPath;
    }
    
    final extension = path.extension(filename);
    final nameWithoutExtension = path.basenameWithoutExtension(filename);
    
    int counter = 1;
    do {
      final newFilename = '${nameWithoutExtension}_$counter$extension';
      finalPath = path.join(basePath, newFilename);
      counter++;
    } while (await File(finalPath).exists());
    
    return finalPath;
  }
  
  /// Validate filename for cross-platform compatibility
  static bool isValidFilename(String filename) {
    // Check for invalid characters
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(filename)) {
      return false;
    }
    
    // Check for reserved names (Windows)
    final reservedNames = [
      'CON', 'PRN', 'AUX', 'NUL',
      'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
      'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9'
    ];
    
    final nameWithoutExtension = path.basenameWithoutExtension(filename).toUpperCase();
    if (reservedNames.contains(nameWithoutExtension)) {
      return false;
    }
    
    // Check length
    if (filename.length > 255) {
      return false;
    }
    
    return true;
  }
}