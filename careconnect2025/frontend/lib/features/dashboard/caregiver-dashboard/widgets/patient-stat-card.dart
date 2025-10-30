import 'package:flutter/material.dart';
import 'package:care_connect_app/features/dashboard/patient_dashboard/widgets/recent_checkin_widget.dart';
import 'package:care_connect_app/services/checkin_service.dart';
import 'package:provider/provider.dart';
import 'package:care_connect_app/providers/user_provider.dart';

/// Widget that displays patient statistics in responsive card layout.
///
/// This widget shows key metrics for caregivers including missed check-ins
/// and active patients count. The layout adapts to screen size, displaying
/// cards in a column on small screens and in a row on larger screens.
class PatientStatisticsCards extends StatelessWidget {
  /// Creates a PatientStatisticsCards widget.
  const PatientStatisticsCards({super.key});

  /// Builds the responsive statistics card layout.
  ///
  /// Uses LayoutBuilder to determine screen size and adjusts the layout
  /// accordingly. On screens smaller than 600px, cards are arranged vertically.
  /// On larger screens, cards are arranged horizontally.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        if (isSmallScreen) {
          return Column(
            children: [
              _StatCard(
                icon: Icons.people_outline,
                iconColor: Colors.blue,
                title: '# of Missed Check-Ins',
                value: FutureBuilder<int>(
                  future: _fetchCheckinCount(context),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('...', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold));
                    }
                    if (snapshot.hasError) {
                      return const Text('0', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold));
                    }
                    final n = snapshot.data ?? 0;
                    return Text(
                      n.toString(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    );
                  },
                ),
                valueColor: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              _StatCard(
                icon: Icons.monitor_heart_outlined,
                iconColor: Colors.green,
                title: 'Active Patients',
                value: FutureBuilder<int>(
                  future: _fetchActivePatients(context),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('...', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold));
                    }
                    if (snapshot.hasError) {
                      return const Text('0', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold));
                    }
                    final n = snapshot.data ?? 0;
                    return Text(
                      n.toString(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    );
                  },
                ),
                valueColor: Colors.green,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.people_outline,
                iconColor: Colors.blue,
                title: '# of Missed\nCheck-Ins',
                value: FutureBuilder<int>(
                  future: _fetchCheckinCount(context),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('...', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold));
                    }
                    if (snapshot.hasError) {
                      return const Text('0', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold));
                    }
                    final n = snapshot.data ?? 0;
                    return Text(
                      n.toString(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    );
                  },
                ),
                valueColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                icon: Icons.monitor_heart_outlined,
                iconColor: Colors.green,
                title: 'Active\nPatients',
                value: FutureBuilder<int>(
                  future: _fetchActivePatients(context),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('...', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold));
                    }
                    if (snapshot.hasError) {
                      return const Text('0', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold));
                    }
                    final n = snapshot.data ?? 0;
                    return Text(
                      n.toString(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    );
                  },
                ),
                valueColor: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Fetches the count of missed check-ins for the current caregiver.
  Future<int> _fetchCheckinCount(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final caregiverId = userProvider.user?.id.toString() ?? '';
    return await CheckinService.getCheckinCount(caregiverId);
  }

  /// Fetches the count of active patients linked to this caregiver.
  Future<int> _fetchActivePatients(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final caregiverId = userProvider.user?.id.toString() ?? '';

    // Placeholder: using check-in count until /patients/active endpoint exists.
    return await CheckinService.getCheckinCount(caregiverId);
  }
}

/// Private widget that displays an individual statistic card.
class _StatCard extends StatelessWidget {
  /// The icon to display at the top of the card
  final IconData icon;

  /// The color for the icon and its background
  final Color iconColor;

  /// The title text displayed below the icon
  final String title;

  /// The statistical value to be prominently displayed
  final Widget value;

  /// The color for the value and title text
  final Color valueColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: valueColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: value,
          ),
        ],
      ),
    );
  }
}
