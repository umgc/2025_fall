import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme/careconnect_theme.dart';

class PatientListScreen extends StatelessWidget {
  const PatientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareConnectTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Patients'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<AppStateProvider>().setCurrentTab('home');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(CareConnectTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            
            const SizedBox(height: CareConnectTheme.spacingXL),
            
            // Patient List
            _buildPatientList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer2<AuthProvider, AppStateProvider>(
      builder: (context, authProvider, appState, child) {
        final isDemoMode = appState.isDemoMode;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDemoMode ? 'Demo Patient List' : 'My Patients',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: CareConnectTheme.primaryColor,
              ),
            ),
            const SizedBox(height: CareConnectTheme.spacingS),
            Text(
              isDemoMode 
                ? 'Manage your assigned patients and their care plans'
                : 'View and manage your assigned patients',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: CareConnectTheme.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPatientList(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final isDemoMode = appState.isDemoMode;
        
        if (isDemoMode) {
          return Column(
            children: [
              _buildPatientCard(
                context: context,
                name: 'Sarah Johnson',
                age: 68,
                condition: 'Diabetes Management',
                status: 'Good',
                statusColor: CareConnectTheme.successColor,
                lastVisit: '2 days ago',
                nextAppointment: 'Tomorrow, 10:00 AM',
                medications: 3,
                onTap: () => _showPatientDetails(context, 'Sarah Johnson'),
              ),
              const SizedBox(height: CareConnectTheme.spacingM),
              _buildPatientCard(
                context: context,
                name: 'Michael Chen',
                age: 72,
                condition: 'Physical Therapy',
                status: 'Needs Attention',
                statusColor: CareConnectTheme.warningColor,
                lastVisit: '1 day ago',
                nextAppointment: 'Today, 2:00 PM',
                medications: 2,
                onTap: () => _showPatientDetails(context, 'Michael Chen'),
              ),
              const SizedBox(height: CareConnectTheme.spacingM),
              _buildPatientCard(
                context: context,
                name: 'Emily Davis',
                age: 65,
                condition: 'Medication Review',
                status: 'Stable',
                statusColor: CareConnectTheme.secondaryColor,
                lastVisit: '3 days ago',
                nextAppointment: 'Friday, 11:30 AM',
                medications: 4,
                onTap: () => _showPatientDetails(context, 'Emily Davis'),
              ),
            ],
          );
        } else {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(CareConnectTheme.spacingXL),
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
                const Icon(
                  Icons.people_outline,
                  size: 64,
                  color: CareConnectTheme.textSecondary,
                ),
                const SizedBox(height: CareConnectTheme.spacingL),
                Text(
                  'No patients assigned yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: CareConnectTheme.spacingS),
                Text(
                  'Contact your supervisor to get assigned to patients',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: CareConnectTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: CareConnectTheme.spacingL),
                ElevatedButton(
                  onPressed: () {
                    // In a real app, this would contact the supervisor
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contact supervisor feature coming soon'),
                        backgroundColor: CareConnectTheme.primaryColor,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CareConnectTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: CareConnectTheme.spacingL,
                      vertical: CareConnectTheme.spacingM,
                    ),
                  ),
                  child: const Text('Contact Supervisor'),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildPatientCard({
    required BuildContext context,
    required String name,
    required int age,
    required String condition,
    required String status,
    required Color statusColor,
    required String lastVisit,
    required String nextAppointment,
    required int medications,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    Icons.person,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: CareConnectTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$age years old • $condition',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CareConnectTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.schedule,
                    label: 'Last Visit',
                    value: lastVisit,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.calendar_today,
                    label: 'Next Appointment',
                    value: nextAppointment,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.medication,
                    label: 'Medications',
                    value: '$medications',
                  ),
                ),
              ],
            ),
            const SizedBox(height: CareConnectTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPatientDetails(context, name),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CareConnectTheme.primaryColor,
                      side: const BorderSide(color: CareConnectTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: CareConnectTheme.spacingS),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _startVisit(context, name),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Start Visit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CareConnectTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: CareConnectTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: CareConnectTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showPatientDetails(BuildContext context, String patientName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$patientName Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient: $patientName'),
            const SizedBox(height: 8),
            Text('Age: ${patientName == 'Sarah Johnson' ? '68' : patientName == 'Michael Chen' ? '72' : '65'}'),
            const SizedBox(height: 8),
            Text('Condition: ${patientName == 'Sarah Johnson' ? 'Diabetes Management' : patientName == 'Michael Chen' ? 'Physical Therapy' : 'Medication Review'}'),
            const SizedBox(height: 8),
            Text('Status: ${patientName == 'Sarah Johnson' ? 'Good' : patientName == 'Michael Chen' ? 'Needs Attention' : 'Stable'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _startVisit(BuildContext context, String patientName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting visit with $patientName...'),
        backgroundColor: CareConnectTheme.successColor,
      ),
    );
    // In a real app, this would navigate to the visit screen
  }
}
