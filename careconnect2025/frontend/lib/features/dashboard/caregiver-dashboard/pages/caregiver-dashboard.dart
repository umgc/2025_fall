import 'package:care_connect_app/features/dashboard/caregiver-dashboard/widgets/careteam-performace-card.dart';
import 'package:care_connect_app/features/dashboard/caregiver-dashboard/widgets/recent-patient-activity-widget.dart';
import 'package:care_connect_app/features/dashboard/caregiver-dashboard/widgets/upcoming-checkins-widget.dart';
import 'package:care_connect_app/features/dashboard/patient_dashboard/widgets/recent_checkin_widget.dart';
import 'package:care_connect_app/providers/user_provider.dart';
import 'package:care_connect_app/shared/widgets/dashboard_appheader_widget.dart';
import 'package:care_connect_app/config/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/patient-stat-card.dart';

class CaregiverDashboard extends StatelessWidget {
  const CaregiverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      appBar: DashboardAppHeader(
        userName: user?.name ?? '',
        role: user?.role as String,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Statistics Cards
              const PatientStatisticsCards(),
              const SizedBox(height: 20),

              // Upcoming Check-ins
              const UpcomingCheckins(),
              const SizedBox(height: 20),

              // Recent Patient Activity
              const RecentPatientActivity(),
              const SizedBox(height: 20),

              // Care Team Performance
              const CareTeamPerformance(),
            ],
          ),
        ),
      ),
    );
  }
}
