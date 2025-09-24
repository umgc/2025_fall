import 'package:care_connect_app/features/dashboard/presentation/sosscreen.dart';
import 'package:care_connect_app/features/health/medication-tracker/pages/medication-tracker.dart';
import 'package:flutter/material.dart';

/// Widget for the More bottom drawer navigation item
class MoreFeaturesBottomDrawerWidget extends StatelessWidget {
  const MoreFeaturesBottomDrawerWidget({super.key});

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
    ];

    return SizedBox(
      height: 280,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Additional Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: features.length,
                itemBuilder: (context, index) {
                  final feature = features[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Card(
                      child: InkWell(
                        onTap: feature.onTap,
                        child: ListTile(
                          leading: Icon(feature.icon, color: feature.iconColor),
                          title: Text(feature.title),
                          subtitle: Text(feature.subtitle),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Model for each Feature
/// @param icon - The icon of the feature
/// @param iconColor - The color of the icon
/// @param title - The title of the feature
/// @param subtitle - The subtitle of the feature
/// @param onTap - The function to be called when the feature is tapped
/// (typical the navigation to a new screen)
class FeatureItem {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const FeatureItem({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
