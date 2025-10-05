import 'package:care_connect_app/pages/notetaker_configuration_page.dart';
import 'package:care_connect_app/shared/widgets/more_features_bottom_drawer.dart';
import 'package:flutter/material.dart';

/// Widget for the More bottom drawer navigation item
class CaregiverMoreFeaturesBottomDrawerWidget extends StatelessWidget {
  const CaregiverMoreFeaturesBottomDrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final List<FeatureItem> features = [
      FeatureItem(
        icon: Icons.note,
        iconColor: Colors.blue,
        title: 'Notetake Configuration',
        subtitle: 'Manage your Medical Notetaker Assistant Settings',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotetakerConfigurationPage()),
          );
        },
      )
    ];

    return MoreFeaturesBottomDrawer(features: features);
  }
}
