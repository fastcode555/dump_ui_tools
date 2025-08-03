import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../lib/controllers/ui_analyzer_state.dart';
import '../lib/models/ui_element.dart';
import '../lib/ui/panels/preview_panel.dart';

void main() {
  runApp(const PreviewPanelDemo());
}

class PreviewPanelDemo extends StatelessWidget {
  const PreviewPanelDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Preview Panel Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ChangeNotifierProvider(
        create: (context) => UIAnalyzerState(),
        child: const PreviewPanelDemoPage(),
      ),
    );
  }
}

class PreviewPanelDemoPage extends StatefulWidget {
  const PreviewPanelDemoPage({super.key});

  @override
  State<PreviewPanelDemoPage> createState() => _PreviewPanelDemoPageState();
}

class _PreviewPanelDemoPageState extends State<PreviewPanelDemoPage> {
  @override
  void initState() {
    super.initState();
    _setupMockUIHierarchy();
  }

  void _setupMockUIHierarchy() {
    final state = context.read<UIAnalyzerState>();
    
    // Create a mock UI hierarchy
    final rootElement = UIElement(
      id: 'root',
      depth: 0,
      className: 'android.widget.FrameLayout',
      packageName: 'com.example.demo',
      bounds: const Rect.fromLTWH(0, 0, 1080, 1920),
    );

    // Header
    final headerElement = UIElement(
      id: 'header',
      depth: 1,
      className: 'android.widget.LinearLayout',
      packageName: 'com.example.demo',
      bounds: const Rect.fromLTWH(0, 0, 1080, 200),
    );

    final titleElement = UIElement(
      id: 'title',
      depth: 2,
      text: 'Demo App',
      className: 'android.widget.TextView',
      packageName: 'com.example.demo',
      resourceId: 'com.example.demo:id/title',
      bounds: const Rect.fromLTWH(50, 50, 980, 100),
    );

    // Main content
    final contentElement = UIElement(
      id: 'content',
      depth: 1,
      className: 'android.widget.ScrollView',
      packageName: 'com.example.demo',
      bounds: const Rect.fromLTWH(0, 200, 1080, 1520),
    );

    final buttonElement = UIElement(
      id: 'button1',
      depth: 2,
      text: 'Click Me',
      className: 'android.widget.Button',
      packageName: 'com.example.demo',
      resourceId: 'com.example.demo:id/button1',
      clickable: true,
      bounds: const Rect.fromLTWH(100, 300, 880, 120),
    );

    final inputElement = UIElement(
      id: 'input1',
      depth: 2,
      text: 'Enter text here',
      className: 'android.widget.EditText',
      packageName: 'com.example.demo',
      resourceId: 'com.example.demo:id/input1',
      clickable: true,
      bounds: const Rect.fromLTWH(100, 500, 880, 80),
    );

    final imageElement = UIElement(
      id: 'image1',
      depth: 2,
      contentDesc: 'Profile picture',
      className: 'android.widget.ImageView',
      packageName: 'com.example.demo',
      resourceId: 'com.example.demo:id/profile_image',
      bounds: const Rect.fromLTWH(400, 650, 280, 280),
    );

    // Build hierarchy
    rootElement.addChild(headerElement);
    headerElement.addChild(titleElement);
    
    rootElement.addChild(contentElement);
    contentElement.addChild(buttonElement);
    contentElement.addChild(inputElement);
    contentElement.addChild(imageElement);

    // Set the hierarchy
    state.setUIHierarchy(rootElement);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Preview Panel Demo'),
      ),
      body: Row(
        children: [
          // Left panel - Element info
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: Consumer<UIAnalyzerState>(
                builder: (context, state, child) {
                  final selectedElement = state.selectedElement;
                  
                  if (selectedElement == null) {
                    return const Center(
                      child: Text(
                        'Click on an element in the preview to see its details',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Element',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildInfoRow('ID', selectedElement.id),
                      _buildInfoRow('Class', selectedElement.className.split('.').last),
                      _buildInfoRow('Text', selectedElement.text.isEmpty ? '(none)' : selectedElement.text),
                      _buildInfoRow('Resource ID', selectedElement.resourceId.isEmpty ? '(none)' : selectedElement.resourceId),
                      _buildInfoRow('Bounds', selectedElement.boundsString),
                      _buildInfoRow('Clickable', selectedElement.clickable ? 'Yes' : 'No'),
                      _buildInfoRow('Enabled', selectedElement.enabled ? 'Yes' : 'No'),
                      
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          state.selectElement(null);
                        },
                        child: const Text('Clear Selection'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          
          // Right panel - Preview
          Expanded(
            flex: 2,
            child: const PreviewPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}