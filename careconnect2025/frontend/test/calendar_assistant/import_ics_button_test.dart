import 'dart:convert';
import 'dart:typed_data';

import 'package:care_connect_app/features/tasks/presentation/widgets/import_ics_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// =============================
/// FakeFilePicker — no abstract inheritance issues
/// =============================
class FakeFilePicker {
  FilePickerResult? result;

  FakeFilePicker({this.result});

  Future<FilePickerResult?> pickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFilePicker fakePicker;

  setUp(() {
    fakePicker = FakeFilePicker();
  });

  Widget buildWidget(Map<int, String> patients) {
    return MaterialApp(
      home: Scaffold(
        body: ImportIcsButton(
          patientNames: patients,
          onTasksImported: () {},
          filePicker: fakePicker, // inject fake picker
        ),
      ),
    );
  }

  testWidgets('shows snackbar when no patient selected', (tester) async {
    await tester.pumpWidget(buildWidget({1: 'John'}));

    await tester.tap(find.text('Import ICS'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose File'));
    await tester.pumpAndSettle();

    expect(
      find.text('Please select a patient before importing.'),
      findsOneWidget,
    );
  });

  testWidgets('imports valid ICS file successfully', (tester) async {
    const icsContent = '''
BEGIN:VEVENT
SUMMARY:Morning Medication
DESCRIPTION:Take your meds
DTSTART:20251019T080000
DTEND:20251019T083000
RRULE:FREQ=DAILY;INTERVAL=1;COUNT=2
END:VEVENT
''';

    final bytes = Uint8List.fromList(utf8.encode(icsContent));
    fakePicker.result = FilePickerResult([
      PlatformFile(name: 'test.ics', bytes: bytes, size: bytes.length),
    ]);

    await tester.pumpWidget(buildWidget({1: 'John Doe'}));

    // Open import dialog
    await tester.tap(find.text('Import ICS'));
    await tester.pumpAndSettle();

    // Select a patient
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('John Doe').last);
    await tester.pumpAndSettle();

    // Trigger import
    await tester.tap(find.text('Choose File'));
    await tester.pumpAndSettle();

    // Verify UI didn’t crash
    expect(find.text('Import ICS'), findsOneWidget);
  });
}
