import 'package:care_connect_app/features/dashboard/presentation/sosscreen.dart';
import 'package:care_connect_app/features/health/medication-tracker/pages/medication-tracker.dart';
import 'package:care_connect_app/pages/notetaker_configuration_page.dart';
import 'package:care_connect_app/shared/widgets/more_features_bottom_drawer.dart';
import 'package:flutter/material.dart';

/// Widget for the More bottom drawer navigation item
class PatientMoreFeaturesBottomDrawerWidget extends StatelessWidget {
  const PatientMoreFeaturesBottomDrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final List<FeatureItem> features = [
      FeatureItem(
        icon: Icons.sos,
        iconColor: Colors.red,
        title: 'SOS',
        subtitle: 'Informing Caregiver of emergency',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SosScreen()),
          );
        },
      ),
      FeatureItem(
        icon: Icons.medication,
        iconColor: Colors.blue,
        title: 'Medication Tracker',
        subtitle: 'Track your medications and schedules',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MedicationsTrackerPage(),
            ),
          );
        },
      ),
      FeatureItem(
        icon: Icons.note,
        iconColor: Colors.blue,
        title: 'Notetake Configuration',
        subtitle: 'Manage your Medical Notetaker Assistant Settings',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotetakerConfigurationPage(),
            ),
          );
        },
      ),
    ];

    return MoreFeaturesBottomDrawer(features: features);
  }
}
