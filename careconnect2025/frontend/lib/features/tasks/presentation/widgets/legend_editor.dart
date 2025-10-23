import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/task_type_manager.dart';
import 'legend.dart';

/// =============================
/// LegendEditor Widget
/// =============================
///
/// Provides an interface for managing task types.
/// Users can view, add, edit, delete, and reset types.
/// Prevents deleting types that are currently used.
class LegendEditor extends StatelessWidget {
  /// A set of task types that are currently in use (optional)
  final Set<String> usedTaskTypes;

  const LegendEditor({super.key, this.usedTaskTypes = const {}});

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<TaskTypeManager>();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 500,
          ), // limit dialog height
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Manage Task Types",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),

                /// Legend
                Legend(
                  showManageButton: false,
                  onTypeTap: (type) {
                    final color = manager.getColor(type);
                    final icon = manager.getIcon(type);
                    _editType(context, manager, type, color, icon);
                  },
                  onTypeLongPress: (type) =>
                      _confirmDelete(context, manager, type),
                ),

                const SizedBox(height: 12),

                /// Action Buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _addTaskType(context, manager),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Task Type'),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Reset Task Types"),
                            content: const Text(
                              "Restore default icons and colors for all task types?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Reset"),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) await manager.resetDefaults();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text("Reset Defaults"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// =============================
  /// Edit Existing Task Type
  /// =============================
  ///
  /// Opens a dialog allowing the user to modify color or icon.
  /// Includes an option to delete the type with usage checks.
  void _editType(
    BuildContext context,
    TaskTypeManager manager,
    String name,
    Color currentColor,
    IconData currentIcon,
  ) async {
    Color selectedColor = currentColor;
    IconData selectedIcon = currentIcon;

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Edit '$name'"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Pick Color:"),
                  const SizedBox(height: 8),
                  _ColorPicker(
                    selectedColor: selectedColor,
                    onColorSelected: (c) => setState(() => selectedColor = c),
                  ),
                  const SizedBox(height: 16),
                  const Text("Pick Icon:"),
                  const SizedBox(height: 8),
                  _IconPicker(
                    selectedIcon: selectedIcon,
                    onIconSelected: (i) => setState(() => selectedIcon = i),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                // Delete Button
                TextButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () async {
                    await _attemptDelete(context, manager, name);
                  },
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await manager.updateTaskColor(name, selectedColor);
                    await manager.updateTaskIcon(name, selectedIcon);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// =============================
  /// Attempt Delete
  /// =============================
  ///
  /// Checks if the type is in use before deleting.
  /// Shows an error message if it cannot be deleted.
  Future<void> _attemptDelete(
    BuildContext context,
    TaskTypeManager manager,
    String name,
  ) async {
    // If task type is in use, show error instead of confirmation
    final isUsed = usedTaskTypes.contains(name.toLowerCase());
    if (isUsed) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Cannot Delete Task Type"),
          content: Text(
            "The task type '$name' is currently used by one or more tasks. "
            "Please reassign or delete those tasks before removing this type.",
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    // Otherwise, show normal confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete task type '$name'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await manager.removeTaskType(name);
      if (context.mounted) Navigator.pop(context);
    }
  }

  /// =============================
  /// Add New Task Type
  /// =============================
  ///
  /// Opens a dialog to create a new task type
  /// with a custom color and icon.
  void _addTaskType(BuildContext context, TaskTypeManager manager) {
    final nameController = TextEditingController();
    Color selectedColor = Colors.grey;
    IconData selectedIcon = Icons.task;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Add Task Type"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Task Type Name",
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("Pick Color:"),
                  const SizedBox(height: 8),
                  _ColorPicker(
                    selectedColor: selectedColor,
                    onColorSelected: (c) => setState(() => selectedColor = c),
                  ),
                  const SizedBox(height: 16),
                  const Text("Pick Icon:"),
                  const SizedBox(height: 8),
                  _IconPicker(
                    selectedIcon: selectedIcon,
                    onIconSelected: (i) => setState(() => selectedIcon = i),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      await manager.addTaskType(
                        nameController.text,
                        selectedColor,
                        icon: selectedIcon,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// =============================
  /// Long-Press Delete Fallback
  /// =============================
  ///
  /// Used when the user long-presses a type in the legend.
  void _confirmDelete(
    BuildContext context,
    TaskTypeManager manager,
    String name,
  ) {
    _attemptDelete(context, manager, name);
  }
}

/// =============================
/// Long-Press Delete Fallback
/// =============================
///
/// Used when the user long-presses a type in the legend.
class _ColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const _ColorPicker({
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.brown,
      Colors.cyan,
      Colors.indigo,
    ];
    return Wrap(
      spacing: 8,
      children: colors.map((c) {
        final isSelected = selectedColor == c;
        return GestureDetector(
          onTap: () => onColorSelected(c),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// =============================
/// _IconPicker Helper
/// =============================
///
/// Displays a grid of icons for the user to select.
class _IconPicker extends StatelessWidget {
  final IconData selectedIcon;
  final ValueChanged<IconData> onIconSelected;

  const _IconPicker({required this.selectedIcon, required this.onIconSelected});

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.task,
      Icons.medication,
      Icons.event,
      Icons.fitness_center,
      Icons.science,
      Icons.local_pharmacy,
      Icons.file_upload,
      Icons.home_repair_service,
      Icons.favorite,
      Icons.check_circle,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: icons.map((i) {
        final isSelected = selectedIcon == i;
        return GestureDetector(
          onTap: () => onIconSelected(i),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(i, size: 20),
          ),
        );
      }).toList(),
    );
  }
}
