import 'package:care_connect_app/config/navigation/caregiver-more-features-bottom-drawer.dart';
import 'package:care_connect_app/features/dashboard/caregiver-dashboard/pages/caregiver-dashboard.dart';
import 'package:care_connect_app/features/health/symptom-tracker/pages/symptom_allergies_tracker_screen.dart';
import 'package:flutter/material.dart';
import '../../screens/tabs/patient_tabs.dart';
import '../../screens/tabs/caregiver_tabs.dart';
import 'patient-more-features-bottom-drawer.dart';

/// This is the individual bottom nav bar buttons
/// @param label - The label of the button
/// @param icon - The icon of the button
/// @param activeIcon - The active icon of the button
/// @param routeName - The route name of the button
/// @param screen - The optional screen of the button (which is rendered when clicked on
/// the button)
/// @param onPress - The optional function to be called when the button is
/// pressed.
/// @param requiresPatientId - Whether the button requires a patient ID to be
/// set
///
class BottomNavItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String routeName;
  final Widget? screen;
  final bool requiresPatientId;
  final void Function(BuildContext context, WidgetBuilder builder)? onPress;

  const BottomNavItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    required this.routeName,
    this.screen,
    this.requiresPatientId = false,
    this.onPress,
  }) : assert(
         screen != null || onPress != null,
         'Either screen or onPress must be provided',
       );
}

/// The bottom nav bar config for each role. To add a new role create a method
/// and build a list of BottomNavItem objects.
class BottomNavConfig {
  /// Get Patient Bottom Nav bar items:
  /// Home, Symptoms, Health, Symptoms, Messages, More
  /// The More will open up a bottom drawer modal which will show additional
  /// features
  static List<BottomNavItem> getPatientNavItems() {
    return [
      BottomNavItem(
        label: 'Home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        routeName: 'home',
        screen: const PatientHomeTab(),
      ),
      BottomNavItem(
        label: 'Symptoms',
        icon: Icons.medical_information_outlined,
        activeIcon: Icons.medical_information,
        routeName: 'symptoms',
        screen: const SymptomsAllergiesPage(),
      ),
      BottomNavItem(
        label: 'Health',
        icon: Icons.health_and_safety_outlined,
        activeIcon: Icons.health_and_safety,
        routeName: 'health',
        screen: const PatientHealthTab(),
      ),
      BottomNavItem(
        label: 'Messages',
        icon: Icons.message_outlined,
        activeIcon: Icons.message,
        routeName: 'messages',
        screen: const PatientMessagesTab(),
      ),
      BottomNavItem(
        label: 'More',
        icon: Icons.more_horiz_outlined,
        activeIcon: Icons.more,
        routeName: 'more',
        onPress: (context, builder) {
          showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) {
              return const PatientMoreFeaturesBottomDrawerWidget();
            },
          );
        },
      ),
    ];
  }

  /// Build Caregiver Bottom Nav bar items:
  /// Home, Tasks, Analytics, Messages, Profile
  static List<BottomNavItem> getCaregiverNavItems() {
    return [
      BottomNavItem(
        label: 'Home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        routeName: 'home',
        screen: const CaregiverDashboard(),
      ),
      BottomNavItem(
        label: 'Tasks',
        icon: Icons.assignment_outlined,
        activeIcon: Icons.assignment,
        routeName: 'tasks',
        screen: const CaregiverTasksTab(),
      ),
      BottomNavItem(
        label: 'Analytics',
        icon: Icons.analytics_outlined,
        activeIcon: Icons.analytics,
        routeName: 'analytics',
        screen: const CaregiverAnalyticsTab(),
      ),
      BottomNavItem(
        label: 'Messages',
        icon: Icons.message_outlined,
        activeIcon: Icons.message,
        routeName: 'messages',
        screen: const CaregiverMessagesTab(),
      ),
      BottomNavItem(
        label: 'More',
        icon: Icons.more_horiz_outlined,
        activeIcon: Icons.more,
        routeName: 'profile',
        onPress: (context, builder) {
          showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) {
              return const CaregiverMoreFeaturesBottomDrawerWidget();
            },
          );
        },

      ),
    ];
  }

  /// Get nav items for a given role
  /// @param role - The role of the user
  static List<BottomNavItem> getNavItemsForRole(String role) {
    switch (role.toUpperCase()) {
      case 'PATIENT':
        return getPatientNavItems();
      case 'CAREGIVER':
      case 'FAMILY_LINK':
      case 'ADMIN':
        return getCaregiverNavItems();
      default:
        // TODO - We should throw exception if the roles doesn't exist
        //        We don't want any data leakage.
        return getPatientNavItems();
    }
  }
}
