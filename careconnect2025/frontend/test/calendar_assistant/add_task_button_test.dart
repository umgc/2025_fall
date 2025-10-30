import 'package:care_connect_app/features/tasks/presentation/widgets/add_task_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddTaskButton Widget', () {
    testWidgets('renders labeled button on wide screens', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 800)), // wide screen
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 800,
                  height: 600,
                  child: AddTaskButton(onPressed: () => pressed = true),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The button should show label text
      expect(find.text('Add Task'), findsOneWidget);

      // Tap by text (safe even if Flutter changes internal class)
      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('renders icon-only button on compact screens', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(300, 800)), // narrow screen
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  height: 600,
                  child: AddTaskButton(onPressed: () => pressed = true),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show only the icon version (no text)
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Add Task'), findsNothing);

      // Tap the icon and verify callback fired
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });
  });
}
