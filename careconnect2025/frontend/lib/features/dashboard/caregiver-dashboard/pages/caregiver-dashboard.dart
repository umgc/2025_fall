import 'package:care_connect_app/features/dashboard/caregiver-dashboard/widgets/careteam-performace-card.dart';
import 'package:care_connect_app/features/dashboard/caregiver-dashboard/widgets/recent-patient-activity-widget.dart';
import 'package:care_connect_app/features/dashboard/caregiver-dashboard/widgets/upcoming-checkins-widget.dart';
import 'package:care_connect_app/features/dashboard/patient_dashboard/widgets/recent_checkin_widget.dart';
import 'package:care_connect_app/features/invoices/models/invoice_models.dart';
import 'package:care_connect_app/features/invoices/services/invoice_service.dart';
import 'package:care_connect_app/features/invoices/widgets/invoice_overview_card.dart';
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
        // TODO - the conditional needs to be removed. There is a bug in the
        //        backend where patient and caregiver data is not fetched.
        userName: user?.name ?? '',
        role: user?.role as String,
      ),
      backgroundColor: AppTheme.backgroundSecondary,
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
              // Invoice overview
              const SizedBox(height: 20),
              InvoiceOverviewCard(
                getUnpaidCount: () => _fetchUnpaidInvoiceCount(context),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<int> _fetchUnpaidInvoiceCount(BuildContext context) async {
    final unpaidStatuses = <PaymentStatus>{
      PaymentStatus.pending,
      PaymentStatus.overdue,
      PaymentStatus.pendingInsurance,
      PaymentStatus.sent,
      PaymentStatus.partialPayment,
      PaymentStatus.rejectedInsurance,
    };

    final invoices = await InvoiceService.instance.fetchInvoices(
      status: unpaidStatuses,
      pageSize: 200, // adjust if needed
    );

    return invoices.length;
  }
}
