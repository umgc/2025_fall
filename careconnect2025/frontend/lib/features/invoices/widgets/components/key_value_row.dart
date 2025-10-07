// components/key_value_row.dart
import 'package:flutter/material.dart';

class KeyValueRow extends StatelessWidget {
  const KeyValueRow(
    this.k,
    this.v, {
    super.key,
    this.success = false,
    this.muted = false,
    this.mono = false,
  });

  final String k;
  final String v;
  final bool success;
  final bool muted;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: theme.textTheme.bodySmall),
        Flexible(
          child: Text(
            v,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: success
                  ? const Color(0xFF059669)
                  : muted
                      ? theme.colorScheme.onSurface.withOpacity(0.7)
                      : null,
              fontFamily: mono ? 'monospace' : null,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
