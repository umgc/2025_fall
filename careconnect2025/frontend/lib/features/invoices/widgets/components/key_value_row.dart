// components/key_value_row.dart
import 'package:flutter/material.dart';

class KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final bool success;
  final bool allowWrap; // new

  const KeyValueRow(
    this.label,
    this.value, {
    this.success = false,
    this.allowWrap = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      color: success ? const Color(0xFF059669) : null,
      fontWeight: FontWeight.w600,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            softWrap: allowWrap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            softWrap: allowWrap,
            textAlign: TextAlign.right,
            style: valueStyle,
          ),
        ),
      ],
    );
  }
}
