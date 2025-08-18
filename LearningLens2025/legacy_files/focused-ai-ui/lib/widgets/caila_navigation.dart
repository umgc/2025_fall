// lib/widgets/caila_navigation.dart - SINGLE FILE FOR ALL CAILA NAV WIDGETS
import 'package:flutter/material.dart';

// Main navigation panel for CAILA
class CailaNavigationPanel extends StatelessWidget {
  final String? selectedItem;
  final Function(String) onItemSelected;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const CailaNavigationPanel({
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
                const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 24,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  const Expanded(
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
                _CailaNavSection(
                  title: isCollapsed ? null : 'Material Creation',
                  isCollapsed: isCollapsed,
                  children: [
                    _CailaNavItem(
                      icon: Icons.auto_awesome,
                      title: isCollapsed ? null : 'Generate Materials',
                      isSelected: selectedItem == 'generate',
                      onTap: () => onItemSelected('generate'),
                      isCollapsed: isCollapsed,
                    ),
                  ],
                ),
                _CailaNavSection(
                  title: isCollapsed ? null : 'History & Logs',
                  isCollapsed: isCollapsed,
                  children: [
                    _CailaNavItem(
                      icon: Icons.history,
                      title: isCollapsed ? null : 'Chat History',
                      isSelected: selectedItem == 'history',
                      onTap: () => onItemSelected('history'),
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

// Private navigation section widget (prefixed with _ to make it private)
class _CailaNavSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final bool isCollapsed;

  const _CailaNavSection({
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

// Private navigation item widget (prefixed with _ to make it private)
class _CailaNavItem extends StatelessWidget {
  final IconData icon;
  final String? title;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCollapsed;

  const _CailaNavItem({
    required this.icon,
    this.title,
    required this.isSelected,
    required this.onTap,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 8 : 8,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 8 : 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[600],
                ),
                if (!isCollapsed && title != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}