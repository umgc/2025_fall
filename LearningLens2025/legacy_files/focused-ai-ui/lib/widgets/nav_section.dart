// lib/widgets/nav_section.dart
import 'package:flutter/material.dart';
import 'nav_item.dart';

class NavSection extends StatefulWidget {
  final String title;
  final List<String> items;
  final bool disabled;
  final Function(String) onItemSelected;

  const NavSection({
    super.key,
    required this.title,
    required this.items,
    this.disabled = false,
    required this.onItemSelected,
  });

  @override
  State<NavSection> createState() => _NavSectionState();
}

class _NavSectionState extends State<NavSection> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.black.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: ListTile(
            title: Text(
              widget.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2d5a2d),
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: const Color(0xFF2d5a2d),
            ),
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: Container(
            height: isExpanded ? null : 0,
            child: Column(
              children: widget.items.map((item) {
                return NavItem(
                  text: item,
                  disabled: widget.disabled && item == widget.items.first,
                  onTap: () {
                    if (!widget.disabled || item != widget.items.first) {
                      widget.onItemSelected(item);
                    }
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}