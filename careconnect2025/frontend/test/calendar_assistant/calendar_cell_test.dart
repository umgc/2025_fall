import 'package:calendar_view/calendar_view.dart';
import 'package:care_connect_app/features/tasks/models/task_model.dart';
import 'package:care_connect_app/features/tasks/presentation/widgets/calendar_cell.dart';
import 'package:care_connect_app/features/tasks/utils/task_type_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // required to mock prefs

void main() {
  // Ensure widget bindings + mock SharedPreferences are initialized
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({}); // prevents MissingPluginException

  group('CalendarCell Widget Tests', () {
    late TaskTypeManager manager;

    setUp(() {
      manager = TaskTypeManager(); // safely initializes SharedPreferences
    });

    /// Helper widget to wrap CalendarCell in provider and MaterialApp
    Widget buildTestable(Widget child) {
      return ChangeNotifierProvider.value(
        value: manager,
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }

    testWidgets('renders day number correctly', (tester) async {
      final date = DateTime(2025, 10, 19);

      await tester.pumpWidget(
        buildTestable(
          CalendarCell(
            date: date,
            events: const [],
            isToday: false,
            isInMonth: true,
            isWeekend: false,
            isSelected: false,
          ),
        ),
      );

      expect(find.text('19'), findsOneWidget);
    });

    testWidgets('highlights today correctly', (tester) async {
      final date = DateTime.now();

      await tester.pumpWidget(
        buildTestable(
          CalendarCell(
            date: date,
            events: const [],
            isToday: true,
            isInMonth: true,
            isWeekend: false,
            isSelected: false,
          ),
        ),
      );

      // Verify the border color for today cell
      final container = tester.widget<Container>(find.byType(Container).first);
      final box = container.decoration as BoxDecoration;
      expect(box.border?.top.color, equals(ThemeData().colorScheme.primary));
    });

    testWidgets('renders up to 4 task dots', (tester) async {
      final date = DateTime(2025, 10, 19);

      // ✅ Added required `title` + `date` for CalendarEventData<Task> and Task
      final fakeTasks = List.generate(
        5,
        (i) => CalendarEventData<Task>(
          date: date,
          title: 'Task $i',
          startTime: date,
          endTime: date.add(const Duration(hours: 1)),
          event: Task(
            id: i,
            name: 'Task $i',
            taskType: 'general',
            date: date, // ✅ required for Task model
          ),
        ),
      );

      await tester.pumpWidget(
        buildTestable(
          CalendarCell(
            date: date,
            events: fakeTasks,
            isToday: false,
            isInMonth: true,
            isWeekend: false,
            isSelected: false,
          ),
        ),
      );

      // Verify up to 4 dots are rendered
      final dots = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      );
      expect(dots.evaluate().length, lessThanOrEqualTo(4));
    });

    testWidgets('applies selected border when selected', (tester) async {
      final date = DateTime(2025, 10, 19);

      await tester.pumpWidget(
        buildTestable(
          CalendarCell(
            date: date,
            events: const [],
            isToday: false,
            isInMonth: true,
            isWeekend: false,
            isSelected: true,
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final box = container.decoration as BoxDecoration;

      // Selected day should have a green border
      expect(box.border?.top.color, equals(Colors.green));
    });

    testWidgets('renders weekend styling correctly', (tester) async {
      final date = DateTime(2025, 10, 19); // Sunday → weekend

      await tester.pumpWidget(
        buildTestable(
          CalendarCell(
            date: date,
            events: const [],
            isToday: false,
            isInMonth: true,
            isWeekend: true,
            isSelected: false,
          ),
        ),
      );

      // Verify it still shows the day label
      expect(find.text('19'), findsOneWidget);
    });
  });
}
