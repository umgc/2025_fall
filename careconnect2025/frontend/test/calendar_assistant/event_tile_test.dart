import 'package:calendar_view/calendar_view.dart';
import 'package:care_connect_app/features/tasks/models/task_model.dart';
import 'package:care_connect_app/features/tasks/presentation/widgets/event_tile.dart';
import 'package:care_connect_app/features/tasks/utils/task_type_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({}); // avoid MissingPluginException

  group('EventTile Widget Tests', () {
    late TaskTypeManager manager;
    late DateTime now;

    setUp(() {
      manager = TaskTypeManager();
      now = DateTime(2025, 10, 19, 10, 0);
    });

    /// Helper to build a testable widget tree with Provider + MaterialApp
    Widget wrapWithProvider(Widget child) {
      return ChangeNotifierProvider.value(
        value: manager,
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }

    testWidgets('renders nothing when events list is empty', (tester) async {
      await tester.pumpWidget(wrapWithProvider(const EventTile(events: [])));

      expect(find.byType(Container), findsNothing);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('renders a single event with correct name', (tester) async {
      final task = Task(
        id: 1,
        name: 'Check Blood Pressure',
        taskType: 'general',
        date: now,
      );

      final event = CalendarEventData<Task>(
        date: now,
        title: 'Event',
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        event: task,
      );

      await tester.pumpWidget(wrapWithProvider(EventTile(events: [event])));

      // Should render the task name text
      expect(find.text('Check Blood Pressure'), findsOneWidget);
    });

    testWidgets('renders dot with correct color from TaskTypeManager', (
      tester,
    ) async {
      final task = Task(
        id: 2,
        name: 'Medication Reminder',
        taskType: 'medication',
        date: now,
      );

      final event = CalendarEventData<Task>(
        date: now,
        title: 'Medication Event',
        startTime: now,
        endTime: now.add(const Duration(minutes: 30)),
        event: task,
      );

      await tester.pumpWidget(wrapWithProvider(EventTile(events: [event])));

      // Find the colored dot (small circular container)
      final dotFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      );

      expect(dotFinder, findsOneWidget);

      // Verify the color matches TaskTypeManager color for 'medication'
      final dot = tester.widget<Container>(dotFinder);
      final color = (dot.decoration as BoxDecoration).color;
      expect(color, equals(manager.getColor('medication')));
    });

    testWidgets('applies background tint and border color correctly', (
      tester,
    ) async {
      final task = Task(
        id: 3,
        name: 'Appointment with Doctor',
        taskType: 'appointment',
        date: now,
      );

      final event = CalendarEventData<Task>(
        date: now,
        title: 'Appointment',
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        event: task,
      );

      await tester.pumpWidget(wrapWithProvider(EventTile(events: [event])));

      // The outer container should have background and border colors
      final container = tester.widget<Container>(find.byType(Container).first);
      final box = container.decoration as BoxDecoration;
      expect(box.border?.top.color, equals(manager.getColor('appointment')));
      expect(
        box.color,
        equals(manager.getColor('appointment').withOpacity(0.15)),
      );
    });

    testWidgets('shows only first event when multiple provided', (
      tester,
    ) async {
      final task1 = Task(
        id: 1,
        name: 'Morning Task',
        taskType: 'general',
        date: now,
      );

      final task2 = Task(
        id: 2,
        name: 'Evening Task',
        taskType: 'exercise',
        date: now,
      );

      final events = [
        CalendarEventData<Task>(
          date: now,
          title: 'First',
          startTime: now,
          endTime: now.add(const Duration(hours: 1)),
          event: task1,
        ),
        CalendarEventData<Task>(
          date: now,
          title: 'Second',
          startTime: now,
          endTime: now.add(const Duration(hours: 1)),
          event: task2,
        ),
      ];

      await tester.pumpWidget(wrapWithProvider(EventTile(events: events)));

      // Should display only the first task name
      expect(find.text('Morning Task'), findsOneWidget);
      expect(find.text('Evening Task'), findsNothing);
    });

    testWidgets('applies text color matching event color', (tester) async {
      final task = Task(id: 4, name: 'Lab Work', taskType: 'lab', date: now);

      final event = CalendarEventData<Task>(
        date: now,
        title: 'Lab Event',
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        event: task,
      );

      await tester.pumpWidget(wrapWithProvider(EventTile(events: [event])));

      // Find the Text widget for the event name
      final textWidget = tester.widget<Text>(find.text('Lab Work'));
      expect(textWidget.style?.color, equals(manager.getColor('lab')));
    });
  });
}
