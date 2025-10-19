import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';

class SmartDevicesPage extends StatefulWidget {
  const SmartDevicesPage({super.key});

  @override
  State<SmartDevicesPage> createState() => _SmartDevicesPageState();
}

class _SmartDevicesPageState extends State<SmartDevicesPage> {
  bool? isAlexaLinked;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _checkAlexaStatus();
  }

  /// ✅ Calls backend to check if Alexa is linked for this patient
  Future<void> _checkAlexaStatus() async {
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user == null || user.patientId == null) {
        setState(() {
          error = "User not logged in or missing patient ID.";
          isLoading = false;
        });
        return;
      }

      final response = await ApiService.getAlexaStatus(user.patientId!);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          isAlexaLinked = data['isAlexaLinked'] ?? false;
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Failed to fetch Alexa status (${response.statusCode}).";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Error checking Alexa status: $e";
        isLoading = false;
      });
    }
  }

  /// ✅ Mock linking function (could open your login.html page)
  Future<void> _linkAlexaAccount() async {
    // For now, you could just open your linking flow
    // e.g., launch your Alexa linking web page
    print("Opening Alexa linking flow...");
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Smart Devices")),
        body: Center(child: Text(error!, style: const TextStyle(color: Colors.red))),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Smart Devices")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAlexaLinked == true ? Icons.link : Icons.link_off,
              color: isAlexaLinked == true ? Colors.green : Colors.grey,
              size: 100,
            ),
            const SizedBox(height: 20),
            Text(
              isAlexaLinked == true
                  ? "Your Alexa account is linked!"
                  : "Alexa is not linked yet.",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            if (isAlexaLinked != true)
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_outlined),
                label: const Text("Link Alexa Account"),
                onPressed: _linkAlexaAccount,
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Check Status Again"),
                onPressed: _checkAlexaStatus,
              ),
          ],
        ),
      ),
    );
  }
}
