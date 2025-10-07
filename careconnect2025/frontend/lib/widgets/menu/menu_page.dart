import 'package:care_connect_app/core/services/api_service.dart';
import 'package:care_connect_app/providers/user_provider.dart';
import 'package:care_connect_app/widgets/theme_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
 

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
        body: _LoggedOutPrompt(onLogin: () => context.go('/login')),
      );
    }

    final role = user.role.toUpperCase();
    final isCaregiver = role == 'CAREGIVER' || role == 'FAMILY_LINK' || role == 'ADMIN';
    final isPatient = role == 'PATIENT';

    final items = <_MenuItem>[
      // Assistants and core features
      _MenuItem(
        icon: Icons.receipt_long,
        label: 'Invoice Assistant',
        route: '/invoice-assistant/dashboard',
        visibleFor: const {'CAREGIVER', 'ADMIN'},
      ),
      _MenuItem(
        icon: Icons.verified_user,
        label: 'EVV',
        route: '/evv',
        visibleFor: const {'CAREGIVER', 'ADMIN'},
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
        icon: Icons.watch,
        label: 'Wearables',
        route: '/wearables',
      ),
      _MenuItem(
        icon: Icons.folder,
        label: 'File Management',
        route: '/file-management',
      ),
      // Caregiver shortcuts
      _MenuItem(
        icon: Icons.person_add,
        label: 'Add Patient',
        route: '/add-patient',
        visibleFor: const {'CAREGIVER', 'ADMIN'},
      ),
      // Settings and theme
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
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _HeaderCard(
              name: user.name ?? 'User',
              role: role,
              imageUrl: _profileImageUrl,
              onTapProfile: () => context.go('/profile'),
            ),
          ),

          // Shortcuts section: shows a small curated set depending on role
          SliverToBoxAdapter(
            child: _SectionHeader(title: 'Your shortcuts'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
            delegate: SliverChildListDelegate.fixed(
              _shortcutTiles(context, role, user.id.toString()),
            ),

              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisExtent: 88,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
            ),
          ),

          // Tools section 
          SliverToBoxAdapter(child: _SectionHeader(title: 'Tools')),
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

          // Settings and theme toggle
          SliverToBoxAdapter(child: _SectionHeader(title: 'Preferences')),
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.brightness_6),
                title: const Text('Dark Mode'),
                trailing: const ThemeToggleSwitch(showIcon: false, showLabel: false),
              ),
            ),
          ),

          // Logout
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                title: Text('Logout', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () async {
                  await userProvider.clearUser();
                  if (context.mounted) context.go('/');
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      bottomNavigationBar: _BottomHintBar(
        onGoHome: () => context.go('/dashboard'),
        onGoProfile: () => context.go('/profile'),
      ),
    );
  }

  List<Widget> _shortcutTiles(BuildContext context, String role, String? userId) {
    final isCaregiver = role == 'CAREGIVER' || role == 'ADMIN' || role == 'FAMILY_LINK';
    final tiles = <_Shortcut>[
      _Shortcut(Icons.dashboard, 'Dashboard', onTap: () => context.go('/dashboard')),
      if (isCaregiver) _Shortcut(Icons.receipt, 'Invoices', onTap: () => context.go('/invoice-assistant/dashboard')),
      _Shortcut(Icons.calendar_today, 'Calendar', onTap: () => context.go('/calendar')),
      _Shortcut(Icons.forum, 'Feed', onTap: () => context.go('/social-feed?userId=$userId')),
      _Shortcut(Icons.medical_information, 'Meds', onTap: () => context.go('/medication')),
      if (isCaregiver) _Shortcut(Icons.shield, 'EVV', onTap: () => context.go('/evv')),
      _Shortcut(Icons.watch, 'Wearables', onTap: () => context.go('/wearables')),
      _Shortcut(Icons.folder, 'Files', onTap: () => context.go('/file-management')),
    ];

    return tiles.take(8).map((s) => _ShortcutTile(shortcut: s)).toList();
  }
}

/* ---------- Small components ---------- */

class _HeaderCard extends StatelessWidget {
  final String name;
  final String role;
  final String? imageUrl;
  final VoidCallback onTapProfile;

  const _HeaderCard({
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.onTapProfile,
  });

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onPrimary;
    return GestureDetector(
      onTap: onTapProfile,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        color: Theme.of(context).appBarTheme.backgroundColor,
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: fg,
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
              child: imageUrl == null
                  ? Icon(Icons.person, size: 30, color: Theme.of(context).primaryColor)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).appBarTheme.foregroundColor ??
                                Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        role,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(width: 8),
                      Text('View Profile',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

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
        onTap: item.onTap ?? (item.route != null ? () => context.go(item.route!) : null),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(item.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(item.label, style: Theme.of(context).textTheme.bodyMedium),
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
            Text('Please log in', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'You need to be logged in to access the menu',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).disabledColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onLogin, child: const Text('Login')),
          ],
        ),
      ),
    );
  }
}

class _BottomHintBar extends StatelessWidget {
  final VoidCallback onGoHome;
  final VoidCallback onGoProfile;
  const _BottomHintBar({required this.onGoHome, required this.onGoProfile});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGoHome,
                icon: const Icon(Icons.home),
                label: const Text('Home'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGoProfile,
                icon: const Icon(Icons.person),
                label: const Text('Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
