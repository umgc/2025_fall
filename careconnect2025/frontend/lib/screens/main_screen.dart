import 'package:care_connect_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../config/navigation/bottom_nav_config.dart';
import '../config/navigation/main_screen_config.dart';

/// Main screen of the application. This is where the user is navigated to
/// after logging in. This contains the bottom nav bar and main screens
class MainScreen extends StatefulWidget {
  final int? initialTabIndex;
  final MainScreenConfig? config;

  const MainScreen({
    super.key,
    this.initialTabIndex,
    this.config,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<BottomNavItem> _navItems = [];
  late PageController _pageController;
  late MainScreenConfig _config;

  @override
  void initState() {
    super.initState();
    _initializeConfig();
    _pageController = PageController(initialPage: widget.initialTabIndex ?? 0);
    _selectedIndex = widget.initialTabIndex ?? 0;
    _initializeNavigation();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Initialize the MainScreenConfig object.
  void _initializeConfig() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (widget.config != null) {
      _config = widget.config!;
    } else {
      final user = userProvider.user;

      // Check if user data is missing or invalid
      if (user == null || user.role.isEmpty || user.id <= 0) {
        _redirectToLoginWithMessage('Please log in again');
        return;
      }

      final role = user.role;
      final userId = user.id;
      final patientId = user.patientId;
      final caregiverId = user.caregiverId;

      _config = MainScreenConfig(
        userRole: role,
        userId: userId,
        patientId: patientId,
        caregiverId: caregiverId,
      );
    }
  }

  /// Redirect to login screen with a message.
  void _redirectToLoginWithMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear user data
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.clearUser();

      // Show message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );

        // Navigate to login
        context.go('/login');
      }
    });
  }

  /// Initialize the navigation items.
  void _initializeNavigation() {
    setState(() {
      _navItems = _config.getNavItems();
      // Ensure selected index is within bounds
      if (_selectedIndex >= _navItems.length) {
        _selectedIndex = 0;
      }
    });
  }

  /// Handle bottom nav bar item tap.
  void _onItemTapped(int index) {
    final navItem = _navItems[index];

    // Check if onPress callback exists and call it
    if (navItem.onPress != null) {
      navItem.onPress!(context, (context) => Container());
      // Don't change screen if only onPress is present
      return;
    }

    // Only change screen if there's an actual screen to navigate to
    if (navItem.screen != null) {
      setState(() {
        _selectedIndex = index;
      });

      if (_config.enablePageAnimation) {
        _pageController.animateToPage(
          index,
          duration: _config.animationDuration,
          curve: _config.animationCurve,
        );
      } else {
        _pageController.jumpToPage(index);
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Check if user data is missing or invalid
        final currentUser = userProvider.user;
        if (widget.config == null && (currentUser == null || currentUser.role.isEmpty || currentUser.id <= 0)) {
          // Return a loading screen while redirecting
          _redirectToLoginWithMessage('Please log in again');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Update configuration if user changes
        final currentRole = currentUser?.role ?? '';
        final currentUserId = currentUser?.id ?? 0;

        if (widget.config == null && (_config.userRole != currentRole || _config.userId != currentUserId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeConfig();
            _initializeNavigation();
          });
        }
        


        return Scaffold(
          backgroundColor: _config.backgroundColor,
          appBar: _config.showAppBar ? AppBar(
            title: Text(_config.appBarTitle ?? 'CareConnect'),
            backgroundColor: _config.primaryColor ?? Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            actions: _config.appBarActions,
          ) : null,
          body: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _navItems.length,
            itemBuilder: (context, index) {
              final navItem = _navItems[index];

              return _navItems[index].screen;
            },
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  /// Build the bottom navigation bar
  Widget _buildBottomNavigationBar() {
   final t = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: _config.primaryColor ?? Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 24,
        items: _navItems.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.activeIcon ?? item.icon),
           label: item.localizedLabel(t),
          );
        }).toList(),
      ),
    );
  }
}

/// Extension to provide easy navigation to specific tabs
extension MainScreenNavigation on BuildContext {
  void navigateToMainScreen({
    int? tabIndex,
    MainScreenConfig? config,
  }) {
    Navigator.of(this).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainScreen(
          initialTabIndex: tabIndex,
          config: config,
        ),
      ),
    );
  }

  void navigateToMainScreenWithConfig(MainScreenConfig config, {int? tabIndex}) {
    Navigator.of(this).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainScreen(
          initialTabIndex: tabIndex,
          config: config,
        ),
      ),
    );
  }
}