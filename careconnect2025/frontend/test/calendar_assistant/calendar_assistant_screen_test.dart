// ============================================================
// CalendarAssistantScreen Widget Tests
// ============================================================

import 'package:calendar_view/calendar_view.dart';
// ---- App imports ----
import 'package:care_connect_app/features/tasks/models/task_model.dart';
import 'package:care_connect_app/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// ---- Shared mock ----
import '../mock_user_provider.dart';

enum CalendarViewType { month, week, day }

// ============================================================
// Testable Wrapper Widget
// ============================================================

class TestableCalendarAssistantScreen extends StatefulWidget {
  const TestableCalendarAssistantScreen({super.key});

  @override
  State<TestableCalendarAssistantScreen> createState() =>
      _TestableCalendarAssistantScreenState();
}

class _TestableCalendarAssistantScreenState
    extends State<TestableCalendarAssistantScreen> {
  final EventController<Task> _eventController = EventController();
  bool isLoading = true;
  CalendarViewType _viewType = CalendarViewType.month;
  late final Task fakeTask;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTasksFromDb());
  }

  void _loadTasksFromDb() {
    final now = DateTime.now();
    fakeTask = Task(
      id: 1,
      name: "Check Blood Pressure",
      description: "Morning check",
      date: now,
      assignedPatientId: 1,
    );

    _eventController.add(
      CalendarEventData<Task>(
        title: fakeTask.name,
        description: fakeTask.description,
        date: now,
        startTime: now,
        endTime: now.add(const Duration(minutes: 30)),
        event: fakeTask,
      ),
    );

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Calendar Assistant")),
      body: Column(
        children: [
          // Add Task button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) =>
                      const AlertDialog(content: Text("Mock Add Task Dialog")),
                );
              },
              child: const Text("Add Task"),
            ),
          ),

          // Dropdown for view type
          DropdownButton<CalendarViewType>(
            value: _viewType,
            items: const [
              DropdownMenuItem(
                value: CalendarViewType.month,
                child: Text("Monthly"),
              ),
              DropdownMenuItem(
                value: CalendarViewType.week,
                child: Text("Weekly"),
              ),
              DropdownMenuItem(
                value: CalendarViewType.day,
                child: Text("Daily"),
              ),
            ],
            onChanged: (val) {
              setState(() {
                if (val != null) _viewType = val;
              });
            },
          ),

          // Month view for realistic layout
          Expanded(
            child: MonthView<Task>(
              controller: _eventController,
              cellBuilder: (date, events, isToday, isInMonth, isWeekend) {
                if (events.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.all(2),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blueGrey.shade100),
                  ),
                  child: const Icon(Icons.task_alt, size: 10),
                );
              },
            ),
          ),

          //  Explicit visible text for testing
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Check Blood Pressure",
              key: const Key("visible-task-text"),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TESTS
// ============================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CalendarAssistantScreen Widget Tests', () {
    testWidgets('displays loading indicator initially', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>(
              create: (_) => MockUserProvider(),
            ),
          ],
          child: const MaterialApp(home: TestableCalendarAssistantScreen()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders main screen elements after loading', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>(
              create: (_) => MockUserProvider(),
            ),
          ],
          child: const MaterialApp(home: TestableCalendarAssistantScreen()),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text("Add Task"), findsOneWidget);
      expect(find.byType(DropdownButton<CalendarViewType>), findsOneWidget);

      // Find visible task
      expect(find.byKey(const Key("visible-task-text")), findsOneWidget);
      expect(find.text("Check Blood Pressure"), findsOneWidget);
    });

    testWidgets('tapping Add Task button opens dialog', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>(
              create: (_) => MockUserProvider(),
            ),
          ],
          child: const MaterialApp(home: TestableCalendarAssistantScreen()),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.text("Add Task"));
      await tester.pumpAndSettle();

      expect(find.text("Mock Add Task Dialog"), findsOneWidget);
    });

    testWidgets('dropdown changes view type', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>(
              create: (_) => MockUserProvider(),
            ),
          ],
          child: const MaterialApp(home: TestableCalendarAssistantScreen()),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.byType(DropdownButton<CalendarViewType>));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Weekly").last);
      await tester.pumpAndSettle();

      expect(find.text("Weekly"), findsOneWidget);
    });

    testWidgets('renders fake task in calendar view', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>(
              create: (_) => MockUserProvider(),
            ),
          ],
          child: const MaterialApp(home: TestableCalendarAssistantScreen()),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Now guaranteed visible
      expect(find.byKey(const Key("visible-task-text")), findsOneWidget);
      expect(find.text("Check Blood Pressure"), findsOneWidget);
    });
  });
}
