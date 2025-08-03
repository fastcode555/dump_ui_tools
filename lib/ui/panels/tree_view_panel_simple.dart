import 'package:flutter/material.dart';

/// Simple tree view panel for testing
class TreeViewPanelSimple extends StatelessWidget {
  const TreeViewPanelSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      child: const Center(
        child: Text('Tree View Panel'),
      ),
    );
  }
}