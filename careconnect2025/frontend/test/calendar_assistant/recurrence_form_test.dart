import 'package:care_connect_app/features/tasks/presentation/widgets/recurrence_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

/// Mock callback for onChanged
class _OnChangedMock extends Mock {
  void call({
    bool? isRecurring,
    String? recurrenceType,
    List<bool>? daysOfWeek,
    int? interval,
    int? count,
    DateTime? startDate,
    DateTime? endDate,
    int? dayOfMonth,
    bool? applyToSeries,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecurrenceForm Widget', () {
    void verifyCalled(_OnChangedMock mock) {
      verify(
        mock.call(
          isRecurring: anyNamed('isRecurring'),
          recurrenceType: anyNamed('recurrenceType'),
          daysOfWeek: anyNamed('daysOfWeek'),
          interval: anyNamed('interval'),
          count: anyNamed('count'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          dayOfMonth: anyNamed('dayOfMonth'),
          applyToSeries: anyNamed('applyToSeries'),
        ),
      ).called(greaterThan(0));
    }

    testWidgets('renders and toggles Recurring Task checkbox', (tester) async {
      final mockCallback = _OnChangedMock();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RecurrenceForm(onChanged: mockCallback)),
        ),
      );

      expect(find.text('Recurring Task'), findsOneWidget);

      await tester.tap(find.text('Recurring Task'));
      await tester.pumpAndSettle();

      verifyCalled(mockCallback);
      expect(find.text('Recurrence Type'), findsOneWidget);
    });

    testWidgets('selecting recurrence type updates state', (tester) async {
      final mockCallback = _OnChangedMock();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RecurrenceForm(onChanged: mockCallback)),
        ),
      );

      await tester.tap(find.text('Recurring Task'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weekly').last);
      await tester.pumpAndSettle();

      verifyCalled(mockCallback);
      expect(find.text('Select Days of Week'), findsOneWidget);
    });

    testWidgets('weekly recurrence allows selecting days of week', (
      tester,
    ) async {
      final mockCallback = _OnChangedMock();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrenceForm(
              onChanged: mockCallback,
              initialIsRecurring: true,
              initialRecurrenceType: 'Weekly',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Mon'));
      await tester.pumpAndSettle();

      verifyCalled(mockCallback);
    });

    testWidgets('monthly recurrence allows selecting day of month', (
      tester,
    ) async {
      final mockCallback = _OnChangedMock();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrenceForm(
              onChanged: mockCallback,
              initialIsRecurring: true,
              initialRecurrenceType: 'Monthly',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Day of Month:'), findsOneWidget);
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').last);
      await tester.pumpAndSettle();

      verifyCalled(mockCallback);
    });

    testWidgets('applyToSeries checkbox triggers callback', (tester) async {
      final mockCallback = _OnChangedMock();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrenceForm(
              onChanged: mockCallback,
              initialIsRecurring: true,
              initialRecurrenceType: 'Daily',
              showApplyToSeries: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply changes to entire series'));
      await tester.pumpAndSettle();

      verifyCalled(mockCallback);
    });

    testWidgets('yearly recurrence allows selecting year', (tester) async {
      final mockCallback = _OnChangedMock();
      final now = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrenceForm(
              onChanged: mockCallback,
              initialIsRecurring: true,
              initialRecurrenceType: 'Yearly',
              initialStartDate: now,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Ends in Year:'), findsOneWidget);
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();

      await tester.tap(find.text((now.year + 1).toString()).last);
      await tester.pumpAndSettle();

      verifyCalled(mockCallback);
    });

    testWidgets('shows validation when missing recurrence type', (
      tester,
    ) async {
      final mockCallback = _OnChangedMock();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrenceForm(
              onChanged: mockCallback,
              initialIsRecurring: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Please select a recurrence type'), findsOneWidget);
    });
  });
}
