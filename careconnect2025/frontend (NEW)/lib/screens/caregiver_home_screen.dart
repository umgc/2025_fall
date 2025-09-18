import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme/careconnect_theme.dart';
import '../widgets/notification_icon.dart';
import '../widgets/notification_banner.dart';

class CaregiverHomeScreen extends StatelessWidget {
  const CaregiverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareConnectTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: CareConnectTheme.backgroundColor,
        elevation: 0,
        actions: const [
          NotificationIcon(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CareConnectTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification banner
              const NotificationBanner(),
              
              const SizedBox(height: CareConnectTheme.spacingL),
              
              // Header
              _buildHeader(context),
              
              const SizedBox(height: CareConnectTheme.spacingXL),
              
              // Quick actions
              _buildQuickActions(context),
              
              const SizedBox(height: CareConnectTheme.spacingXL),
              
              // Patient list
              _buildPatientList(context),
              
              const SizedBox(height: CareConnectTheme.spacingXL),
              
              // Today's schedule
              _buildTodaysSchedule(context),
              
              const SizedBox(height: CareConnectTheme.spacingXL),
              
              // Recent activities
              _buildRecentActivities(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer2<AuthProvider, AppStateProvider>(
      builder: (context, authProvider, appState, child) {
        final isDemoMode = appState.isDemoMode;
        final displayName = isDemoMode ? 'Demo Caregiver' : authProvider.getDisplayName();
        
        return Column(
          children: [
            // Demo mode banner
            if (isDemoMode) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(CareConnectTheme.spacingM),
                margin: const EdgeInsets.only(bottom: CareConnectTheme.spacingM),
                decoration: BoxDecoration(
                  color: CareConnectTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CareConnectTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.play_circle_filled,
                      color: CareConnectTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: CareConnectTheme.spacingS),
                    Expanded(
                      child: Text(
                        'Demo Mode Active - Showing sample caregiver data',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: CareConnectTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Main header row
            Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDemoMode ? CareConnectTheme.successColor : CareConnectTheme.primaryColor,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    isDemoMode ? Icons.play_circle_filled : Icons.health_and_safety,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: CareConnectTheme.spacingM),
                
                // Welcome text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDemoMode ? 'Demo Mode -' : 'Welcome back,',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: CareConnectTheme.textSecondary,
                        ),
                      ),
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: CareConnectTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Settings button
                IconButton(
                  onPressed: () {
                    context.read<AppStateProvider>().showSettings();
                  },
                  icon: const Icon(Icons.settings_outlined),
                  style: IconButton.styleFrom(
                    backgroundColor: CareConnectTheme.surfaceColor,
                    foregroundColor: CareConnectTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final appState = context.read<AppStateProvider>();
    
    final actions = [
      {
        'icon': Icons.people_outline,
        'title': 'My Patients',
        'color': CareConnectTheme.primaryColor,
        'onTap': () => appState.setCurrentTab('patientlist'),
      },
      {
        'icon': Icons.schedule_outlined,
        'title': 'Schedule',
        'color': CareConnectTheme.secondaryColor,
        'onTap': () => appState.setCurrentTab('schedule'),
      },
      {
        'icon': Icons.message_outlined,
        'title': 'Messages',
        'color': CareConnectTheme.successColor,
        'onTap': () => appState.setCurrentTab('messages'),
      },
      {
        'icon': Icons.calendar_today_outlined,
        'title': 'Calendar',
        'color': CareConnectTheme.warningColor,
        'onTap': () => appState.setCurrentTab('calendar'),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: CareConnectTheme.primaryColor,
          ),
        ),
        const SizedBox(height: CareConnectTheme.spacingM),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: CareConnectTheme.spacingM,
            mainAxisSpacing: CareConnectTheme.spacingM,
            childAspectRatio: 1.5,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(
              context: context,
              icon: action['icon'] as IconData,
              title: action['title'] as String,
              color: action['color'] as Color,
              onTap: action['onTap'] as VoidCallback,
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(CareConnectTheme.spacingM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: CareConnectTheme.spacingS),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientList(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final isDemoMode = appState.isDemoMode;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDemoMode ? 'Demo Patient List' : 'My Patients',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: CareConnectTheme.primaryColor,
              ),
            ),
            const SizedBox(height: CareConnectTheme.spacingM),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(CareConnectTheme.spacingL),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (isDemoMode) ...[
                    _buildDemoPatientItem('Sarah Johnson', 'Diabetes Management', 'Good'),
                    const Divider(),
                    _buildDemoPatientItem('Michael Chen', 'Physical Therapy', 'Needs Attention'),
                    const Divider(),
                    _buildDemoPatientItem('Emily Davis', 'Medication Review', 'Stable'),
                  ] else ...[
                    const Text(
                      'No patients assigned yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: CareConnectTheme.spacingS),
                    Text(
                      'Contact your supervisor to get assigned to patients',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: CareConnectTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDemoPatientItem(String name, String condition, String status) {
    Color statusColor = CareConnectTheme.successColor;
    if (status == 'Needs Attention') statusColor = CareConnectTheme.warningColor;
    if (status == 'Stable') statusColor = CareConnectTheme.secondaryColor;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CareConnectTheme.spacingS),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.person,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: CareConnectTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  condition,
                  style: TextStyle(
                    fontSize: 14,
                    color: CareConnectTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysSchedule(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final isDemoMode = appState.isDemoMode;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDemoMode ? 'Demo Today\'s Schedule' : 'Today\'s Schedule',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: CareConnectTheme.primaryColor,
              ),
            ),
            const SizedBox(height: CareConnectTheme.spacingM),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(CareConnectTheme.spacingL),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (isDemoMode) ...[
                    _buildScheduleItem('9:00 AM', 'Sarah Johnson', 'Medication Check', CareConnectTheme.primaryColor),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildScheduleItem('11:30 AM', 'Michael Chen', 'Physical Therapy', CareConnectTheme.secondaryColor),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildScheduleItem('2:00 PM', 'Emily Davis', 'Health Assessment', CareConnectTheme.successColor),
                  ] else ...[
                    const Text(
                      'No appointments scheduled for today',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: CareConnectTheme.spacingS),
                    Text(
                      'Check back later for updates',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: CareConnectTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScheduleItem(String time, String patient, String activity, Color color) {
    return Row(
      children: [
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: CareConnectTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: CareConnectTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                activity,
                style: TextStyle(
                  fontSize: 14,
                  color: CareConnectTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final isDemoMode = appState.isDemoMode;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDemoMode ? 'Demo Recent Activities' : 'Recent Activities',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: CareConnectTheme.primaryColor,
              ),
            ),
            const SizedBox(height: CareConnectTheme.spacingM),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(CareConnectTheme.spacingL),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (isDemoMode) ...[
                    _buildActivityItem('Completed medication check for Sarah Johnson', '2 hours ago', Icons.check_circle, CareConnectTheme.successColor),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildActivityItem('Updated care plan for Michael Chen', '4 hours ago', Icons.edit, CareConnectTheme.primaryColor),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildActivityItem('Received message from Emily Davis', '6 hours ago', Icons.message, CareConnectTheme.secondaryColor),
                  ] else ...[
                    const Text(
                      'No recent activities',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: CareConnectTheme.spacingS),
                    Text(
                      'Your activities will appear here',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: CareConnectTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityItem(String description, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: CareConnectTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: CareConnectTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}