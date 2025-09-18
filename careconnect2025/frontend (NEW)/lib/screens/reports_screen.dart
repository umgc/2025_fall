import 'package:flutter/material.dart';
import '../config/theme/careconnect_theme.dart';
import '../widgets/careconnect_card.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareConnectTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Health Reports'),
        backgroundColor: CareConnectTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(CareConnectTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Reports',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: CareConnectTheme.primaryColor,
              ),
            ),
            const SizedBox(height: CareConnectTheme.spacingS),
            Text(
              'View your health data and reports.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: CareConnectTheme.textSecondary,
              ),
            ),
            
            const SizedBox(height: CareConnectTheme.spacingXL),
            
            CareConnectCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.assessment,
                    size: 64,
                    color: CareConnectTheme.primaryColor,
                  ),
                  const SizedBox(height: CareConnectTheme.spacingM),
                  Text(
                    'Reports Coming Soon',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: CareConnectTheme.spacingS),
                  Text(
                    'Health reports and analytics will be available in the full version.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: CareConnectTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
