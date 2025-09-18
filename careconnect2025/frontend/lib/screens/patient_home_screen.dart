import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme/careconnect_theme.dart';
import '../widgets/notification_banner.dart';
import '../widgets/notification_icon.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
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
              _buildHeader(),
              
              const SizedBox(height: CareConnectTheme.spacingXL),
              
              // Quick actions
              _buildQuickActions(),
              
              const SizedBox(height: CareConnectTheme.spacingXL),
              
              // Health overview
              _buildHealthOverview(),
              
              const SizedBox(height: CareConnectTheme.spacingXL),
              
              // Recent activity
              _buildRecentActivity(),
              
              const SizedBox(height: CareConnectTheme.spacingXL),
              
              // Upcoming appointments
              _buildUpcomingAppointments(),
              
              const SizedBox(height: CareConnectTheme.spacingXL),
              
              // Additional content for scrolling
              _buildAdditionalContent(),
              
              const SizedBox(height: CareConnectTheme.spacingXL),
              
              // More content to ensure scrolling
              _buildHealthTips(),
              
              const SizedBox(height: CareConnectTheme.spacingXL),
              
              _buildMedicationReminders(),
              
              const SizedBox(height: CareConnectTheme.spacingXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer2<AuthProvider, AppStateProvider>(
      builder: (context, authProvider, appState, child) {
        final isDemoMode = appState.isDemoMode;
        final displayName = isDemoMode ? 'Demo Patient' : authProvider.getDisplayName();
        
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
                        'Demo Mode Active - Showing sample data',
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
                    isDemoMode ? Icons.play_circle_filled : Icons.person,
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

  Widget _buildQuickActions() {
    final appState = context.read<AppStateProvider>();
    
    final actions = [
      {
        'icon': Icons.check_circle_outline,
        'title': 'Check-in',
        'color': CareConnectTheme.successColor,
        'onTap': () => appState.setCurrentTab('checkin'),
      },
      {
        'icon': Icons.health_and_safety_outlined,
        'title': 'Symptoms',
        'color': CareConnectTheme.warningColor,
        'onTap': () => appState.setCurrentTab('symptoms'),
      },
      {
        'icon': Icons.medication_outlined,
        'title': 'Medications',
        'color': CareConnectTheme.primaryColor,
        'onTap': () => appState.setCurrentTab('medications'),
      },
      {
        'icon': Icons.message_outlined,
        'title': 'Messages',
        'color': CareConnectTheme.secondaryColor,
        'onTap': () => appState.setCurrentTab('messages'),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildHealthOverview() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final isDemoMode = appState.isDemoMode;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDemoMode ? 'Demo Health Overview' : 'Health Overview',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
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
                  // Mood indicator
                  Row(
                    children: [
                      Text(
                        isDemoMode ? '🎯' : '😊',
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: CareConnectTheme.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDemoMode ? 'Demo Mode Active' : 'Feeling Good',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            Text(
                              isDemoMode 
                                ? 'Sample data for demonstration'
                                : 'Last check-in: Today, 9:00 AM',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: CareConnectTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: CareConnectTheme.spacingL),
                  
                  // Health metrics
                  Row(
                    children: [
                      Expanded(
                        child: _buildHealthMetric(
                          'Blood Pressure',
                          isDemoMode ? '118/78' : '120/80',
                          'Normal',
                          CareConnectTheme.successColor,
                        ),
                      ),
                      const SizedBox(width: CareConnectTheme.spacingM),
                      Expanded(
                        child: _buildHealthMetric(
                          'Heart Rate',
                          isDemoMode ? '68 bpm' : '72 bpm',
                          'Normal',
                          CareConnectTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHealthMetric(String label, String value, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(CareConnectTheme.spacingM),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: CareConnectTheme.textSecondary,
            ),
          ),
          const SizedBox(height: CareConnectTheme.spacingXS),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CareConnectTheme.primaryColor,
            ),
          ),
          const SizedBox(height: CareConnectTheme.spacingXS),
          Text(
            status,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
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
              _buildActivityItem(
                icon: Icons.medication,
                title: 'Took morning medication',
                time: '9:00 AM',
                color: CareConnectTheme.primaryColor,
              ),
              const Divider(),
              _buildActivityItem(
                icon: Icons.check_circle,
                title: 'Completed daily check-in',
                time: '8:30 AM',
                color: CareConnectTheme.successColor,
              ),
              const Divider(),
              _buildActivityItem(
                icon: Icons.message,
                title: 'Received message from Dr. Smith',
                time: 'Yesterday',
                color: CareConnectTheme.secondaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CareConnectTheme.spacingS),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: CareConnectTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: CareConnectTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Appointments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CareConnectTheme.primaryColor,
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<AppStateProvider>().handleOpenCalendar();
              },
              child: const Text('View All'),
            ),
          ],
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
              _buildAppointmentItem(
                doctor: 'Dr. Sarah Johnson',
                specialty: 'Cardiologist',
                date: 'Tomorrow',
                time: '2:00 PM',
                isUrgent: false,
              ),
              const Divider(),
              _buildAppointmentItem(
                doctor: 'Dr. Michael Chen',
                specialty: 'General Practice',
                date: 'Friday',
                time: '10:30 AM',
                isUrgent: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentItem({
    required String doctor,
    required String specialty,
    required String date,
    required String time,
    required bool isUrgent,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CareConnectTheme.spacingS),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: CareConnectTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.person,
              color: CareConnectTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: CareConnectTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        doctor,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CareConnectTheme.errorColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  specialty,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: CareConnectTheme.textSecondary,
                  ),
                ),
                Text(
                  '$date at $time',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: CareConnectTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalContent() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CareConnectTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: CareConnectTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: CareConnectTheme.spacingM),
              const Text(
                'Additional Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: CareConnectTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: CareConnectTheme.spacingM),
          const Text(
            'This section provides additional content to ensure the screen is scrollable. In a real app, this could contain health tips, medication reminders, or other relevant information.',
            style: TextStyle(
              fontSize: 14,
              color: CareConnectTheme.textPrimary,
            ),
          ),
          const SizedBox(height: CareConnectTheme.spacingM),
          Container(
            padding: const EdgeInsets.all(CareConnectTheme.spacingM),
            decoration: BoxDecoration(
              color: CareConnectTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.health_and_safety,
                  color: CareConnectTheme.primaryColor,
                  size: 16,
                ),
                SizedBox(width: CareConnectTheme.spacingS),
                Expanded(
                  child: Text(
                    'Remember to take your medications as prescribed',
                    style: TextStyle(
                      fontSize: 12,
                      color: CareConnectTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTips() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CareConnectTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: CareConnectTheme.secondaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: CareConnectTheme.spacingM),
              const Text(
                'Health Tips',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: CareConnectTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: CareConnectTheme.spacingM),
          const Text(
            'Stay hydrated by drinking at least 8 glasses of water daily. Regular exercise and a balanced diet are key to maintaining good health.',
            style: TextStyle(
              fontSize: 14,
              color: CareConnectTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationReminders() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CareConnectTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.medication,
                  color: CareConnectTheme.warningColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: CareConnectTheme.spacingM),
              const Text(
                'Medication Reminders',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: CareConnectTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: CareConnectTheme.spacingM),
          const Text(
            'Don\'t forget to take your prescribed medications at the scheduled times. Set reminders to help you stay on track with your treatment plan.',
            style: TextStyle(
              fontSize: 14,
              color: CareConnectTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}