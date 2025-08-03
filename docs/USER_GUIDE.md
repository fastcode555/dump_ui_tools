# Android UI Analyzer Tool - User Guide

## Overview

The Android UI Analyzer Tool is a Flutter desktop application designed to help developers analyze Android UI hierarchies from XML dump files. This tool provides an intuitive interface for exploring UI structures, searching elements, and understanding layout relationships.

## Features

### Core Functionality
- **UI Hierarchy Visualization**: View Android UI structures in an interactive tree format
- **Element Search & Filtering**: Find specific UI elements using various criteria
- **Property Inspection**: Examine detailed properties of UI elements
- **Visual Preview**: See element positions on a scaled device screen
- **XML Viewing**: View and export raw XML dump files with syntax highlighting
- **History Management**: Access previously captured UI dumps

### Key Benefits
- Accelerate UI automation test development
- Debug layout issues and accessibility problems
- Understand complex UI hierarchies
- Export data for further analysis

## Getting Started

### Prerequisites
- macOS (primary supported platform)
- Android device with USB debugging enabled
- ADB (Android Debug Bridge) installed and accessible

### Installation
1. Download the latest release from the releases page
2. Extract the application to your Applications folder
3. Ensure ADB is installed and available in your PATH

### First Launch
1. Connect your Android device via USB
2. Enable USB debugging on your device
3. Launch the Android UI Analyzer Tool
4. The app will automatically detect connected devices

## User Interface

### Main Window Layout
The application uses a multi-panel layout:

```
┌─────────────────────────────────────────────────────────┐
│                    Toolbar                              │
├─────────────────────┬───────────────────────────────────┤
│                     │                                   │
│   Tree View Panel   │        Property Panel            │
│                     │                                   │
│                     ├───────────────────────────────────┤
│                     │                                   │
│                     │       Preview Panel               │
│                     │                                   │
├─────────────────────┴───────────────────────────────────┤
│                XML Viewer Panel                         │
└─────────────────────────────────────────────────────────┘
```

### Toolbar
- **Device Selector**: Choose from connected Android devices
- **Capture UI**: Get current UI hierarchy from selected device
- **Theme Toggle**: Switch between light and dark themes
- **Settings**: Access application preferences

### Tree View Panel (Left)
- **Search Bar**: Real-time search across UI elements
- **Filter Options**: Quick filters for clickable, input, and text elements
- **Hierarchy Tree**: Interactive tree showing UI structure
- **Element Count**: Display of total and filtered elements

### Property Panel (Right Top)
- **Element Details**: Complete property list for selected element
- **Copy Values**: Click any property value to copy to clipboard
- **Bounds Information**: Parsed coordinate and dimension data

### Preview Panel (Right Bottom)
- **Visual Layout**: Scaled representation of device screen
- **Element Highlighting**: Selected elements highlighted in preview
- **Interactive Selection**: Click preview to select corresponding element
- **Zoom Controls**: Scale preview for better visibility

### XML Viewer Panel (Bottom)
- **Syntax Highlighting**: Color-coded XML display
- **Collapsible**: Hide/show panel as needed
- **Export Options**: Save XML to file
- **Search**: Find text within XML content

## Basic Workflow

### 1. Connect Device
1. Connect Android device via USB
2. Ensure USB debugging is enabled
3. Select device from dropdown in toolbar

### 2. Capture UI Hierarchy
1. Navigate to the screen you want to analyze on your device
2. Click "Capture UI" button in toolbar
3. Wait for capture to complete (progress indicator will show)

### 3. Explore UI Structure
1. Use the tree view to navigate the hierarchy
2. Click elements to see their properties
3. Use search and filters to find specific elements
4. View element positions in the preview panel

### 4. Export Data
1. Use "Export XML" to save raw dump file
2. Copy specific property values as needed
3. Access history panel for previous captures

## Advanced Features

### Search and Filtering

#### Search Options
- **Text Search**: Find elements containing specific text
- **Resource ID Search**: Locate elements by resource identifier
- **Class Name Search**: Filter by Android view class
- **Content Description Search**: Find accessibility labels

