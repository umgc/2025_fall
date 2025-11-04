import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../features/dashboard/presentation/pages/caregiver_dashboard.dart';
import '../../features/profile/presentation/pages/profile_settings_page.dart';
import '../../features/social/presentation/pages/chat_inbox_screen.dart';

class CaregiverPatientsTab extends StatelessWidget {
  const CaregiverPatientsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final caregiverId = userProvider.user?.caregiverId ?? 1;

    return CaregiverDashboard(
      caregiverId: caregiverId,
      userRole: userProvider.user?.role ?? 'CAREGIVER',
    );
  }
}

class CaregiverTasksTab extends StatelessWidget {
  const CaregiverTasksTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment,
              size: 80,
              color: Color(0xFF14366E),
            ),
            SizedBox(height: 16),
            Text(
              'Task Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF14366E),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Manage and assign tasks to your patients.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CaregiverAnalyticsTab extends StatelessWidget {
  const CaregiverAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 80,
              color: Color(0xFF14366E),
            ),
            SizedBox(height: 16),
            Text(
              'Patient Analytics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF14366E),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'View patient health trends and insights.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CaregiverMessagesTab extends StatelessWidget {
  const CaregiverMessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      return Scaffold(
       
        body: const Center(
          child: Text('Please log in to view messages'),
        ),
      );
    }

    return Scaffold(
       
      body: const ChatInboxScreen(),
    );
  }
}

class CaregiverProfileTab extends StatelessWidget {
  const CaregiverProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileSettingsPage();
  }
}