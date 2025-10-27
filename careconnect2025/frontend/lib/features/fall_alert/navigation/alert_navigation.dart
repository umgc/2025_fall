import 'package:flutter/material.dart';
import '../models/fall_alert.dart';
import '../pages/alert_details_page.dart';

class AlertNavigation {
  static void navigateFromPayload(BuildContext context, Map<String, String> payload) {
    final alert = FallAlert.fromPayload(payload);
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: AlertDetailsPage.routeName),
      builder: (_) => AlertDetailsPage(alert: alert),
    ));
  }
}
