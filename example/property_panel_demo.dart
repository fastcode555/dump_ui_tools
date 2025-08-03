import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../lib/ui/panels/property_panel.dart';
import '../lib/controllers/ui_analyzer_state.dart';
import '../lib/models/ui_element.dart';

/// Demo showing the PropertyPanel functionality
void main() {
  runApp(const PropertyPanelDemo());
}

class PropertyPanelDemo extends StatelessWidget {
  const PropertyPanelDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Property Panel Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: ChangeNotifierProvider(
        create: (context) => UIAnalyzerState(),
        child: const PropertyPanelDemoPage(),
      ),
    );
  }
}

class PropertyPanelDemoPage extends StatelessWidget {
  const PropertyPanelDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Panel Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Row(
        children: [
          // Left side - Element selection
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select an element:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildElementButton(
                    context,
                    'Button Element',
                    UIElement(
                      id: 'button-1',
                      depth: 1,
                      text: 'Click Me',
                      contentDesc: 'Action button',
                      className: 'android.widget.Button',
                      packageName: 'com.example.demo',
                      resourceId: 'com.example.demo:id/action_button',
                      clickable: true,
                      enabled: true,
                      bounds: const Rect.fromLTWH(100, 200, 200, 60),
                      index: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildElementButton(
                    context,
                    'TextView Element',
                    UIElement(
                      id: 'textview-1',
                      depth: 2,
                      text: 'Hello World! This is a longer text to demonstrate text wrapping.',
                      contentDesc: 'Greeting message',
                      className: 'android.widget.TextView',
                      packageName: 'com.example.demo',
                      resourceId: 'com.example.demo:id/greeting_text',
                      clickable: false,
                      enabled: true,
                      bounds: const Rect.fromLTWH(50, 100, 300, 80),
                      index: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildElementButton(
                    context,
                    'EditText Element',
                    UIElement(
                      id: 'edittext-1',
                      depth: 1,
                      text: '',
                      contentDesc: 'Enter your name',
                      className: 'android.widget.EditText',
                      packageName: 'com.example.demo',
                      resourceId: 'com.example.demo:id/name_input',
                      clickable: true,
                      enabled: true,
                      bounds: const Rect.fromLTWH(80, 300, 250, 50),
                      index: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<UIAnalyzerState>().selectElement(null);
                    },
                    child: const Text('Clear Selection'),
                  ),
                ],
              ),
            ),
          ),
          
          // Divider
          const VerticalDivider(),
          
          // Right side - Property panel
          Expanded(
            flex: 2,
            child: const PropertyPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildElementButton(BuildContext context, String label, UIElement element) {
    return Consumer<UIAnalyzerState>(
      builder: (context, state, child) {
        final isSelected = state.selectedElement?.id == element.id;
        
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              state.selectElement(element);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : null,
              foregroundColor: isSelected 
                  ? Theme.of(context).colorScheme.onPrimary
                  : null,
            ),
            child: Text(label),
          ),
        );
      },
    );
  }
}