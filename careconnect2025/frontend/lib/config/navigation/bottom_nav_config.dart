import 'package:flutter/material.dart';
import '../../screens/tabs/patient_tabs.dart';
import '../../screens/tabs/caregiver_tabs.dart';

class BottomNavItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String routeName;
  final Widget screen;
  final bool requiresPatientId;

  const BottomNavItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    required this.routeName,
    required this.screen,
    this.requiresPatientId = false,
  });
}

class BottomNavConfig {
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
        label: 'Profile',
        icon: Icons.person_outlined,
        activeIcon: Icons.person,
        routeName: 'profile',
        screen: const PatientProfileTab(),
      ),
    ];
  }

  static List<BottomNavItem> getCaregiverNavItems() {
    return [
      BottomNavItem(
        label: 'Patients',
        icon: Icons.people_outlined,
        activeIcon: Icons.people,
        routeName: 'patients',
        screen: const CaregiverPatientsTab(),
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
        label: 'Profile',
        icon: Icons.person_outlined,
        activeIcon: Icons.person,
        routeName: 'profile',
        screen: const CaregiverProfileTab(),
      ),
    ];
  }

  static List<BottomNavItem> getNavItemsForRole(String role) {
    switch (role.toUpperCase()) {
      case 'PATIENT':
        return getPatientNavItems();
      case 'CAREGIVER':
      case 'FAMILY_LINK':
      case 'ADMIN':
        return getCaregiverNavItems();
      default:
        return getPatientNavItems();
    }
  }
}

