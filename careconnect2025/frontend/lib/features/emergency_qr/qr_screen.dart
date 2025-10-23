import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class _Contact {
  final String name;
  final String role;
  final String phone;
  final bool isPrimary;

  const _Contact({
    required this.name,
    required this.role,
    required this.phone,
    this.isPrimary = false,
  });
}

class EmergencyInfo {
  final String firstName;
  final String lastName;
  final String bloodType;
  final DateTime dob;
  final int age;
  final String gender;
  final String id;
  final List<String> allergiesCritical;
  final List<_Contact> contacts;
  final String secureToken;

  const EmergencyInfo({
    required this.firstName,
    required this.lastName,
    required this.bloodType,
    required this.dob,
    required this.age,
    required this.gender,
    required this.id,
    required this.allergiesCritical,
    required this.contacts,
    required this.secureToken,
  });

  String qrPayload() {
    final primaryContact = contacts.firstWhere(
      (c) => c.isPrimary,
      orElse: () => contacts.isNotEmpty ? contacts.first : const _Contact(name: 'None', role: '', phone: ''),
    );

    return '''
VIAL OF LIFE - EMERGENCY INFO

Name: $firstName $lastName | $bloodType
DOB: ${dob.toIso8601String().substring(0, 10)} (Age: $age) | Gender: $gender
ID: $id

Critical Allergies: ${allergiesCritical.join(", ")}

Primary Contact: ${primaryContact.name} ${primaryContact.phone}

Full Details: http://localhost:8080/v1/api/emergency/$id.pdf

Scan offline for basic info • Tap link when online for full details
''';
  }
}

class QrScreen extends StatelessWidget {
  final String payload;
  final String? emergencyId;
  final int? patientId;
  const QrScreen({required this.payload, this.emergencyId, this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VIAL OF LIFE'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: 260,
                  gapless: false,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 6),
              const SizedBox(height: 12),

              // Action buttons
              if (emergencyId != null)
                Column(
                  children: [
                    // View PDF Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _viewPdf(context),
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('View Vial of Life PDF'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Row with Download and Share buttons
                    Row(
                      children: [
                        // Download PDF Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _downloadPdf(context),
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('Download Vial of Life PDF'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Share Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _shareEmergencyInfo(context),
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Share Vial of Life Info'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Get the PDF URL for viewing (inline)
  String _getPdfUrl() {
    // Replace with your actual backend domain
    const String baseUrl = 'http://localhost:8080'; // Update this with your domain
    return '$baseUrl/v1/api/emergency/$emergencyId.pdf';
  }

  // Get the PDF URL for downloading (attachment)
  String _getDownloadPdfUrl() {
    // Replace with your actual backend domain
    const String baseUrl = 'http://localhost:8080'; // Update this with your domain
    return '$baseUrl/v1/api/emergency/download/$emergencyId.pdf';
  }

  // View PDF in browser or in-app
  void _viewPdf(BuildContext context) async {
    if (emergencyId == null) return;

    final url = _getPdfUrl();

    try {
      if (kIsWeb) {
        // For web: Open PDF in new tab
        html.window.open(url, '_blank');
      } else {
        // For mobile: Use url_launcher with external browser
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot open PDF viewer'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error viewing PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Download PDF to device
  void _downloadPdf(BuildContext context) async {
    if (emergencyId == null) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Downloading PDF...'),
            ],
          ),
        ),
      );

      // Download the PDF using the download endpoint
      final url = _getDownloadPdfUrl();
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        if (kIsWeb) {
          // For web: Trigger browser download
          final blob = html.Blob([response.bodyBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', 'vial-of-life-$emergencyId.pdf')
            ..click();
          html.Url.revokeObjectUrl(url);

          // Close loading dialog
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PDF download started'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          // For mobile: Save to documents directory
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/emergency_$emergencyId.pdf');
          await file.writeAsBytes(response.bodyBytes);

          // Close loading dialog
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF downloaded to: ${file.path}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to download PDF'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Share emergency information
  void _shareEmergencyInfo(BuildContext context) async {
    try {
      String shareText = payload;

      if (emergencyId != null) {
        shareText += '\n\nEmergency PDF: ${_getPdfUrl()}';
      }

      await Share.share(
        shareText,
        subject: 'Emergency Medical Information - $emergencyId',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}