import 'package:care_connect_app/features/notifications/models/scheduled_notification_model.dart';
import 'package:care_connect_app/features/tasks/models/task_model.dart';
import 'package:care_connect_app/features/tasks/presentation/widgets/task_form_dialog.dart';
import 'package:care_connect_app/features/tasks/utils/task_type_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// ======================================================
/// Fake TaskTypeManager (concrete implementation)
/// ======================================================
class FakeTaskTypeManager extends ChangeNotifier implements TaskTypeManager {
  @override
  Map<String, Color> get taskTypeColors => <String, Color>{
    'general': Colors.blue,
    'lab': Colors.red,
  };

  @override
  IconData getIcon(String? type) => Icons.task;

  @override
  Color getColor(String? type) => taskTypeColors[type] ?? Colors.blue;

  @override
  Future<void> addTaskType(String name, Color color, {IconData? icon}) async {}

  @override
  Future<void> removeTaskType(String name) async {}

  @override
  Future<void> resetDefaults() async {}

  @override
  Future<void> updateTaskColor(String name, Color color) async {}

  @override
  Future<void> updateTaskIcon(String name, IconData icon) async {}

  @override
  List<String> getSortedTypes() => taskTypeColors.keys.toList()..sort();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeTaskTypeManager fakeManager;

  setUp(() {
    fakeManager = FakeTaskTypeManager();
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      home: ChangeNotifierProvider<TaskTypeManager>.value(
        value: fakeManager,
        child: Scaffold(body: child),
      ),
    );
  }

  group('TaskFormDialog Widget', () {
    testWidgets('renders all expected sections', (tester) async {
      await tester.pumpWidget(
        wrap(
          TaskFormDialog(
            isCaregiver: true,
            patients: [
              {
                'patient': {'id': 1, 'firstName': 'John', 'lastName': 'Doe'},
              },
              {
                'patient': {'id': 2, 'firstName': 'Jane', 'lastName': 'Smith'},
              },
            ],
          ),
        ),
      );

      expect(find.text('Add Task'), findsOneWidget);
      expect(find.text('Task Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Task Type'), findsOneWidget);
      expect(find.text('Reminder Notification'), findsOneWidget);
      expect(find.text('Recurring Task'), findsOneWidget);
      expect(find.text('Assign to Patient(s)'), findsOneWidget);
    });

    testWidgets('typing title enables Save button', (tester) async {
      await tester.pumpWidget(
        wrap(TaskFormDialog(isCaregiver: false, patients: [])),
      );

      final saveBefore = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Save'),
      );
      expect(saveBefore.onPressed, isNull);

      await tester.enterText(find.byType(TextFormField).first, 'My New Task');
      await tester.pumpAndSettle();

      final saveAfter = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Save'),
      );
      expect(saveAfter.onPressed, isNotNull);
    });

    testWidgets('caregiver can select Assign to All Patients', (tester) async {
      await tester.pumpWidget(
        wrap(
          TaskFormDialog(
            isCaregiver: true,
            patients: [
              {
                'patient': {'id': 1, 'firstName': 'Alice', 'lastName': 'Lee'},
              },
              {
                'patient': {'id': 2, 'firstName': 'Bob', 'lastName': 'King'},
              },
            ],
          ),
        ),
      );

      await tester.tap(find.text('Assign to All Patients'));
      await tester.pumpAndSettle();

      final allTiles = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(allTiles.where((t) => t.value == true).length, greaterThan(0));
    });

    testWidgets('updates reminder dropdown selection', (tester) async {
      await tester.pumpWidget(
        wrap(TaskFormDialog(isCaregiver: false, patients: [])),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('15 minutes before').last);
      await tester.pumpAndSettle();

      expect(find.text('15 minutes before'), findsWidgets);
    });

    /// ✅ FIXED: ensure provider + ensureVisible + pump scroll
    testWidgets('Save button returns result map after filling title', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (outerContext) => ElevatedButton(
              onPressed: () async {
                final result = await showDialog(
                  context: outerContext,
                  builder: (context) =>
                      ChangeNotifierProvider<TaskTypeManager>.value(
                        value: fakeManager,
                        child: TaskFormDialog(isCaregiver: false, patients: []),
                      ),
                );
                ScaffoldMessenger.of(outerContext).showSnackBar(
                  SnackBar(content: Text('Returned: ${result != null}')),
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Example Task');
      await tester.pumpAndSettle();

      // ensure Save is visible (scroll if needed)
      final saveButtonFinder = find.widgetWithText(ElevatedButton, 'Save');
      await tester.ensureVisible(saveButtonFinder);
      await tester.pumpAndSettle();

      await tester.tap(saveButtonFinder, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // confirm snackbar appears
      expect(find.textContaining('Returned: true'), findsOneWidget);
    });

    testWidgets('renders correctly with existing task + notification', (
      tester,
    ) async {
      final existingTask = Task(
        id: 1,
        name: 'Follow-up',
        description: 'Check in with patient',
        date: DateTime.now(),
        assignedPatientId: 1,
        taskType: 'general',
        notifications: [
          ScheduledNotification(
            scheduledTime: DateTime.now().subtract(const Duration(minutes: 15)),
            title: 'Reminder',
            body: 'Check in soon!',
            notificationType: 'TASK_REMINDER',
            receiverId: 1,
            status: 'PENDING',
          ),
        ],
      );

      await tester.pumpWidget(
        wrap(
          TaskFormDialog(
            isCaregiver: false,
            patients: [],
            initialTask: existingTask,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Task'), findsOneWidget);
      expect(find.text('Follow-up'), findsOneWidget);
    });
  });
}
