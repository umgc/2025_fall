import 'package:flutter/material.dart';

class NavSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final bool isCollapsed;

  const NavSection({
    super.key,
    this.title,
    required this.children,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && !isCollapsed) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }
}