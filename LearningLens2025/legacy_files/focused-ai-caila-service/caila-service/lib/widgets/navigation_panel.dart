import 'package:flutter/material.dart';
import 'nav_section.dart';
import 'nav_item.dart';

class NavigationPanel extends StatelessWidget {
  final String? selectedItem;
  final Function(String) onItemSelected;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const NavigationPanel({
    super.key,
    this.selectedItem,
    required this.onItemSelected,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCollapsed ? 80 : 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 24,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'CAILA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (onToggleCollapse != null)
                  IconButton(
                    icon: Icon(
                      isCollapsed ? Icons.menu : Icons.menu_open,
                      color: Colors.white,
                    ),
                    onPressed: onToggleCollapse,
                  ),
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                NavSection(
                  title: isCollapsed ? null : 'Material Creation',
                  isCollapsed: isCollapsed,
                  children: [
                    NavItem(
                      icon: Icons.auto_awesome,
                      title: isCollapsed ? null : 'Generate Materials',
                      isSelected: selectedItem == 'generate',
                      onTap: () => onItemSelected('generate'),
                      isCollapsed: isCollapsed,
                    ),
                    NavItem(
                      icon: Icons.chat,
                      title: isCollapsed ? null : 'Chat with CAILA',
                      isSelected: selectedItem == 'chat',
                      onTap: () => onItemSelected('chat'),
                      isCollapsed: isCollapsed,
                    ),
                  ],
                ),
                NavSection(
                  title: isCollapsed ? null : 'History & Logs',
                  isCollapsed: isCollapsed,
                  children: [
                    NavItem(
                      icon: Icons.history,
                      title: isCollapsed ? null : 'Chat History',
                      isSelected: selectedItem == 'history',
                      onTap: () => onItemSelected('history'),
                      isCollapsed: isCollapsed,
                    ),
                    NavItem(
                      icon: Icons.people,
                      title: isCollapsed ? null : 'Student Logs',
                      isSelected: selectedItem == 'logs',
                      onTap: () => onItemSelected('logs'),
                      isCollapsed: isCollapsed,
                    ),
                  ],
                ),
                NavSection(
                  title: isCollapsed ? null : 'Materials',
                  isCollapsed: isCollapsed,
                  children: [
                    NavItem(
                      icon: Icons.folder,
                      title: isCollapsed ? null : 'My Materials',
                      isSelected: selectedItem == 'materials',
                      onTap: () => onItemSelected('materials'),
                      isCollapsed: isCollapsed,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}