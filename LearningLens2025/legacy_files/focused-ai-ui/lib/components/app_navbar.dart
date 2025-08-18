import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AppNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showUserMenu;
  final VoidCallback? onHomePressed;

  const AppNavbar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showUserMenu = true,
    this.onHomePressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.school, color: Colors.white),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      leading: leading ?? (onHomePressed != null ? IconButton(
        icon: const Icon(Icons.home),
        onPressed: onHomePressed,
      ) : null),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.lightGreen.shade300, const Color(0xFFADD8E6)],
          ),
        ),
      ),
      elevation: 0,
      actions: [
        ...?actions,
        if (showUserMenu) _buildUserMenu(context),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildUserMenu(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;
        final displayName = user?.email ?? user?.username ?? 'User';
        final platformName = user?.lmsType.toString().split('.').last.toUpperCase() ?? 'Unknown';

        return PopupMenuButton<String>(
          icon: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              color: Theme.of(context).primaryColor,
            ),
          ),
          onSelected: (value) {
            if (value == 'logout') {
              _handleLogout(context);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  const Icon(Icons.person),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'platform',
              child: Row(
                children: [
                  const Icon(Icons.devices),
                  const SizedBox(width: 8),
                  Text('Platform: $platformName'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authService.logout();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}