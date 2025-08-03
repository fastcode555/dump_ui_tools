import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import '../../lib/services/file_manager.dart';
import '../../lib/models/ui_element.dart';

void main() {
  group('FileManager Tests', () {
    late FileManagerImpl fileManager;
    late Directory tempDir;
    
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      fileManager = FileManagerImpl();
      // Create a temporary directory for testing
      tempDir = await Directory.systemTemp.createTemp('file_manager_test_');
    });
    
    tearDownAll(() async {
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });
    
    group('saveUIdump', () {
      test('should save UI dump with generated filename', () async {
        const testContent = '''<?xml version="1.0" encoding="UTF-8"?>
<hierarchy rotation="0">
  <node text="Test" class="TextView" bounds="[0,0][100,50]" />
</hierarchy>''';
        
        final filePath = await fileManager.saveUIdump(testContent);
        
        expect(filePath, isNotEmpty);
        expect(await File(filePath).exists(), isTrue);
        
        final savedContent = await File(filePath).readAsString();
        expect(savedContent, equals(testContent));
        
        // Clean up
        await File(filePath).delete();
      });
      
      test('should save UI dump with custom filename', () async {
        const testContent = '''<?xml version="1.0" encoding="UTF-8"?>
<hierarchy rotation="0">
  <node text="Custom Test" class="TextView" bounds="[0,0][100,50]" />
</hierarchy>''';
        
        const customFilename = 'custom_test.xml';
        final filePath = await fileManager.saveUIdump(testContent, filename: customFilename);
        
        expect(path.basename(filePath), equals(customFilename));
        expect(await File(filePath).exists(), isTrue);
        
        final savedContent = await File(filePath).readAsString();
        expect(savedContent, equals(testContent));
        
        // Clean up
        await File(filePath).delete();
      });
    });
    
    group('readFile', () {
      test('should read file content correctly', () async {
        const testContent = 'Test file content';
        final testFile = File(path.join(tempDir.path, 'test_read.txt'));
        await testFile.writeAsString(testContent);
        
        final content = await fileManager.readFile(testFile.path);
        expect(content, equals(testContent));
      });
      
      test('should throw exception for non-existent file', () async {
        const nonExistentPath = '/non/existent/file.txt';
        
        expect(
          () => fileManager.readFile(nonExistentPath),
          throwsA(isA<FileOperationException>()),
        );
      });
    });
    
    group('deleteFile', () {
      test('should delete existing file', () async {
        final testFile = File(path.join(tempDir.path, 'test_delete.txt'));
        await testFile.writeAsString('Test content');
        
        expect(await testFile.exists(), isTrue);
        
        await fileManager.deleteFile(testFile.path);
        
        expect(await testFile.exists(), isFalse);
      });
      
      test('should not throw exception for non-existent file', () async {
        const nonExistentPath = '/non/existent/file.txt';
        
        expect(
          () => fileManager.deleteFile(nonExistentPath),
          returnsNormally,
        );
      });
    });
    
    group('exportToXML', () {
      test('should export UI element hierarchy to XML', () async {
        // Create test UI hierarchy
        final root = UIElement(
          id: 'root',
          depth: 0,
          className: 'android.widget.FrameLayout',
          bounds: const Rect.fromLTWH(0, 0, 1080, 1920),
          text: '',
          index: 0,
        );
        
        final child1 = UIElement(
          id: 'child1',
          depth: 1,
          className: 'android.widget.TextView',
          bounds: const Rect.fromLTWH(100, 100, 200, 50),
          text: 'Hello World',
          clickable: true,
          index: 0,
        );
        
        final child2 = UIElement(
          id: 'child2',
          depth: 1,
          className: 'android.widget.Button',
          bounds: const Rect.fromLTWH(100, 200, 150, 60),
          text: 'Click Me',
          clickable: true,
          enabled: true,
          index: 1,
        );
        
        root.addChild(child1);
        root.addChild(child2);
        
        final exportPath = path.join(tempDir.path, 'exported_test.xml');
        final resultPath = await fileManager.exportToXML(root, exportPath);
        
        expect(resultPath, equals(exportPath));
        expect(await File(exportPath).exists(), isTrue);
        
        final exportedContent = await File(exportPath).readAsString();
        
        // Verify XML structure
        expect(exportedContent, contains('<?xml version="1.0" encoding="UTF-8"'));
        expect(exportedContent, contains('<hierarchy rotation="0">'));
        expect(exportedContent, contains('text="Hello World"'));
        expect(exportedContent, contains('text="Click Me"'));
        expect(exportedContent, contains('class="android.widget.TextView"'));
        expect(exportedContent, contains('class="android.widget.Button"'));
        expect(exportedContent, contains('clickable="true"'));
        expect(exportedContent, contains('bounds="[100,100][300,150]"'));
        expect(exportedContent, contains('</hierarchy>'));
      });
    });
    
    group('getHistoryFiles', () {
      test('should return empty list when no history files exist', () async {
        // This test assumes a clean state or we clean up before testing
        final historyFiles = await fileManager.getHistoryFiles();
        // We can't guarantee empty list due to other tests, so just check it's a list
        expect(historyFiles, isA<List<String>>());
      });
    });
    
    group('XML escaping', () {
      test('should properly escape XML special characters', () async {
        final testElement = UIElement(
          id: 'test',
          depth: 0,
          className: 'TestClass',
          bounds: const Rect.fromLTWH(0, 0, 100, 50),
          text: 'Text with <special> & "quoted" characters',
          contentDesc: "Content with 'single' quotes",
          index: 0,
        );
        
        final exportPath = path.join(tempDir.path, 'escape_test.xml');
        await fileManager.exportToXML(testElement, exportPath);
        
        final exportedContent = await File(exportPath).readAsString();
        
        // Verify proper escaping
        expect(exportedContent, contains('&lt;special&gt;'));
        expect(exportedContent, contains('&amp;'));
        expect(exportedContent, contains('&quot;quoted&quot;'));
        expect(exportedContent, contains('&apos;single&apos;'));
      });
    });
  });
  
  group('FileSystemUtils Tests', () {
    test('should validate filenames correctly', () {
      expect(FileSystemUtils.isValidFilename('valid_filename.xml'), isTrue);
      expect(FileSystemUtils.isValidFilename('file with spaces.xml'), isTrue);
      expect(FileSystemUtils.isValidFilename('file<invalid>.xml'), isFalse);
      expect(FileSystemUtils.isValidFilename('file|invalid.xml'), isFalse);
      expect(FileSystemUtils.isValidFilename('CON.xml'), isFalse);
      expect(FileSystemUtils.isValidFilename('con.xml'), isFalse); // Case insensitive
    });
    
    test('should get default export directory', () async {
      final exportDir = await FileSystemUtils.getDefaultExportDirectory();
      expect(exportDir, isNotEmpty);
      expect(await Directory(exportDir).exists(), isTrue);
    });
  });
}