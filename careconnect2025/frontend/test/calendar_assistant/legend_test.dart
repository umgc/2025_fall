import 'package:care_connect_app/features/tasks/presentation/widgets/legend.dart';
import 'package:care_connect_app/features/tasks/utils/task_type_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper to wrap a widget with Provider + MaterialApp
Widget _wrapWithProvider(Widget child, TaskTypeManager manager) {
  return MaterialApp(
    home: ChangeNotifierProvider<TaskTypeManager>.value(
      value: manager,
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  setUp(() async {
    // Ensures no SharedPreferences initialization errors
    SharedPreferences.setMockInitialValues({});
  });

  group('Legend Widget', () {
    testWidgets('renders header, icons, and default task types', (
      WidgetTester tester,
    ) async {
      final manager = TaskTypeManager();

      await tester.pumpWidget(_wrapWithProvider(const Legend(), manager));
      await tester.pumpAndSettle();

      // Verify header
      expect(find.text('Task Types'), findsOneWidget);

      // Default task type names
      expect(find.text('Medication'), findsOneWidget);
      expect(find.text('Appointment'), findsOneWidget);
      expect(find.text('Exercise'), findsOneWidget);
      expect(find.text('Lab'), findsOneWidget);
      expect(find.text('Imported'), findsOneWidget);

      // Icons should render
      expect(find.byIcon(Icons.task), findsWidgets);
    });

    testWidgets('tapping manage button triggers onManage callback', (
      WidgetTester tester,
    ) async {
      bool tapped = false;
      final manager = TaskTypeManager();

      await tester.pumpWidget(
        _wrapWithProvider(Legend(onManage: () => tapped = true), manager),
      );

      await tester.pumpAndSettle();

      // Tap edit (manage) icon
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('hides manage button when showManageButton is false', (
      WidgetTester tester,
    ) async {
      final manager = TaskTypeManager();

      await tester.pumpWidget(
        _wrapWithProvider(const Legend(showManageButton: false), manager),
      );

      await tester.pumpAndSettle();

      // Edit icon should not appear
      expect(find.byIcon(Icons.edit), findsNothing);
    });

    testWidgets('invokes onTypeTap when type chip tapped', (
      WidgetTester tester,
    ) async {
      String? tappedType;
      final manager = TaskTypeManager();

      await tester.pumpWidget(
        _wrapWithProvider(
          Legend(onTypeTap: (type) => tappedType = type),
          manager,
        ),
      );

      await tester.pumpAndSettle();

      // Tap one of the task labels (Medication)
      await tester.tap(find.text('Medication'));
      await tester.pumpAndSettle();

      expect(tappedType, isNotNull);
      expect(tappedType!.toLowerCase(), 'medication');
    });

    testWidgets('invokes onTypeLongPress when chip long-pressed', (
      WidgetTester tester,
    ) async {
      String? longPressedType;
      final manager = TaskTypeManager();

      await tester.pumpWidget(
        _wrapWithProvider(
          Legend(onTypeLongPress: (type) => longPressedType = type),
          manager,
        ),
      );

      await tester.pumpAndSettle();

      // Long press one of the task labels
      await tester.longPress(find.text('Appointment'));
      await tester.pumpAndSettle();

      expect(longPressedType, isNotNull);
      expect(longPressedType!.toLowerCase(), 'appointment');
    });
  });
}
