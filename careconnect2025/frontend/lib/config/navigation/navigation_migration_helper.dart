import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../screens/main_screen.dart';
import 'main_screen_config.dart';

/// Helper class to migrate from old navigation patterns to new MainScreen
class NavigationMigrationHelper {
  /// Migrate from old PatientDashboard navigation
  static void navigateToPatientDashboard(
    BuildContext context, {
    int? patientId,
    int? tabIndex,
  }) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null || user.id <= 0) {
      // Redirect to login if no valid user
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final userId = user.id;
    final pId = patientId ?? user.patientId;

    final config = MainScreenConfig.forPatient(userId: userId, patientId: pId);

    context.navigateToMainScreenWithConfig(config, tabIndex: tabIndex);
  }

  /// Migrate from old CaregiverDashboard navigation
  static void navigateToCaregiverDashboard(
    BuildContext context, {
    int? caregiverId,
    int? patientId,
    int? tabIndex,
  }) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null || user.id <= 0) {
      // Redirect to login if no valid user
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final userId = user.id;
    final cId = caregiverId ?? user.caregiverId;

    final config = MainScreenConfig.forCaregiver(
      userId: userId,
      caregiverId: cId,
      patientId: patientId,
    );

    context.navigateToMainScreenWithConfig(config, tabIndex: tabIndex);
  }

  /// Navigate to specific tabs by name
  static void navigateToTab(
    BuildContext context,
    String tabName, {
    String? userRole,
  }) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final role = userRole ?? userProvider.user?.role ?? 'PATIENT';

    int? tabIndex;
    if (role.toUpperCase() == 'PATIENT') {
      switch (tabName.toLowerCase()) {
        case 'home':
        case 'dashboard':
          tabIndex = 0;
          break;
        case 'health':
        case 'medical':
          tabIndex = 1;
          break;
        case 'messages':
        case 'chat':
        case 'communication':
          tabIndex = 2;
          break;
        case 'profile':
        case 'settings':
          tabIndex = 3;
          break;
      }
    } else {
      switch (tabName.toLowerCase()) {
        case 'patients':
        case 'dashboard':
        case 'home':
          tabIndex = 0;
          break;
        case 'tasks':
        case 'scheduling':
          tabIndex = 1;
          break;
        case 'analytics':
        case 'reports':
        case 'insights':
          tabIndex = 2;
          break;
        case 'messages':
        case 'chat':
        case 'communication':
          tabIndex = 3;
          break;
        case 'profile':
        case 'settings':
          tabIndex = 4;
          break;
      }
    }

    if (tabIndex != null) {
      context.navigateToMainScreen(tabIndex: tabIndex);
    } else {
      // Fallback to home tab
      context.navigateToMainScreen(tabIndex: 0);
    }
  }

  /// Replace old dashboard navigation calls
  static void replaceDashboardNavigation(
    BuildContext context, {
    String? route,
    Map<String, dynamic>? parameters,
  }) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = userProvider.user?.role;

    if (userRole == null) {
      // Redirect to login if no user
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Handle specific routes
    if (route != null) {
      switch (route.toLowerCase()) {
        case '/patient_dashboard':
        case '/dashboard/patient':
          navigateToPatientDashboard(
            context,
            patientId: parameters?['patientId'],
            tabIndex: parameters?['tabIndex'],
          );
          return;

        case '/caregiver_dashboard':
        case '/dashboard/caregiver':
          navigateToCaregiverDashboard(
            context,
            caregiverId: parameters?['caregiverId'],
            patientId: parameters?['patientId'],
            tabIndex: parameters?['tabIndex'],
          );
          return;

        case '/social_feed':
        case '/social-feed':
          navigateToTab(context, 'messages', userRole: userRole);
          return;

        case '/analytics':
          navigateToTab(context, 'analytics', userRole: userRole);
          return;

        case '/profile':
        case '/profile_settings':
          navigateToTab(context, 'profile', userRole: userRole);
          return;
      }
    }

    // Default navigation based on role
    context.navigateToMainScreen();
  }

  /// Helper to check if a route should be migrated
  static bool shouldMigrateRoute(String route) {
    const routesToMigrate = [
      '/patient_dashboard',
      '/caregiver_dashboard',
      '/dashboard/patient',
      '/dashboard/caregiver',
      '/social_feed',
      '/social-feed',
      '/analytics',
      '/profile',
      '/profile_settings',
    ];

    return routesToMigrate.contains(route.toLowerCase());
  }

  /// Migrate old Navigator calls
  static void migrateNavigatorCall(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    if (shouldMigrateRoute(routeName)) {
      Map<String, dynamic>? params;
      if (arguments is Map<String, dynamic>) {
        params = arguments;
      }

      replaceDashboardNavigation(context, route: routeName, parameters: params);
    } else {
      // Use original navigation for non-migrated routes
      Navigator.pushNamed(context, routeName, arguments: arguments);
    }
  }
}

/// Extension to add migration helpers to BuildContext
extension NavigationMigration on BuildContext {
  /// Quick access to migration helpers
  void migrateToMainScreen({String? route, Map<String, dynamic>? parameters}) {
    NavigationMigrationHelper.replaceDashboardNavigation(
      this,
      route: route,
      parameters: parameters,
    );
  }

  /// Navigate to specific tab by name
  void navigateToAppTab(String tabName, {String? userRole}) {
    NavigationMigrationHelper.navigateToTab(this, tabName, userRole: userRole);
  }
}
