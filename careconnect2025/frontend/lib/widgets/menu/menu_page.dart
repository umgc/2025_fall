import 'package:care_connect_app/core/services/api_service.dart';
import 'package:care_connect_app/providers/user_provider.dart';
import 'package:care_connect_app/widgets/menu/shortcut_search_delegate.dart';
import 'package:care_connect_app/widgets/theme_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:care_connect_app/providers/shortcut_provider.dart';
import 'package:care_connect_app/features/invoices/screens/invoice_tabbed_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  Future<void> _loadProfilePicture() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      if (userId != null) {
        final role = userProvider.user?.role;
        final url = await ApiService.getUserProfilePictureUrl(userId, role);
        if (!mounted) return;
        setState(() => _profileImageUrl = url);
      }
    } catch (_) {
      // Keep avatar fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Menu')),
        body: _LoggedOutPrompt(onLogin: () => context.push('/login')),
      );
    }

    final role = user.role.toUpperCase();

    final shortcutProvider = context.watch<ShortcutProvider>();
    if (!shortcutProvider.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final activeShortcuts = shortcutProvider.visibleActiveForRole(role);
    String resolveRoute(ShortcutDef d) =>
        d.resolveRoute({'userId': user.id.toString()});

    final items = <_MenuItem>[
      _MenuItem(
        icon: Icons.receipt_long,
        label: 'Invoice Assistant',
        route: '/invoice-assistant/dashboard',
        visibleFor: const {'CAREGIVER', 'ADMIN'},
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InvoiceTabbedPage()),
          );
        },
      ),
      _MenuItem(
        icon: Icons.verified_user,
        label: 'EVV',
        route: '/evv',
        visibleFor: const {'CAREGIVER', 'ADMIN', 'FAMILY_LINK'},
      ),
      _MenuItem(
        icon: Icons.calendar_month,
        label: 'Calendar Assistant',
        route: '/calendar',
      ),
      _MenuItem(
        icon: Icons.medication,
        label: 'Medication Management',
        route: '/medication',
      ),
      _MenuItem(
        icon: Icons.public,
        label: 'Social Feed',
        onTap: () => context.go('/social-feed?userId=${user.id}'),
      ),
      _MenuItem(
        icon: Icons.emoji_events,
        label: 'Gamification',
        route: '/gamification',
      ),
      _MenuItem(icon: Icons.watch, label: 'Wearables', route: '/wearables'),
      _MenuItem(
        icon: Icons.folder,
        label: 'File Management',
        route: '/file-management',
      ),
      _MenuItem(
        icon: Icons.mail,
        label: 'Informed Delivery',
        route: '/informed-delivery',
      ),
      _MenuItem(
        icon: Icons.person_add,
        label: 'Add Patient',
        route: '/add-patient',
        visibleFor: const {'CAREGIVER', 'ADMIN'},
      ),
      _MenuItem(
        icon: Icons.settings,
        label: 'Settings',
        route: '/settings',
        section: _Section.settings,
      ),
    ].where((m) => m.isVisibleFor(role)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          IconButton(
              onPressed: () => showSearch(
                context: context,
                delegate: ShortcutSearchDelegate(
                  roleUpper: role,                  
                  userId: user.id.toString(),
                ),
              ),
              icon: const Icon(Icons.search),
              tooltip: 'Search',
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Profile header
          SliverToBoxAdapter(
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                backgroundImage: _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : null,
                child: _profileImageUrl == null
                    ? Icon(Icons.person, color: Theme.of(context).primaryColor)
                    : null,
              ),
              title: Text(
                user.name ?? 'User',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => context.push('/profile'),
              ),
              onTap: () => context.push('/profile'),
            ),
          ),

          // Shortcuts header + customize
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Your shortcuts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.tune),
                    tooltip: 'Customize',
                    onPressed: () => _openCustomizeShortcuts(context, role),
                  ),
                ],
              ),
            ),
          ),

          // Shortcuts grid from provider
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisExtent: 88,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              delegate: SliverChildListDelegate.fixed(
                activeShortcuts
                    .map(
                      (d) => _ShortcutTile(
                        shortcut: _Shortcut(
                          d.icon,
                          d.label,
                          onTap: () => context.push(resolveRoute(d)),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          // Tools
          const SliverToBoxAdapter(child: _SectionHeader(title: 'Tools')),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 64,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ToolTile(item: items[index]),
                childCount: items.length,
              ),
            ),
          ),

          // Preferences
          const SliverToBoxAdapter(child: _SectionHeader(title: 'Preferences')),
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: const ListTile(
                leading: Icon(Icons.brightness_6),
                title: Text('Dark Mode'),
                trailing: ThemeToggleSwitch(showIcon: false, showLabel: false),
              ),
            ),
          ),

          // Logout
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () async {
                  await userProvider.clearUser();
                  if (context.mounted) context.go('/');
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      )
    );
  }

  Future<void> _openCustomizeShortcuts(
    BuildContext context,
    String roleUpper,
  ) async {
    final sp = context.read<ShortcutProvider>();
    final list = sp.visibleCatalogForRole(roleUpper);
    final working = Set<String>.from(sp.activeKeys);
    final max = ShortcutProvider.maxShortcuts;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 12 + MediaQuery.of(ctx).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Customize Shortcuts',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: list.map((d) {
                    final checked = working.contains(d.key);
                    return CheckboxListTile(
                      value: checked,
                      title: Row(
                        children: [
                          Icon(d.icon),
                          const SizedBox(width: 12),
                          Text(d.label),
                        ],
                      ),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            if (working.length < max) working.add(d.key);
                          } else {
                            working.remove(d.key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await sp.setAll(working);
                        if (mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------- Small components ---------- */

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

enum _Section { tools, settings }

class _MenuItem {
  final IconData icon;
  final String label;
  final String? route;
  final VoidCallback? onTap;
  final _Section section;
  final Set<String>? visibleFor;

  _MenuItem({
    required this.icon,
    required this.label,
    this.route,
    this.onTap,
    this.section = _Section.tools,
    this.visibleFor,
  });

  bool isVisibleFor(String roleUpper) {
    if (visibleFor == null || visibleFor!.isEmpty) return true;
    return visibleFor!.contains(roleUpper);
  }
}

class _ToolTile extends StatelessWidget {
  final _MenuItem item;
  const _ToolTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            item.onTap ??
            (item.route != null ? () => context.push(item.route!) : null),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(item.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _Shortcut {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _Shortcut(this.icon, this.label, {required this.onTap});
}

class _ShortcutTile extends StatelessWidget {
  final _Shortcut shortcut;
  const _ShortcutTile({required this.shortcut});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: shortcut.onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(shortcut.icon, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          shortcut.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _LoggedOutPrompt extends StatelessWidget {
  final VoidCallback onLogin;
  const _LoggedOutPrompt({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.login, size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 12),
            Text(
              'Please log in',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'You need to be logged in to access the menu',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onLogin, child: const Text('Login')),
          ],
        ),
      ),
    );
  }
}
