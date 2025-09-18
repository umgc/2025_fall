import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/careconnect_theme.dart';
import '../../../../widgets/careconnect_logo.dart';
import '../../../../widgets/careconnect_button.dart';
import '../../../../widgets/careconnect_card.dart';

class NewPatientDashboard extends StatefulWidget {
  const NewPatientDashboard({super.key});

  @override
  State<NewPatientDashboard> createState() => _NewPatientDashboardState();
}

class _NewPatientDashboardState extends State<NewPatientDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareConnectTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              
              const SizedBox(height: 32.0),
              
              // Quick actions
              _buildQuickActions(),
              
              const SizedBox(height: 32.0),
              
              // Health overview
              _buildHealthOverview(),
              
              const SizedBox(height: 32.0),
              
              // Recent activity
              _buildRecentActivity(),
              
              const SizedBox(height: 32.0),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Profile avatar
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: CareConnectTheme.primaryColor,
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 24,
          ),
        ),
        
        const SizedBox(width: 16.0),
        
        // Welcome text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning,',
                style: CareConnectTheme.bodyMedium.copyWith(
                  color: CareConnectTheme.textSecondary,
                ),
              ),
              Text(
                'John Doe',
                style: CareConnectTheme.heading3,
              ),
            ],
          ),
        ),
        
        // Notification icon
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
          color: CareConnectTheme.textSecondary,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.health_and_safety,
        'title': 'Check In',
        'color': CareConnectTheme.primaryColor,
      },
      {
        'icon': Icons.medication,
        'title': 'Medications',
        'color': CareConnectTheme.successColor,
      },
      {
        'icon': Icons.message,
        'title': 'Messages',
        'color': CareConnectTheme.warningColor,
      },
      {
        'icon': Icons.schedule,
        'title': 'Schedule',
        'color': CareConnectTheme.primaryColor,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: CareConnectTheme.heading4,
        ),
        const SizedBox(height: 16.0),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.2,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return CareConnectCard(
              onTap: () {},
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (action['color'] as Color).withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      action['icon'] as IconData,
                      color: action['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    action['title'] as String,
                    style: CareConnectTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHealthOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Overview',
          style: CareConnectTheme.heading4,
        ),
        const SizedBox(height: 16.0),
        CareConnectCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildHealthMetric(
                      'Heart Rate',
                      '72',
                      'BPM',
                      Icons.favorite,
                      CareConnectTheme.errorColor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: CareConnectTheme.borderColor,
                  ),
                  Expanded(
                    child: _buildHealthMetric(
                      'Blood Pressure',
                      '120/80',
                      'mmHg',
                      Icons.monitor_heart,
                      CareConnectTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Container(
                width: double.infinity,
                height: 1,
                color: CareConnectTheme.borderColor,
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: _buildHealthMetric(
                      'Weight',
                      '70.5',
                      'kg',
                      Icons.monitor_weight,
                      CareConnectTheme.successColor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: CareConnectTheme.borderColor,
                  ),
                  Expanded(
                    child: _buildHealthMetric(
                      'Temperature',
                      '36.5',
                      '°C',
                      Icons.thermostat,
                      CareConnectTheme.warningColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthMetric(String title, String value, String unit, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 8.0),
        Text(
          title,
          style: CareConnectTheme.bodySmall.copyWith(
            color: CareConnectTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: CareConnectTheme.heading3.copyWith(
                color: color,
              ),
            ),
            const SizedBox(width: 4.0),
            Text(
              unit,
              style: CareConnectTheme.bodySmall.copyWith(
                color: CareConnectTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: CareConnectTheme.heading4,
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        CareConnectCard(
          child: Column(
            children: [
              _buildActivityItem(
                'Medication Reminder',
                'Take your morning medication',
                '2 hours ago',
                Icons.medication,
                CareConnectTheme.primaryColor,
              ),
              const SizedBox(height: 16.0),
              Container(
                width: double.infinity,
                height: 1,
                color: CareConnectTheme.borderColor,
              ),
              const SizedBox(height: 16.0),
              _buildActivityItem(
                'Check-in Complete',
                'Daily health check-in completed',
                '4 hours ago',
                Icons.check_circle,
                CareConnectTheme.successColor,
              ),
              const SizedBox(height: 16.0),
              Container(
                width: double.infinity,
                height: 1,
                color: CareConnectTheme.borderColor,
              ),
              const SizedBox(height: 16.0),
              _buildActivityItem(
                'Message Received',
                'New message from Dr. Smith',
                '6 hours ago',
                Icons.message,
                CareConnectTheme.primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String description, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: CareConnectTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                description,
                style: CareConnectTheme.bodySmall.copyWith(
                  color: CareConnectTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: CareConnectTheme.bodySmall.copyWith(
            color: CareConnectTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', true),
              _buildNavItem(Icons.health_and_safety, 'Health', false),
              _buildNavItem(Icons.message, 'Messages', false),
              _buildNavItem(Icons.person, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? CareConnectTheme.primaryColor : CareConnectTheme.textSecondary,
          size: 24,
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: CareConnectTheme.bodySmall.copyWith(
            color: isActive ? CareConnectTheme.primaryColor : CareConnectTheme.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
