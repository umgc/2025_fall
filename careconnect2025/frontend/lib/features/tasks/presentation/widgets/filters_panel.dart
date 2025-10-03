import 'package:care_connect_app/features/tasks/utils/task_type_utils.dart';
import 'package:care_connect_app/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Panel with filter chips for Task Types and Patients.
class FiltersPanel extends StatelessWidget {
  final bool expanded;
  final Map<int, String> patientNames;
  final Set<String> selectedTypes;
  final Set<int> selectedPatients;
  final VoidCallback onClear;
  final ValueChanged<String> onTypeToggled;
  final ValueChanged<int> onPatientToggled;
  final VoidCallback onToggleExpanded;
  final VoidCallback onTodayPressed;

  const FiltersPanel({
    super.key,
    required this.expanded,
    required this.patientNames,
    required this.selectedTypes,
    required this.selectedPatients,
    required this.onClear,
    required this.onTypeToggled,
    required this.onPatientToggled,
    required this.onToggleExpanded,
    required this.onTodayPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isCaregiver =
        Provider.of<UserProvider>(context, listen: false).user?.isCaregiver ??
        false;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            fit: FlexFit.tight,
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: const Text("Filters"),
                    trailing: IconButton(
                      icon: Icon(
                        expanded ? Icons.expand_more : Icons.chevron_right,
                      ),
                      onPressed: onToggleExpanded,
                    ),
                  ),
                  if (expanded) ...[
                    // -----------------------
                    // Task Type Filters
                    // -----------------------
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                      child: Text(
                        "Task Types",
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: TaskTypeUtils.getSortedTypes().map((type) {
                          return FilterChip(
                            label: Text(
                              type[0].toUpperCase() + type.substring(1),
                            ),
                            selected: selectedTypes.contains(type),
                            onSelected: (_) => onTypeToggled(type),
                          );
                        }).toList(),
                      ),
                    ),

                    // -----------------------
                    // Patient Filters
                    // -----------------------
                    if (isCaregiver) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                        child: Text(
                          "Patients",
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: patientNames.entries.map((entry) {
                            return FilterChip(
                              label: Text(entry.value),
                              selected: selectedPatients.contains(entry.key),
                              onSelected: (_) => onPatientToggled(entry.key),
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    // -----------------------
                    // Clear button
                    // -----------------------
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.clear),
                        label: const Text("Clear"),
                        onPressed: onClear,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.today),
            label: const Text("Today"),
            onPressed: onTodayPressed,
          ),
        ],
      ),
    );
  }
}
