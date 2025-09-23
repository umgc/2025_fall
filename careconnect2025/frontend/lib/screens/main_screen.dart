import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../config/navigation/bottom_nav_config.dart';
import '../config/navigation/main_screen_config.dart';

class MainScreen extends StatefulWidget {
  final int? initialTabIndex;
  final MainScreenConfig? config;
  final String? userRole;
  final int? patientId;

  const MainScreen({
    super.key,
    this.initialTabIndex,
    this.config,
    this.userRole,
    this.patientId,
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

  void _initializeConfig() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (widget.config != null) {
      _config = widget.config!;
    } else {
      final role = widget.userRole ?? userProvider.user?.role ?? 'PATIENT';
      final patientId = widget.patientId ?? userProvider.user?.patientId;
      final caregiverId = userProvider.user?.caregiverId;

      _config = MainScreenConfig(
        userRole: role,
        patientId: patientId,
        caregiverId: caregiverId,
      );
    }
  }

  void _initializeNavigation() {
    setState(() {
      _navItems = _config.getNavItems();
      // Ensure selected index is within bounds
      if (_selectedIndex >= _navItems.length) {
        _selectedIndex = 0;
      }
    });
  }

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
        // Update configuration if user role changes
        final currentRole = widget.userRole ?? userProvider.user?.role ?? 'PATIENT';

        if (widget.config == null && _config.userRole != currentRole) {
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

  Widget _buildBottomNavigationBar() {
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
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

// Extension to provide easy navigation to specific tabs
extension MainScreenNavigation on BuildContext {
  void navigateToMainScreen({
    int? tabIndex,
    String? role,
    int? patientId,
    MainScreenConfig? config,
  }) {
    Navigator.of(this).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainScreen(
          initialTabIndex: tabIndex,
          config: config,
          userRole: role,
          patientId: patientId,
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