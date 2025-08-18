// lib/widgets/nav_item.dart
import 'package:flutter/material.dart';

class NavItem extends StatelessWidget {
  final String text;
  final bool disabled;
  final VoidCallback onTap;

  const NavItem({
    super.key,
    required this.text,
    this.disabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 24,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.black.withOpacity(0.05),
                width: 1,
              ),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: disabled ? Colors.grey : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}