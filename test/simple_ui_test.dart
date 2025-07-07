import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simple UI tests for basic Flutter components
/// These tests validate core UI functionality without complex dependencies
void main() {
  group('Basic UI Component Tests', () {
    testWidgets('ElevatedButton works correctly', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => wasPressed = true,
                child: const Text('Test Button'),
              ),
            ),
          ),
        ),
      );

      // Button should exist and not be pressed initially
      expect(find.text('Test Button'), findsOneWidget);
      expect(wasPressed, isFalse);

      // Tap button
      await tester.tap(find.text('Test Button'));
      await tester.pumpAndSettle();

      // Button should be pressed
      expect(wasPressed, isTrue);
    });

    testWidgets('TextField accepts input correctly',
        (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Enter text here',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ),
      );

      // TextField should exist with hint text
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Enter text here'), findsOneWidget);

      // Type text into field
      await tester.enterText(find.byType(TextField), 'Hello World');
      await tester.pumpAndSettle();

      // Text should be entered correctly
      expect(controller.text, 'Hello World');
      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('ListView displays and scrolls correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 20,
              itemBuilder: (context, index) => ListTile(
                title: Text('Item $index'),
                subtitle: Text('Description for item $index'),
              ),
            ),
          ),
        ),
      );

      // First items should be visible
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 19'),
          findsNothing); // Should not be visible initially

      // Scroll down to see more items
      await tester.fling(find.byType(ListView), const Offset(0, -500), 1000);
      await tester.pumpAndSettle();

      // After scrolling, should still work without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('Navigation between pages works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Home Page')),
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Second Page')),
                        body:
                            const Center(child: Text('Welcome to second page')),
                      ),
                    ),
                  ),
                  child: const Text('Go to Second Page'),
                ),
              ),
            ),
          ),
        ),
      );

      // Should start on home page
      expect(find.text('Home Page'), findsOneWidget);
      expect(find.text('Go to Second Page'), findsOneWidget);
      expect(find.text('Second Page'), findsNothing);

      // Navigate to second page
      await tester.tap(find.text('Go to Second Page'));
      await tester.pumpAndSettle();

      // Should be on second page now
      expect(find.text('Second Page'), findsOneWidget);
      expect(find.text('Welcome to second page'), findsOneWidget);
      expect(find.text('Home Page'), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Navigate back to home
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should be back on home page
      expect(find.text('Home Page'), findsOneWidget);
      expect(find.text('Go to Second Page'), findsOneWidget);
      expect(find.text('Second Page'), findsNothing);
    });

    testWidgets('IconButton responds to taps', (WidgetTester tester) async {
      bool menuTapped = false;
      bool searchTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Test App Bar'),
              leading: IconButton(
                onPressed: () => menuTapped = true,
                icon: const Icon(Icons.menu),
              ),
              actions: [
                IconButton(
                  onPressed: () => searchTapped = true,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
          ),
        ),
      );

      // Icons should be present
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(menuTapped, isFalse);
      expect(searchTapped, isFalse);

      // Tap menu icon
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(menuTapped, isTrue);

      // Tap search icon
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(searchTapped, isTrue);
    });

    testWidgets('Container with custom styling renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Container(
                width: 200,
                height: 100,
                color: Colors.blue,
                child: const Center(
                  child: Text(
                    'Styled Container',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Container and text should exist
      expect(find.byType(Container), findsOneWidget);
      expect(find.text('Styled Container'), findsOneWidget);

      // Verify text styling
      final textWidget = tester.widget<Text>(find.text('Styled Container'));
      expect(textWidget.style?.color, Colors.white);
      expect(textWidget.style?.fontSize, 18);
      expect(textWidget.style?.fontWeight, FontWeight.bold);
    });
  });

  group('Error Handling Tests', () {
    testWidgets('Empty page renders without errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Nothing here'),
            ),
          ),
        ),
      );

      // Should render without exceptions
      expect(tester.takeException(), isNull);
      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('Empty ListView renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 0, // Empty list
              itemBuilder: (context, index) => ListTile(
                title: Text('Item $index'),
              ),
            ),
          ),
        ),
      );

      // Should handle empty list gracefully
      expect(tester.takeException(), isNull);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });
  });
}