#### Filter Types
- **Clickable Elements**: Show only interactive elements
- **Input Fields**: Display text input elements only
- **Elements with Text**: Show elements containing text content
- **Enabled Elements**: Filter by enabled state
- **Custom Filters**: Create complex filter combinations

### Keyboard Shortcuts
- `Cmd+F`: Focus search bar
- `Cmd+R`: Refresh/capture UI
- `Cmd+E`: Export current XML
- `Cmd+T`: Toggle theme
- `Cmd+H`: Show/hide history panel
- `Cmd+X`: Show/hide XML viewer
- `Escape`: Clear search/selection

### History Management
- Automatic saving of all UI captures
- Timestamp-based file naming
- Quick access to recent captures
- Bulk delete options for cleanup

## Troubleshooting

### Common Issues

#### Device Not Detected
**Problem**: Device doesn't appear in dropdown
**Solutions**:
1. Verify USB debugging is enabled
2. Check USB cable connection
3. Ensure ADB is installed and in PATH
4. Try different USB port
5. Restart ADB server: `adb kill-server && adb start-server`

#### UI Capture Fails
**Problem**: Error when capturing UI hierarchy
**Solutions**:
1. Ensure device is unlocked
2. Check if app has accessibility permissions
3. Try capturing from a different screen
4. Restart the target application
5. Check device storage space

#### Performance Issues
**Problem**: Slow response with large UI hierarchies
**Solutions**:
1. Use filters to reduce displayed elements
2. Close unnecessary applications on device
3. Increase application memory allocation
4. Use search instead of browsing large trees

#### Export Problems
**Problem**: Cannot save XML files
**Solutions**:
1. Check file system permissions
2. Ensure sufficient disk space
3. Try different export location
4. Restart application

### Error Messages

#### "ADB not found"
- Install Android SDK platform tools
- Add ADB to system PATH
- Restart application

#### "Device unauthorized"
- Check device for USB debugging prompt
- Accept debugging authorization
- Ensure device is unlocked

#### "XML parsing failed"
- Capture may be corrupted
- Try capturing again
- Check device accessibility settings

## Tips and Best Practices

### Efficient UI Analysis
1. **Use Filters First**: Apply relevant filters before searching
2. **Search Strategically**: Use specific terms for faster results
3. **Leverage Preview**: Click preview areas for quick element selection
4. **Copy Properties**: Use click-to-copy for automation scripts

### Automation Development
1. **Resource IDs**: Prefer resource-id for stable element identification
2. **Text Content**: Use text as secondary identifier
3. **Hierarchy Paths**: Note parent-child relationships for complex selections
4. **Bounds Information**: Use coordinates for gesture automation

### Performance Optimization
1. **Regular Cleanup**: Delete old history files periodically
2. **Targeted Captures**: Capture specific screens rather than complex flows
3. **Filter Early**: Apply filters before expanding large trees
4. **Close Unused Panels**: Hide XML viewer when not needed

## Support and Feedback

### Getting Help
- Check this user guide for common solutions
- Review error messages for specific guidance
- Consult the developer documentation for technical details

### Reporting Issues
When reporting problems, please include:
- Operating system version
- Device model and Android version
- Steps to reproduce the issue
- Error messages or screenshots
- Sample XML files if relevant

### Feature Requests
We welcome suggestions for new features and improvements. Consider:
- Specific use cases for the feature
- How it would improve your workflow
- Any similar tools that implement the feature

## Appendix

### Supported Android Versions
- Android 4.1 (API 16) and higher
- UIAutomator framework required
- Accessibility services recommended

### File Formats
- **Input**: XML files from `uiautomator dump`
- **Export**: Standard XML format
- **History**: Timestamped XML files

### System Requirements
- **macOS**: 10.14 or later
- **Memory**: 4GB RAM minimum, 8GB recommended
- **Storage**: 100MB for application, additional space for history files
- **Display**: 1280x800 minimum resolution

---

*This guide covers the essential features and workflows of the Android UI Analyzer Tool. For technical implementation details, see the Developer Documentation.*