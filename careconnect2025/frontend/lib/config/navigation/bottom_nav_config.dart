import 'package:care_connect_app/features/dashboard/presentation/sosscreen.dart';
import 'package:care_connect_app/features/health/presentation/pages/symptom_tracker_screen.dart';
import 'package:flutter/material.dart';
import '../../screens/tabs/patient_tabs.dart';
import '../../screens/tabs/caregiver_tabs.dart';
import '../../screens/placeholder_screens.dart';

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
        label: 'More',
        icon: Icons.more_horiz_outlined,
        activeIcon: Icons.more,
        routeName: 'more',
        onPress: (context, builder) {
          showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) {
              return SizedBox(
                height: 280,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'Additional Features',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SymptomTrackerScreen(),
                              ),
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const <Widget>[
                              ListTile(
                                leading: Icon(Icons.healing, color: Colors.blue),
                                title: Text('Symptom Tracker'),
                                subtitle: Text(
                                  'Track and Manage Symptoms',
                                ),
                                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SosScreen(),
                              ),
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const <Widget>[
                              ListTile(
                                leading: Icon(Icons.sos, color: Colors.red),
                                title: Text('SOS'),
                                subtitle: Text(
                                  'Informing Caregiver of emergency',
                                ),
                                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        child: const Text('Close'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
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
        // TODO - We should throw exception if the roles doesn't exist
        //        We don't want any data leakage.
        return getPatientNavItems();
    }
  }
}
