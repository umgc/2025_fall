import 'package:care_connect_app/features/tasks/presentation/widgets/filters_panel.dart';
import 'package:care_connect_app/features/tasks/utils/task_type_manager.dart';

/// =============================
/// Mock User + Provider Setup
/// =============================
import 'package:care_connect_app/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A simple fake UserSession for testing.
class MockUserSession extends UserSession {
  @override
  final bool isCaregiver;
  @override
  final bool isPatient;

  MockUserSession({this.isCaregiver = true, this.isPatient = false})
    : super(
        id: 1,
        email: 'test@test.com',
        role: isCaregiver ? 'CAREGIVER' : 'PATIENT',
        token: 'fake-token',
      );
}

/// Mock UserProvider that supplies a fake caregiver user.
class MockUserProvider extends ChangeNotifier implements UserProvider {
  @override
  UserSession? user = MockUserSession(isCaregiver: true);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({}); // Prevent MissingPluginException

  group('FiltersPanel Widget Tests', () {
    late TaskTypeManager manager;
    late bool expanded;
    late bool clearPressed;
    late bool todayPressed;
    late bool togglePressed;
    late String toggledType;
    late int toggledPatient;

    setUp(() {
      manager = TaskTypeManager();
      expanded = true;
      clearPressed = false;
      todayPressed = false;
      togglePressed = false;
      toggledType = '';
      toggledPatient = -1;
    });

    /// Wraps widget with Providers
    Widget wrapWithProviders(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<TaskTypeManager>.value(value: manager),
          ChangeNotifierProvider<UserProvider>(
            create: (_) => MockUserProvider(),
          ),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }

    testWidgets('renders collapsed view with Today button', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          FiltersPanel(
            expanded: false,
            patientNames: const {},
            selectedTypes: const {},
            selectedPatients: const {},
            onClear: () => clearPressed = true,
            onTypeToggled: (s) => toggledType = s,
            onPatientToggled: (i) => toggledPatient = i,
            onToggleExpanded: () => togglePressed = true,
            onTodayPressed: () => todayPressed = true,
          ),
        ),
      );

      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);

      // Tapping expand button calls onToggleExpanded
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();
      expect(togglePressed, isTrue);
    });

    testWidgets('renders expanded view with task type chips', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          FiltersPanel(
            expanded: true,
            patientNames: const {},
            selectedTypes: const {},
            selectedPatients: const {},
            onClear: () => clearPressed = true,
            onTypeToggled: (s) => toggledType = s,
            onPatientToggled: (i) => toggledPatient = i,
            onToggleExpanded: () => togglePressed = true,
            onTodayPressed: () => todayPressed = true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and clear button exist
      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Task Types'), findsOneWidget);

      // Verify chips render from TaskTypeManager defaults
      expect(find.byType(FilterChip), findsWidgets);

      // Tap a chip
      final firstChip = find.byType(FilterChip).first;
      await tester.tap(firstChip);
      await tester.pump();
      expect(toggledType.isNotEmpty, isTrue);
    });

    testWidgets('calls onClear when Clear button is pressed', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          FiltersPanel(
            expanded: true,
            patientNames: const {},
            selectedTypes: const {},
            selectedPatients: const {},
            onClear: () => clearPressed = true,
            onTypeToggled: (s) => toggledType = s,
            onPatientToggled: (i) => toggledPatient = i,
            onToggleExpanded: () => togglePressed = true,
            onTodayPressed: () => todayPressed = true,
          ),
        ),
      );

      await tester.tap(find.text('Clear'));
      await tester.pump();
      expect(clearPressed, isTrue);
    });

    testWidgets('calls onTodayPressed when Today button is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithProviders(
          FiltersPanel(
            expanded: true,
            patientNames: const {},
            selectedTypes: const {},
            selectedPatients: const {},
            onClear: () => clearPressed = true,
            onTypeToggled: (s) => toggledType = s,
            onPatientToggled: (i) => toggledPatient = i,
            onToggleExpanded: () => togglePressed = true,
            onTodayPressed: () => todayPressed = true,
          ),
        ),
      );

      await tester.tap(find.text('Today'));
      await tester.pump();
      expect(todayPressed, isTrue);
    });

    testWidgets('renders patient filter chips for caregivers', (tester) async {
      final patients = {1: 'John Doe', 2: 'Jane Smith'};

      await tester.pumpWidget(
        wrapWithProviders(
          FiltersPanel(
            expanded: true,
            patientNames: patients,
            selectedTypes: const {},
            selectedPatients: const {},
            onClear: () => clearPressed = true,
            onTypeToggled: (s) => toggledType = s,
            onPatientToggled: (i) => toggledPatient = i,
            onToggleExpanded: () => togglePressed = true,
            onTodayPressed: () => todayPressed = true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Patients'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);

      // Tap a patient chip
      await tester.tap(find.text('John Doe'));
      await tester.pump();
      expect(toggledPatient, equals(1));
    });

    testWidgets('selected chips display with correct color and selection', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithProviders(
          FiltersPanel(
            expanded: true,
            patientNames: const {},
            selectedTypes: {'medication'},
            selectedPatients: const {1},
            onClear: () => clearPressed = true,
            onTypeToggled: (s) => toggledType = s,
            onPatientToggled: (i) => toggledPatient = i,
            onToggleExpanded: () => togglePressed = true,
            onTodayPressed: () => todayPressed = true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the "Medication" chip text
      expect(
        find.textContaining('Medication', findRichText: true),
        findsWidgets,
      );
    });
  });
}
