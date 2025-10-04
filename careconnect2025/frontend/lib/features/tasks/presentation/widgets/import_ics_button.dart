import 'dart:convert';

import 'package:care_connect_app/features/tasks/models/task_model.dart';
import 'package:care_connect_app/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// A button to import tasks from an .ics file
/// - Opens a dialog with a patient dropdown
/// - Lets the user choose a .ics file
/// - Parses VEVENT blocks and sends tasks to the backend
/// - Calls [onTasksImported] after tasks are saved (to refresh UI)
class ImportIcsButton extends StatefulWidget {
  final Map<int, String> patientNames; // patientId → name
  final VoidCallback? onTasksImported; // callback after import finishes

  const ImportIcsButton({
    super.key,
    required this.patientNames,
    this.onTasksImported,
  });

  @override
  State<ImportIcsButton> createState() => _ImportIcsButtonState();
}

class _ImportIcsButtonState extends State<ImportIcsButton> {
  int? _selectedPatientId;

  Future<void> _pickAndImportFile() async {
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a patient before importing."),
        ),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ics'],
    );
    if (result == null || result.files.isEmpty) return;

    final fileBytes = result.files.first.bytes;
    if (fileBytes == null) return;

    final content = utf8.decode(fileBytes);
    final events = _parseIcs(content);

    for (final ev in events) {
      final task = Task(
        name: ev['SUMMARY'] ?? "Untitled",
        description: ev['DESCRIPTION'] ?? "",
        date: ev['DTSTART'] ?? DateTime.now(),
        timeOfDay: ev['DTEND'] != null
            ? TimeOfDay(hour: ev['DTEND']!.hour, minute: ev['DTEND']!.minute)
            : null,
        assignedPatientId: _selectedPatientId,
        isComplete: false,
        taskType: _inferTaskType(ev['SUMMARY'] ?? "").toLowerCase(),
      );

      final taskJson = jsonEncode(task.toJson());
      await ApiService.createTaskV2(_selectedPatientId, taskJson);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Imported ${events.length} events")),
      );
    }

    // Trigger refresh after tasks are imported
    if (widget.onTasksImported != null) {
      widget.onTasksImported!();
    }
  }

  /// Very simple ICS parser for VEVENTS
  List<Map<String, dynamic>> _parseIcs(String ics) {
    final lines = ics.split(RegExp(r'\r?\n'));
    final events = <Map<String, dynamic>>[];
    Map<String, dynamic>? currentEvent;

    for (var line in lines) {
      line = line.trim();
      if (line.startsWith('BEGIN:VEVENT')) {
        currentEvent = {};
      } else if (line.startsWith('END:VEVENT')) {
        if (currentEvent != null) events.add(currentEvent);
        currentEvent = null;
      } else if (currentEvent != null) {
        final parts = line.split(':');
        if (parts.length < 2) continue;
        final key = parts[0].split(';')[0];
        final value = parts.sublist(1).join(':');

        switch (key) {
          case 'SUMMARY':
            currentEvent['SUMMARY'] = value;
            break;
          case 'DESCRIPTION':
            currentEvent['DESCRIPTION'] = value;
            break;
          case 'DTSTART':
            currentEvent['DTSTART'] = _parseDate(value);
            break;
          case 'DTEND':
            currentEvent['DTEND'] = _parseDate(value);
            break;
          case 'RRULE':
            currentEvent['RRULE'] = value;
            break;
        }
      }
    }
    return events;
  }

  /// Parses YYYYMMDD or YYYYMMDDTHHMMSSZ formats
  DateTime? _parseDate(String raw) {
    try {
      if (raw.contains('T')) {
        return DateTime.parse(raw.replaceAll('Z', ''));
      } else {
        // all-day event
        return DateTime.parse(
          '${raw.substring(0, 4)}-${raw.substring(4, 6)}-${raw.substring(6, 8)}',
        );
      }
    } catch (_) {
      return null;
    }
  }

  void _openDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Import ICS"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: "Assign to patient"),
              value: _selectedPatientId,
              items: widget.patientNames.entries
                  .map(
                    (e) => DropdownMenuItem<int>(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedPatientId = val),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pickAndImportFile();
            },
            child: const Text("Choose File"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _openDialog,
      icon: const Icon(Icons.file_upload),
      label: const Text("Import ICS"),
    );
  }

  String _inferTaskType(String summary) {
    final lower = summary.toLowerCase();
    if (lower.contains("appointment")) return "Appointment";
    if (lower.contains("lab")) return "Lab";
    if (lower.contains("medication") || lower.contains("meds")) {
      return "Medication";
    }
    if (lower.contains("exercise") || lower.contains("workout")) {
      return "Exercise";
    }
    return "Imported";
  }
}
