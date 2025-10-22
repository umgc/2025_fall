import 'package:flutter/material.dart';

/// =============================
/// LegendDot Widget
/// =============================
///
/// Displays a small colored dot followed by a text label.
/// - Typically used in a legend to explain what different colors mean
///   (e.g., task types in the calendar).
///
/// Example:
/// ```dart
/// LegendDot(color: Colors.blue, label: "Medication")
/// ```
///
/// This will render a small blue circle with the text "Medication" beside it.
class LegendDot extends StatelessWidget {
  /// The color of the dot.
  final Color color;

  /// The label text shown next to the dot.
  final String label;

  const LegendDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
