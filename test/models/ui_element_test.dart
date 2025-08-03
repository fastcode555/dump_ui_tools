import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dump_ui_tools/models/ui_element.dart';

void main() {
  group('UIElement', () {
    late UIElement testElement;
    
    setUp(() {
      testElement = UIElement(
        id: 'test_element_1',
        depth: 1,
        text: 'Test Button',
        contentDesc: 'Test button description',
        className: 'android.widget.Button',
        packageName: 'com.example.app',
        resourceId: 'com.example.app:id/test_button',
        clickable: true,
        enabled: true,
        bounds: const Rect.fromLTRB(10, 20, 110, 70),
        index: 0,
      );
    });

    group('Constructor and Properties', () {
      test('should create UIElement with all properties', () {
        expect(testElement.id, equals('test_element_1'));
        expect(testElement.depth, equals(1));
        expect(testElement.text, equals('Test Button'));
        expect(testElement.contentDesc, equals('Test button description'));
        expect(testElement.className, equals('android.widget.Button'));
        expect(testElement.packageName, equals('com.example.app'));
        expect(testElement.resourceId, equals('com.example.app:id/test_button'));
        expect(testElement.clickable, isTrue);
        expect(testElement.enabled, isTrue);
        expect(testElement.bounds, equals(const Rect.fromLTRB(10, 20, 110, 70)));
        expect(testElement.index, equals(0));
      });

      test('should have empty children list initially', () {
        expect(testElement.children, isEmpty);
        expect(testElement.hasChildren, isFalse);
        expect(testElement.childCount, equals(0));
      });

      test('should have null parent initially', () {
        expect(testElement.parent, isNull);
      });
    });

    group('Computed Properties', () {
      test('should calculate width and height correctly', () {
        expect(testElement.width, equals(100.0));
        expect(testElement.height, equals(50.0));
      });

      test('should return display text correctly', () {
        expect(testElement.displayText, equals('Test Button'));
        
        // Test with empty text but content description
        final elementWithContentDesc = UIElement(
          id: 'test_2',
          depth: 1,
          text: '',
          contentDesc: 'Content description',
          className: 'android.widget.View',
          packageName: '',
          resourceId: '',
          clickable: false,
          enabled: true,
          bounds: Rect.zero,
          index: 0,
        );
        expect(elementWithContentDesc.displayText, equals('Content description'));
        
        // Test with both empty
        final elementWithoutText = UIElement(
          id: 'test_3',
          depth: 1,
          text: '',
          contentDesc: '',
          className: 'android.widget.View',
          packageName: '',
          resourceId: '',
          clickable: false,
          enabled: true,
          bounds: Rect.zero,
          index: 0,
        );
        expect(elementWithoutText.displayText, equals('View'));
      });

      test('should return simple class name correctly', () {
        expect(testElement.simpleClassName, equals('Button'));
        
        final elementWithSimpleClass = UIElement(
          id: 'test_4',
          depth: 1,
          text: '',
          contentDesc: '',
          className: 'TextView',
          packageName: '',
          resourceId: '',
          clickable: false,
          enabled: true,
          bounds: Rect.zero,
          index: 0,
        );
        expect(elementWithSimpleClass.simpleClassName, equals('TextView'));
      });
    });

    group('Hierarchy Management', () {
      test('should add child correctly', () {
        final child = UIElement(
          id: 'child_1',
          depth: 2,
          text: 'Child Element',
          contentDesc: '',
          className: 'android.widget.TextView',
          packageName: '',
          resourceId: '',
          clickable: false,
          enabled: true,
          bounds: Rect.zero,
          index: 0,
        );

        testElement.addChild(child);

        expect(testElement.children, contains(child));
        expect(testElement.hasChildren, isTrue);
        expect(testElement.childCount, equals(1));
        expect(child.parent, equals(testElement));
      });

      test('should remove child correctly', () {
        final child = UIElement(
          id: 'child_1',
          depth: 2,
          text: 'Child Element',
          contentDesc: '',
          className: 'android.widget.TextView',
          packageName: '',
          resourceId: '',
          clickable: false,
          enabled: true,
          bounds: Rect.zero,
          index: 0,
        );

        testElement.addChild(child);
        expect(testElement.hasChildren, isTrue);

        testElement.removeChild(child);
        expect(testElement.children, isNot(contains(child)));
        expect(testElement.hasChildren, isFalse);
        expect(testElement.childCount, equals(0));
        expect(child.parent, isNull);
      });

      test('should handle multiple children correctly', () {
        final child1 = _createTestChild('child_1', 0);
        final child2 = _createTestChild('child_2', 1);
        final child3 = _createTestChild('child_3', 2);

        testElement.addChild(child1);
        testElement.addChild(child2);
        testElement.addChild(child3);

        expect(testElement.childCount, equals(3));
        expect(testElement.children, containsAll([child1, child2, child3]));
        expect(child1.parent, equals(testElement));
        expect(child2.parent, equals(testElement));
        expect(child3.parent, equals(testElement));
      });
    });

    group('Search and Find Methods', () {
      late UIElement rootElement;
      late UIElement child1;
      late UIElement child2;
      late UIElement grandchild1;

      setUp(() {
        rootElement = _createTestElement('root', 0, 'Root Element');
        child1 = _createTestElement('child1', 1, 'Login Button');
        child2 = _createTestElement('child2', 1, 'Password Field');
        grandchild1 = _createTestElement('grandchild1', 2, 'Submit');

        rootElement.addChild(child1);
        rootElement.addChild(child2);
        child1.addChild(grandchild1);
      });

      test('should find elements by text', () {
        final results = rootElement.findByText('Login');
        expect(results, contains(child1));
        expect(results.length, equals(1));

        final noResults = rootElement.findByText('NonExistent');
        expect(noResults, isEmpty);
      });

      test('should find elements by resource ID', () {
        child1 = UIElement(
          id: 'child1',
          depth: 1,
          text: 'Login Button',
          contentDesc: '',
          className: 'android.widget.Button',
          packageName: '',
          resourceId: 'com.example:id/login_btn',
          clickable: true,
          enabled: true,
          bounds: Rect.zero,
          index: 0,
        );
        rootElement.addChild(child1);

        final results = rootElement.findByResourceId('login_btn');
        expect(results, contains(child1));
        expect(results.length, equals(1));
      });

      test('should find elements by class name', () {
        final results = rootElement.findByClassName('Button');
        expect(results.length, greaterThan(0));
      });

      test('should find clickable elements', () {
        final results = rootElement.findClickableElements();
        expect(results, contains(child1));
      });

      test('should find enabled elements', () {
        final results = rootElement.findEnabledElements();
        expect(results.length, greaterThan(0));
      });

      test('should get all descendants', () {
        final descendants = rootElement.getAllDescendants();
        expect(descendants, containsAll([child1, child2, grandchild1]));
        expect(descendants.length, equals(3));
      });

      test('should get path from root', () {
        final path = grandchild1.getPathFromRoot();
        expect(path, equals([rootElement, child1, grandchild1]));
      });

      test('should get path to root', () {
        final path = grandchild1.getPathToRoot();
        expect(path, equals([grandchild1, child1, rootElement]));
      });
    });

    group('Hierarchy Validation', () {
      test('should detect if element is ancestor of another', () {
        final parent = _createTestElement('parent', 0, 'Parent');
        final child = _createTestElement('child', 1, 'Child');
        final grandchild = _createTestElement('grandchild', 2, 'Grandchild');

        parent.addChild(child);
        child.addChild(grandchild);

        expect(parent.isAncestorOf(child), isTrue);
        expect(parent.isAncestorOf(grandchild), isTrue);
        expect(child.isAncestorOf(grandchild), isTrue);
        expect(child.isAncestorOf(parent), isFalse);
        expect(grandchild.isAncestorOf(parent), isFalse);
      });

      test('should detect if element is descendant of another', () {
        final parent = _createTestElement('parent', 0, 'Parent');
        final child = _createTestElement('child', 1, 'Child');
        final grandchild = _createTestElement('grandchild', 2, 'Grandchild');

        parent.addChild(child);
        child.addChild(grandchild);

        expect(child.isDescendantOf(parent), isTrue);
        expect(grandchild.isDescendantOf(parent), isTrue);
        expect(grandchild.isDescendantOf(child), isTrue);
        expect(parent.isDescendantOf(child), isFalse);
        expect(parent.isDescendantOf(grandchild), isFalse);
      });

      test('should calculate depth correctly in hierarchy', () {
        final root = _createTestElement('root', 0, 'Root');
        final level1 = _createTestElement('level1', 1, 'Level 1');
        final level2 = _createTestElement('level2', 2, 'Level 2');
        final level3 = _createTestElement('level3', 3, 'Level 3');

        root.addChild(level1);
        level1.addChild(level2);
        level2.addChild(level3);

        expect(root.depth, equals(0));
        expect(level1.depth, equals(1));
        expect(level2.depth, equals(2));
        expect(level3.depth, equals(3));
      });
    });

    group('Bounds and Positioning', () {
      test('should calculate center point correctly', () {
        final element = UIElement(
          id: 'test',
          depth: 0,
          text: '',
          contentDesc: '',
          className: '',
          packageName: '',
          resourceId: '',
          clickable: false,
          enabled: true,
          bounds: const Rect.fromLTRB(0, 0, 100, 50),
          index: 0,
        );

        expect(element.center, equals(const Offset(50, 25)));
      });

      test('should detect if point is inside bounds', () {
        final element = UIElement(
          id: 'test',
          depth: 0,
          text: '',
          contentDesc: '',
          className: '',
          packageName: '',
          resourceId: '',
          clickable: false,
          enabled: true,
          bounds: const Rect.fromLTRB(10, 10, 110, 60),
          index: 0,
        );

        expect(element.containsPoint(const Offset(50, 30)), isTrue);
        expect(element.containsPoint(const Offset(5, 5)), isFalse);
        expect(element.containsPoint(const Offset(120, 70)), isFalse);
      });

      test('should detect overlapping bounds', () {
        final element1 = UIElement(
          id: 'element1',
          depth: 0,
          text: '',
          contentDesc: '',
          className: '',
          packageName: '',
          resourceId: '',
          clickable: false,
          enabled: true,
          bounds: const Rect.fromLTRB(0, 0, 50, 50),
          index: 0,
        );

        final element2 = UIElement(
          id: 'element2',
          depth: 0,
          text: '',
          contentDesc: '',
          className: '',
          packageName: '',
          resourceId: '',
          clickable: false,
          enabled: true,
          bounds: const Rect.fromLTRB(25, 25, 75, 75),
          index: 0,
        );

        final element3 = UIElement(
          id: 'element3',
          depth: 0,
          text: '',
          contentDesc: '',
          className: '',
          packageName: '',
          resourceId: '',
          clickable: false,
          enabled: true,
          bounds: const Rect.fromLTRB(100, 100, 150, 150),
          index: 0,
        );

        expect(element1.overlaps(element2), isTrue);
        expect(element1.overlaps(element3), isFalse);
        expect(element2.overlaps(element3), isFalse);
      });
    });

    group('String Representation', () {
      test('should provide meaningful toString', () {
        final element = UIElement(
          id: 'test_element',
          depth: 1,
          text: 'Test Text',
          contentDesc: 'Test Description',
          className: 'android.widget.Button',
          packageName: 'com.example',
          resourceId: 'com.example:id/test',
          clickable: true,
          enabled: true,
          bounds: const Rect.fromLTRB(0, 0, 100, 50),
          index: 0,
        );

        final stringRep = element.toString();
        expect(stringRep, contains('UIElement'));
        expect(stringRep, contains('test_element'));
        expect(stringRep, contains('Test Text'));
        expect(stringRep, contains('Button'));
      });
    });

    group('Edge Cases', () {
      test('should handle empty strings gracefully', () {
        final element = UIElement(
          id: '',
          depth: 0,
          text: '',
          contentDesc: '',
          className: '',
          packageName: '',
          resourceId: '',
          clickable: false,
          enabled: false,
          bounds: Rect.zero,
          index: 0,
        );

        expect(element.displayText, equals(''));
        expect(element.simpleClassName, equals(''));
        expect(element.width, equals(0.0));
        expect(element.height, equals(0.0));
      });

      test('should handle negative bounds', () {
        final element = UIElement(
          id: 'test',
          depth: 0,
          text: '',
          contentDesc: '',
          className: '',
          packageName: '',
          resourceId: '',
          clickable: false,
          enabled: true,
          bounds: const Rect.fromLTRB(-10, -5, 10, 5),
          index: 0,
        );

        expect(element.width, equals(20.0));
        expect(element.height, equals(10.0));
      });

      test('should handle adding same child multiple times', () {
        final child = _createTestChild('child', 0);
        
        testElement.addChild(child);
        expect(testElement.childCount, equals(1));
        
        // Adding same child again should not duplicate
        testElement.addChild(child);
        expect(testElement.childCount, equals(1));
      });

      test('should handle removing non-existent child', () {
        final child = _createTestChild('child', 0);
        
        // Should not throw when removing non-existent child
        expect(() => testElement.removeChild(child), returnsNormally);
        expect(testElement.childCount, equals(0));
      });
    });
  });
}

// Helper methods for creating test elements
UIElement _createTestElement(String id, int depth, String text) {
  return UIElement(
    id: id,
    depth: depth,
    text: text,
    contentDesc: '',
    className: 'android.widget.Button',
    packageName: 'com.example',
    resourceId: '',
    clickable: true,
    enabled: true,
    bounds: const Rect.fromLTRB(0, 0, 100, 50),
    index: 0,
  );
}

UIElement _createTestChild(String id, int index) {
  return UIElement(
    id: id,
    depth: 2,
    text: 'Child $index',
    contentDesc: '',
    className: 'android.widget.TextView',
    packageName: '',
    resourceId: '',
    clickable: false,
    enabled: true,
    bounds: Rect.zero,
    index: index,
  );
}