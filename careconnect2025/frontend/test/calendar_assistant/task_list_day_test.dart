import 'package:calendar_view/calendar_view.dart';
import 'package:care_connect_app/features/tasks/models/task_model.dart';
import 'package:care_connect_app/features/tasks/presentation/widgets/task_list_day.dart';
import 'package:care_connect_app/features/tasks/utils/task_type_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Helper: wraps a widget in a testable provider + app shell
Widget _wrapWithProviders(Widget child) {
  return ChangeNotifierProvider<TaskTypeManager>(
    create: (_) => TaskTypeManager()
      ..addTaskType("general", Colors.blue)
      ..addTaskType("exercise", Colors.green),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

/// Helper: creates a CalendarEventData for a given Task
CalendarEventData<Task> _eventForTask(Task task) {
  return CalendarEventData<Task>(
    date: task.date,
    event: task,
    title: task.name,
  );
}

void main() {
  group('TaskListDay Widget Tests', () {
    testWidgets('renders "No tasks for this day" when empty', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          TaskListDay(
            events: const [],
            patientNames: const {},
            onEdit: (_) {},
            onDelete: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No tasks for this day'), findsOneWidget);
    });

    testWidgets('renders task details correctly', (tester) async {
      final today = DateTime.now();

      final task = Task(
        id: 1,
        name: 'Morning Exercise',
        description: 'Stretch routine',
        date: today,
        timeOfDay: const TimeOfDay(hour: 8, minute: 0),
        assignedPatientId: 1,
        isComplete: false,
        taskType: 'exercise',
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          TaskListDay(
            events: [_eventForTask(task)],
            patientNames: const {1: 'Alice'},
            onEdit: (_) {},
            onDelete: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Morning Exercise'), findsOneWidget);
      expect(find.textContaining('Alice'), findsOneWidget);
      expect(find.text('Mark as Complete'), findsOneWidget);
    });

    testWidgets('edit and delete buttons trigger callbacks', (tester) async {
      bool editCalled = false;
      bool deleteCalled = false;

      final task = Task(
        id: 2,
        name: 'Check BP',
        description: '',
        date: DateTime.now(),
        timeOfDay: const TimeOfDay(hour: 9, minute: 0),
        assignedPatientId: 3,
        isComplete: false,
        taskType: 'general',
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          TaskListDay(
            events: [_eventForTask(task)],
            patientNames: const {3: 'Bob'},
            onEdit: (_) => editCalled = true,
            onDelete: (_) => deleteCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      expect(editCalled, isTrue);

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      expect(deleteCalled, isTrue);
    });

    testWidgets('Mark as Complete toggles label and calls updateCompletion', (
      tester,
    ) async {
      final today = DateTime.now();

      final task = Task(
        id: 99,
        name: 'Walk',
        description: '',
        date: today,
        timeOfDay: const TimeOfDay(hour: 7, minute: 0),
        assignedPatientId: 5,
        isComplete: false,
        taskType: 'exercise',
      );

      final calls = <Map<String, dynamic>>[];

      await tester.pumpWidget(
        _wrapWithProviders(
          TaskListDay(
            events: [_eventForTask(task)],
            patientNames: const {5: 'Pat'},
            onEdit: (_) {},
            onDelete: (_) {},
            updateCompletion: (id, complete) async {
              calls.add({'id': id, 'complete': complete});
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the "Mark as Complete" button
      final labelFinder = find.text('Mark as Complete');
      final buttonFinder = find.ancestor(
        of: labelFinder,
        matching: find.byWidgetPredicate(
          (w) =>
              w is OutlinedButton ||
              w.runtimeType.toString().contains('OutlinedButton'),
        ),
      );

      // Relaxed matcher: allow at least one button
      expect(buttonFinder, findsAtLeastNWidgets(1));

      final targetButton = buttonFinder.first;
      await tester.ensureVisible(targetButton);
      await tester.tap(targetButton, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      // Expect UI updated
      expect(find.text('Completed'), findsWidgets);

      // Expect injected callback was called
      expect(
        calls.isNotEmpty,
        isTrue,
        reason: 'Expected updateCompletion to be called at least once',
      );
      expect(calls.first['id'], equals(99));
      expect(calls.first['complete'], isTrue);
    });

    testWidgets(
      'Failed API call rolls back completion status and shows SnackBar',
      (tester) async {
        final today = DateTime.now();

        final task = Task(
          id: 42,
          name: 'Take meds',
          description: '',
          date: today,
          timeOfDay: const TimeOfDay(hour: 10, minute: 30),
          assignedPatientId: 10,
          isComplete: false,
          taskType: 'general',
        );

        bool threw = false;

        await tester.pumpWidget(
          _wrapWithProviders(
            TaskListDay(
              events: [_eventForTask(task)],
              patientNames: const {10: 'Maria'},
              onEdit: (_) {},
              onDelete: (_) {},
              updateCompletion: (id, complete) async {
                // Simulate API failure
                threw = true;
                throw Exception("Simulated failure");
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final labelFinder = find.text('Mark as Complete');
        final buttonFinder = find.ancestor(
          of: labelFinder,
          matching: find.byWidgetPredicate(
            (w) =>
                w is OutlinedButton ||
                w.runtimeType.toString().contains('OutlinedButton'),
          ),
        );

        expect(buttonFinder, findsAtLeastNWidgets(1));
        await tester.tap(buttonFinder.first, warnIfMissed: false);
        await tester.pumpAndSettle(const Duration(milliseconds: 400));

        // Should have attempted update and caught error
        expect(threw, isTrue);

        // Check that SnackBar appears
        expect(find.textContaining('Failed to update task'), findsOneWidget);

        // UI should have reverted back
        expect(find.text('Mark as Complete'), findsWidgets);
      },
    );
  });
}
