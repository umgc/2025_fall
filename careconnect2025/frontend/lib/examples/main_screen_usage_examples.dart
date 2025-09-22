import 'package:flutter/material.dart';
import '../screens/main_screen.dart';
import '../config/navigation/main_screen_config.dart';
import '../config/navigation/bottom_nav_config.dart';
import '../config/navigation/navigation_helper.dart';
import '../services/auth_service.dart';

/// This file demonstrates various ways to use the configurable MainScreen component.
/// Updated to use the new UserRoleStorageService for persistent role storage
/// across web (localStorage) and mobile (native storage) platforms.

class MainScreenUsageExamples {

  /// Example 1: Basic usage with automatic role detection
  static Widget basicUsage() {
    return const MainScreen();
  }

  /// Example 2: Patient main screen with specific configuration
  static Widget patientMainScreen(int patientId) {
    final config = MainScreenConfig.forPatient(
      patientId: patientId,
      primaryColor: Colors.blue,
    );

    return MainScreen(
      config: config,
      initialTabIndex: 0, // Start at Home tab
    );
  }

  /// Example 3: Caregiver main screen with custom settings
  static Widget caregiverMainScreen(int caregiverId, {int? patientId}) {
    final config = MainScreenConfig(
      userRole: 'CAREGIVER',
      caregiverId: caregiverId,
      patientId: patientId,
      primaryColor: Colors.green,
      showAppBar: true,
      appBarTitle: 'Caregiver Portal',
      enablePageAnimation: true,
      animationDuration: const Duration(milliseconds: 250),
    );

    return MainScreen(
      config: config,
      initialTabIndex: 0, // Start at Patients tab
    );
  }

  /// Example 4: Family member main screen with restricted navigation
  static Widget familyMemberMainScreen(int patientId) {
    final config = MainScreenConfig.forFamilyMember(
      patientId: patientId,
      primaryColor: Colors.purple,
      customNavItems: [
        // Restricted navigation for family members
        const BottomNavItem(
          label: 'Overview',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
          routeName: 'overview',
          screen: FamilyOverviewTab(),
        ),
        const BottomNavItem(
          label: 'Messages',
          icon: Icons.message_outlined,
          activeIcon: Icons.message,
          routeName: 'messages',
          screen: FamilyMessagesTab(),
        ),
        const BottomNavItem(
          label: 'Emergency',
          icon: Icons.emergency_outlined,
          activeIcon: Icons.emergency,
          routeName: 'emergency',
          screen: FamilyEmergencyTab(),
        ),
      ],
    );

    return MainScreen(config: config);
  }

  /// Example 5: Admin main screen with full access
  static Widget adminMainScreen() {
    final config = MainScreenConfig(
      userRole: 'ADMIN',
      primaryColor: Colors.red,
      backgroundColor: Colors.grey[50],
      showAppBar: true,
      appBarTitle: 'Admin Dashboard',
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // Navigate to admin settings
          },
        ),
      ],
      customNavItems: [
        const BottomNavItem(
          label: 'Users',
          icon: Icons.people_outlined,
          activeIcon: Icons.people,
          routeName: 'users',
          screen: AdminUsersTab(),
        ),
        const BottomNavItem(
          label: 'Analytics',
          icon: Icons.analytics_outlined,
          activeIcon: Icons.analytics,
          routeName: 'analytics',
          screen: AdminAnalyticsTab(),
        ),
        const BottomNavItem(
          label: 'System',
          icon: Icons.computer_outlined,
          activeIcon: Icons.computer,
          routeName: 'system',
          screen: AdminSystemTab(),
        ),
        const BottomNavItem(
          label: 'Reports',
          icon: Icons.assessment_outlined,
          activeIcon: Icons.assessment,
          routeName: 'reports',
          screen: AdminReportsTab(),
        ),
      ],
    );

    return MainScreen(config: config);
  }

  /// Example 6: Custom themed main screen
  static Widget customThemedMainScreen(String userRole) {
    final config = MainScreenConfig(
      userRole: userRole,
      primaryColor: const Color(0xFF2E7D32), // Custom green
      backgroundColor: const Color(0xFFF1F8E9), // Light green background
      enablePageAnimation: false, // Disable animations for performance
      showAppBar: true,
      appBarTitle: 'CareConnect Pro',
    );

    return MainScreen(config: config);
  }

  /// Example 7: Navigation helper usage with stored user data
  static Future<void> navigateToMainScreenExample(BuildContext context) async {
    // Method 1: Navigate to a specific tab using stored user data
    await NavigationHelper.navigateToMainScreen(context, tabIndex: 1);

    // Method 2: Navigate to a specific tab by name
    if (context.mounted) {
      await NavigationHelper.navigateToTab(context, 'messages');
    }

    // Method 3: Check if user is authenticated before navigation
    final isAuthenticated = await NavigationHelper.isAuthenticated();
    if (isAuthenticated && context.mounted) {
      await NavigationHelper.navigateToMainScreen(context);
    } else if (context.mounted) {
      // Redirect to login if not authenticated
      await NavigationHelper.logout(context);
    }
  }

  /// Example 8: Authentication flow example
  static Future<void> authenticationExample() async {
    // Login using the static AuthService methods
    try {
      await AuthService.login(
        'email@example.com',
        'password'
      );

      // Check current user data from storage
      final userData = await AuthService.getCurrentUserData();
      if (userData != null) {
        debugPrint('Current user: ${userData.toString()}');
      }

      // Update patient ID (useful for caregiver switching patients)
      await AuthService.updatePatientId(789);

      // Logout
      await AuthService.logout();
    } catch (e) {
      debugPrint('Authentication error: $e');
    }
  }
}

// Example placeholder tabs for family member restricted access
class FamilyOverviewTab extends StatelessWidget {
  const FamilyOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard, size: 80, color: Colors.purple),
            SizedBox(height: 16),
            Text('Family Member Overview', style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text('View patient status and recent updates'),
          ],
        ),
      ),
    );
  }
}

class FamilyMessagesTab extends StatelessWidget {
  const FamilyMessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message, size: 80, color: Colors.purple),
            SizedBox(height: 16),
            Text('Family Messages', style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text('Communicate with care team'),
          ],
        ),
      ),
    );
  }
}

class FamilyEmergencyTab extends StatelessWidget {
  const FamilyEmergencyTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emergency, size: 80, color: Colors.red),
            SizedBox(height: 16),
            Text('Emergency Contacts', style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text('Quick access to emergency services'),
          ],
        ),
      ),
    );
  }
}

// Example admin tabs
class AdminUsersTab extends StatelessWidget {
  const AdminUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Admin Users Management'),
      ),
    );
  }
}

class AdminAnalyticsTab extends StatelessWidget {
  const AdminAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Admin Analytics'),
      ),
    );
  }
}

class AdminSystemTab extends StatelessWidget {
  const AdminSystemTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('System Configuration'),
      ),
    );
  }
}

class AdminReportsTab extends StatelessWidget {
  const AdminReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('System Reports'),
      ),
    );
  }
}