import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import '../../controllers/ui_analyzer_state.dart';
import '../../services/file_manager.dart';
import '../../services/xml_parser.dart';

/// History panel that displays list of saved UI dump files
/// Supports file preview, loading, and management operations
class HistoryPanel extends StatefulWidget {
  final bool isDialog;
  final VoidCallback? onClose;
  
  const HistoryPanel({
    super.key,
    this.isDialog = false,
    this.onClose,
  });

  @override
  State<HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends State<HistoryPanel> {
  final FileManager _fileManager = FileManagerImpl();
  final XMLParser _xmlParser = XMLParser();
  
  List<Map<String, dynamic>> _historyFiles = [];
  bool _isLoading = false;
  String? _selectedFile;
  String _searchQuery = '';
  DateTimeRange? _dateFilter;
  Set<String> _selectedFiles = {};
  bool _isSelectionMode = false;
  
  @override
  void initState() {
    super.initState();
    _loadHistoryFiles();
  }

  Future<void> _loadHistoryFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final filePaths = await _fileManager.getHistoryFiles();
      final fileInfoList = <Map<String, dynamic>>[];

      for (final filePath in filePaths) {
        try {
          final file = File(filePath);
          final stat = await file.stat();
          final fileInfo = {
            'name': path.basename(filePath),
            'path': filePath,
            'size': stat.size,
            'modified': stat.modified,
            'sizeFormatted': _formatFileSize(stat.size),
          };
          fileInfoList.add(fileInfo);
        } catch (e) {
          // Skip files that can't be read
          debugPrint('Failed to get info for file $filePath: $e');
        }
      }

      setState(() {
        _historyFiles = fileInfoList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load history files: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredFiles {
    var filtered = _historyFiles;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((file) {
        final name = file['name'] as String;
        return name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply date filter
    if (_dateFilter != null) {
      filtered = filtered.where((file) {
        final modified = file['modified'] as DateTime;
        return modified.isAfter(_dateFilter!.start) && 
               modified.isBefore(_dateFilter!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog) {
      return Dialog(
        child: Container(
          width: 600,
          height: 500,
          child: _buildContent(),
        ),
      );
    }
    
    return _buildContent();
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        _buildSearchAndFilter(),
        Expanded(child: _buildFileList()),
        if (_selectedFile != null) _buildPreviewSection(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            _isSelectionMode ? 'Select Files' : 'History Files',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          if (_isSelectionMode) ...[
            Text(
              '(${_selectedFiles.length} selected)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const Spacer(),
          if (_isSelectionMode) ...[
            // Batch operations
            IconButton(
              onPressed: _selectedFiles.isEmpty ? null : _exportSelectedFiles,
              icon: const Icon(Icons.file_download),
              tooltip: 'Export Selected',
            ),
            IconButton(
              onPressed: _selectedFiles.isEmpty ? null : _deleteSelectedFiles,
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Selected',
              color: Theme.of(context).colorScheme.error,
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedFiles.clear();
                });
              },
              icon: const Icon(Icons.close),
              tooltip: 'Cancel Selection',
            ),
          ] else ...[
            // Selection mode toggle
            IconButton(
              onPressed: _filteredFiles.isEmpty ? null : () {
                setState(() {
                  _isSelectionMode = true;
                  _selectedFiles.clear();
                });
              },
              icon: const Icon(Icons.checklist),
              tooltip: 'Select Multiple',
            ),
            Text(
              '${_filteredFiles.length} files',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.onClose != null) ...[
              const SizedBox(width: 16),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
                tooltip: 'Close',
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search files...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Filter buttons
          Row(
            children: [
              // Date filter button
              OutlinedButton.icon(
                onPressed: _showDateFilter,
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(_dateFilter != null 
                    ? 'Date: ${_formatDateRange(_dateFilter!)}'
                    : 'Filter by Date'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _dateFilter != null 
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
              ),
              
              if (_dateFilter != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _dateFilter = null;
                    });
                  },
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear date filter',
                ),
              ],
              
              const Spacer(),
              
              // Batch cleanup button
              OutlinedButton.icon(
                onPressed: _historyFiles.isEmpty ? null : _showBatchCleanupDialog,
                icon: const Icon(Icons.cleaning_services, size: 18),
                label: const Text('Cleanup'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Refresh button
              IconButton(
                onPressed: _isLoading ? null : _loadHistoryFiles,
                icon: _isLoading 
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              _historyFiles.isEmpty 
                  ? 'No history files found'
                  : 'No files match your search',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _historyFiles.isEmpty
                  ? 'Capture some UI hierarchies to see them here'
                  : 'Try adjusting your search or date filter',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredFiles.length,
      itemBuilder: (context, index) {
        final file = _filteredFiles[index];
        return _buildFileItem(file);
      },
    );
  }

  Widget _buildFileItem(Map<String, dynamic> file) {
    final name = file['name'] as String;
    final path = file['path'] as String;
    final size = file['sizeFormatted'] as String;
    final modified = file['modified'] as DateTime;
    final isSelected = _selectedFile == path;
    final isChecked = _selectedFiles.contains(path);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isSelected ? 4 : 1,
      color: isSelected 
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: ListTile(
        leading: _isSelectionMode 
            ? Checkbox(
                value: isChecked,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedFiles.add(path);
                    } else {
                      _selectedFiles.remove(path);
                    }
                  });
                },
              )
            : Icon(
                Icons.description,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected 
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDateTime(modified),
              style: TextStyle(
                color: isSelected 
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              size,
              style: TextStyle(
                fontSize: 12,
                color: isSelected 
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        trailing: _isSelectionMode 
            ? null
            : PopupMenuButton<String>(
                onSelected: (action) => _handleFileAction(action, file),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'load',
                    child: ListTile(
                      leading: Icon(Icons.open_in_new),
                      title: Text('Load'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'preview',
                    child: ListTile(
                      leading: Icon(Icons.preview),
                      title: Text('Preview'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: ListTile(
                      leading: Icon(Icons.file_download),
                      title: Text('Export'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: ListTile(
                      leading: Icon(Icons.share),
                      title: Text('Share'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                      dense: true,
                    ),
                  ),
                ],
              ),
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isChecked) {
                _selectedFiles.remove(path);
              } else {
                _selectedFiles.add(path);
              }
            });
          } else {
            setState(() {
              _selectedFile = isSelected ? null : path;
            });
          }
        },
        onLongPress: _isSelectionMode ? null : () => _handleFileAction('load', file),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.preview, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Preview',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _handleFileAction('load', 
                      _historyFiles.firstWhere((f) => f['path'] == _selectedFile)),
                  child: const Text('Load File'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<String>(
              future: _loadFilePreview(_selectedFile!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load preview: ${snapshot.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  );
                }
                
                final content = snapshot.data ?? '';
                final lines = content.split('\n');
                final previewLines = lines.take(5).join('\n');
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SingleChildScrollView(
                    child: Text(
                      previewLines + (lines.length > 5 ? '\n...' : ''),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _loadFilePreview(String filePath) async {
    try {
      final content = await _fileManager.readFile(filePath);
      return content;
    } catch (e) {
      throw Exception('Failed to load file: $e');
    }
  }

  void _handleFileAction(String action, Map<String, dynamic> file) async {
    final filePath = file['path'] as String;
    
    switch (action) {
      case 'load':
        await _loadFile(filePath);
        break;
      case 'preview':
        setState(() {
          _selectedFile = _selectedFile == filePath ? null : filePath;
        });
        break;
      case 'export':
        await _exportFile(file);
        break;
      case 'share':
        await _shareFile(file);
        break;
      case 'delete':
        await _deleteFile(file);
        break;
    }
  }

  Future<void> _loadFile(String filePath) async {
    try {
      final state = Provider.of<UIAnalyzerState>(context, listen: false);
      state.setLoading(true, 'Loading UI hierarchy...');

      final xmlContent = await _fileManager.readFile(filePath);
      final rootElement = await _xmlParser.parseXMLString(xmlContent);
      
      state.setUIHierarchy(rootElement, xmlContent: xmlContent);
      state.setCurrentHistoryFile(filePath);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded: ${path.basename(filePath)}'),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Close dialog if this is a dialog
        if (widget.isDialog && widget.onClose != null) {
          widget.onClose!();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load file: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      final state = Provider.of<UIAnalyzerState>(context, listen: false);
      state.setLoading(false);
    }
  }

  Future<void> _exportFile(Map<String, dynamic> file) async {
    try {
      // Get default export directory (Desktop)
      final exportDir = await FileSystemUtils.getDefaultExportDirectory();
      final fileName = file['name'] as String;
      final sourcePath = file['path'] as String;
      
      // Generate unique filename if file already exists
      final exportPath = await FileSystemUtils.generateUniqueFilename(exportDir, fileName);
      
      // Copy file to export location
      final sourceFile = File(sourcePath);
      final exportFile = File(exportPath);
      await sourceFile.copy(exportPath);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported: ${path.basename(exportPath)}'),
            action: SnackBarAction(
              label: 'Open Folder',
              onPressed: () => FileSystemUtils.openDirectoryInFinder(exportDir),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export file: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteFile(Map<String, dynamic> file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _fileManager.deleteFile(file['path'] as String);
        
        // Remove from local list
        setState(() {
          _historyFiles.removeWhere((f) => f['path'] == file['path']);
          if (_selectedFile == file['path']) {
            _selectedFile = null;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted: ${file['name']}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete file: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _showDateFilter() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateFilter,
    );

    if (picked != null) {
      setState(() {
        _dateFilter = picked;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateRange(DateTimeRange range) {
    return '${range.start.day}/${range.start.month} - ${range.end.day}/${range.end.month}';
  }

  Future<void> _shareFile(Map<String, dynamic> file) async {
    try {
      final filePath = file['path'] as String;
      final fileName = file['name'] as String;
      
      // For macOS, we can open the file in Finder for sharing
      final success = await FileSystemUtils.openFileInSystem(filePath);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opened $fileName in system'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Failed to open file in system');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share file: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _exportSelectedFiles() async {
    if (_selectedFiles.isEmpty) return;

    try {
      final exportDir = await FileSystemUtils.getDefaultExportDirectory();
      final exportedFiles = <String>[];
      
      for (final filePath in _selectedFiles) {
        final file = _historyFiles.firstWhere((f) => f['path'] == filePath);
        final fileName = file['name'] as String;
        
        // Generate unique filename
        final exportPath = await FileSystemUtils.generateUniqueFilename(exportDir, fileName);
        
        // Copy file
        final sourceFile = File(filePath);
        await sourceFile.copy(exportPath);
        exportedFiles.add(path.basename(exportPath));
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${exportedFiles.length} files'),
            action: SnackBarAction(
              label: 'Open Folder',
              onPressed: () => FileSystemUtils.openDirectoryInFinder(exportDir),
            ),
          ),
        );
        
        // Exit selection mode
        setState(() {
          _isSelectionMode = false;
          _selectedFiles.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export files: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteSelectedFiles() async {
    if (_selectedFiles.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Files'),
        content: Text('Are you sure you want to delete ${_selectedFiles.length} selected files?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final deletedCount = _selectedFiles.length;
        
        for (final filePath in _selectedFiles) {
          await _fileManager.deleteFile(filePath);
          
          // Remove from local list
          _historyFiles.removeWhere((f) => f['path'] == filePath);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted $deletedCount files'),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Exit selection mode and refresh
        setState(() {
          _isSelectionMode = false;
          _selectedFiles.clear();
          if (_selectedFile != null && !_historyFiles.any((f) => f['path'] == _selectedFile)) {
            _selectedFile = null;
          }
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete files: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _showBatchCleanupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batch Cleanup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose cleanup options:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Keep only recent files'),
              subtitle: const Text('Keep last 50 files, delete older ones'),
              onTap: () {
                Navigator.of(context).pop();
                _performBatchCleanup(CleanupType.keepRecent);
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Delete files older than 30 days'),
              subtitle: const Text('Remove files created more than 30 days ago'),
              onTap: () {
                Navigator.of(context).pop();
                _performBatchCleanup(CleanupType.olderThan30Days);
              },
            ),
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('Delete large files'),
              subtitle: const Text('Remove files larger than 1MB'),
              onTap: () {
                Navigator.of(context).pop();
                _performBatchCleanup(CleanupType.largFiles);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBatchCleanup(CleanupType type) async {
    try {
      List<String> filesToDelete = [];
      
      switch (type) {
        case CleanupType.keepRecent:
          if (_historyFiles.length > 50) {
            // Sort by modification date and keep only the 50 most recent
            final sortedFiles = List<Map<String, dynamic>>.from(_historyFiles);
            sortedFiles.sort((a, b) => (b['modified'] as DateTime).compareTo(a['modified'] as DateTime));
            filesToDelete = sortedFiles.skip(50).map((f) => f['path'] as String).toList();
          }
          break;
          
        case CleanupType.olderThan30Days:
          final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
          filesToDelete = _historyFiles
              .where((f) => (f['modified'] as DateTime).isBefore(cutoffDate))
              .map((f) => f['path'] as String)
              .toList();
          break;
          
        case CleanupType.largFiles:
          const maxSize = 1024 * 1024; // 1MB
          filesToDelete = _historyFiles
              .where((f) => (f['size'] as int) > maxSize)
              .map((f) => f['path'] as String)
              .toList();
          break;
      }
      
      if (filesToDelete.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No files match the cleanup criteria'),
            ),
          );
        }
        return;
      }
      
      // Confirm deletion
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Cleanup'),
          content: Text('This will delete ${filesToDelete.length} files. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        // Perform deletion
        for (final filePath in filesToDelete) {
          await _fileManager.deleteFile(filePath);
        }
        
        // Refresh the file list
        await _loadHistoryFiles();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cleanup completed: ${filesToDelete.length} files deleted'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cleanup failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Format file size in human readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

enum CleanupType {
  keepRecent,
  olderThan30Days,
  largFiles,
}

/// Static methods for showing history panel
class HistoryPanelDialog {
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const HistoryPanel(isDialog: true),
    );
  }
}