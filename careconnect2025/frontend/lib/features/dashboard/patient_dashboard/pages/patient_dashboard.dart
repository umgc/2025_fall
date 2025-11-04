import 'dart:convert';

import 'package:care_connect_app/config/theme/app_theme.dart';
import 'package:care_connect_app/features/dashboard/patient_dashboard/widgets/alter_notification_widget.dart';
import 'package:care_connect_app/features/dashboard/patient_dashboard/widgets/current_mood_widget.dart';
import 'package:care_connect_app/shared/widgets/dashboard_appheader_widget.dart';
import 'package:care_connect_app/features/dashboard/patient_dashboard/widgets/medication_reminder_widget.dart';
import 'package:care_connect_app/features/dashboard/patient_dashboard/widgets/offline_notification_widget.dart';
import 'package:care_connect_app/features/dashboard/patient_dashboard/widgets/primary_care_provider_widget.dart';
import 'package:care_connect_app/features/dashboard/patient_dashboard/widgets/recent_checkin_widget.dart';
import 'package:care_connect_app/providers/user_provider.dart';
import 'package:care_connect_app/services/api_service.dart';
import 'package:care_connect_app/services/call_notification_service.dart';
import 'package:care_connect_app/services/communication_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/evv_service.dart';
import 'package:http/http.dart' as http;

import '../../../../../utils/call_integration_helper.dart';
import '../../../../../widgets/ai_chat_improved.dart';

class PatientDashboard extends StatefulWidget {
  final int? userId;

  const PatientDashboard({super.key, this.userId});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  // Patient data
  Map<String, dynamic>? patient;
  List<Map<String, dynamic>> caregivers = [];
  List<Map<String, dynamic>> familyMembers = [];

  // Loading states
  bool loading = true;
  bool isLoading = false;
  String? error;

  // Dashboard specific data
  List<CheckIn> recentCheckIns = [];
  MedicationReminder? upcomingReminder;
  Map<String, dynamic>? primaryCareProvider;

  // Mood tracking
  int currentMoodScore = 0;
  String currentMoodLabel = '';
  List<String> moodTags = [];

  // Notifications state
  bool _callNotificationInitialized = false;
  bool _isOffline = false;
  DateTime? _lastSynced;
  List<AlertNotification> activeAlerts = [];

  // Alert dismissal tracking
  Set<String> dismissedAlertIds = {};

  // EVV sections state
  final EvvService _evvService = EvvService();
  List<EvvRecord> _pastEvvVisits = [];
  List<Map<String, dynamic>> _upcomingEvvAppointments = [];
  bool _loadingEvv = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _initializeCallNotifications();
    _checkConnectivity();
    _loadRecentMoodData();
    _loadMedicationReminders();
    _loadPrimaryCareProvider();
    _loadEvvSections();
  }

  /// Check connectivity status
  Future<void> _checkConnectivity() async {
    // Implement actual connectivity checking
    // For now, using mock data
    setState(() {
      _isOffline = false; // Set based on actual connectivity
      _lastSynced = DateTime.now().subtract(const Duration(hours: 2));
    });
  }

  /// Load all dashboard data
  Future<void> _loadDashboardData() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      final int? id = user?.id;

      if (id == null) {
        setState(() {
          error = 'User not logged in.';
          loading = false;
        });
        return;
      }

      // Check for alerts
      _checkForAlerts();

      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error loading dashboard: ${e.toString()}';
        loading = false;
      });
    }
  }

  Future<void> _loadEvvSections() async {
    setState(() => _loadingEvv = true);
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      final patientId = user?.patientId;
      if (patientId == null) {
        setState(() => _loadingEvv = false);
        return;
      }
      final now = DateTime.now();
      // Use name-based filter to avoid backend SQL param typing issue
      String? patientName;
      try {
        final first = patient?['firstName'] ?? '';
        final last = patient?['lastName'] ?? '';
        final combined = ('$first $last').trim();
        patientName = combined.isNotEmpty ? combined : null;
      } catch (_) {}

      final result = await _evvService.searchRecords(EvvSearchRequest(
        patientName: patientName,
        page: 0,
        size: 200,
        sortBy: 'dateOfService',
        sortDirection: 'DESC',
      ));
      _pastEvvVisits = result.content.where((r) => r.patient?.id == patientId).toList();

      // Try caregiver scheduled visits endpoint and filter by patient
      try {
        final headers = await ApiService.getAuthHeaders();
        int? caregiverId;
        if (caregivers.isNotEmpty) {
          caregiverId = (caregivers.first['id'] ?? caregivers.first['caregiverId']) as int?;
        } else {
          final cgRes = await http.get(
            Uri.parse('${ApiConstants.baseUrl}patients/$patientId/caregivers'),
            headers: headers,
          );
          if (cgRes.statusCode == 200) {
            final cgs = List<Map<String, dynamic>>.from(jsonDecode(cgRes.body));
            if (cgs.isNotEmpty) caregiverId = (cgs.first['id'] ?? cgs.first['caregiverId']) as int?;
          }
        }
        if (caregiverId != null) {
          final startStr = DateTime(now.year, now.month, now.day).toIso8601String().split('T')[0];
          final endDate = now.add(const Duration(days: 30));
          final endStr = DateTime(endDate.year, endDate.month, endDate.day).toIso8601String().split('T')[0];
          final url = Uri.parse('${ApiConstants.baseUrl}scheduled-visits/caregiver/$caregiverId/range?startDate=$startStr&endDate=$endStr');
          final res = await http.get(url, headers: headers);
          if (res.statusCode == 200) {
            final List<dynamic> data = jsonDecode(res.body);
            bool matchesPatient(Map<String, dynamic> m) {
              final target = patientId?.toString();
              if (m.containsKey('patientId') && '${m['patientId']}' == target) return true;
              if (m.containsKey('patient_id') && '${m['patient_id']}' == target) return true;
              final p = m['patient'];
              if (p is Map && ('${p['id']}' == target)) return true;
              return false;
            }
            DateTime? parseWhen(Map<String, dynamic> m) {
              // Case 1: combined timestamp string
              final v = m['scheduledTime'] ?? m['scheduled_time'] ?? m['time'];
              if (v is String) {
                // If this looks like HH:mm[:ss], combine with scheduledDate
                if (RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$').hasMatch(v)) {
                  final d = (m['scheduledDate'] ?? m['scheduled_date']) as String?;
                  if (d != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(d)) {
                    return DateTime.tryParse('$d $v');
                  }
                }
                final dt = DateTime.tryParse(v);
                if (dt != null) return dt;
              }
              if (v is int) {
                try { return DateTime.fromMillisecondsSinceEpoch(v); } catch (_) {}
              }
              // Case 2: separate date/time fields
              final dateStr = (m['scheduledDate'] ?? m['scheduled_date']) as String?;
              final timeStr = (m['scheduledTime'] ?? m['scheduled_time']) as String?;
              if (dateStr != null && timeStr != null) {
                final date = DateTime.tryParse(dateStr);
                if (date != null) {
                  final tp = timeStr.split(':');
                  if (tp.length >= 2) {
                    final h = int.tryParse(tp[0]) ?? 0;
                    final min = int.tryParse(tp[1]) ?? 0;
                    return DateTime(date.year, date.month, date.day, h, min);
                  }
                }
              }
              return null;
            }

            final Set<dynamic> seenIds = {};
            final List<Map<String, dynamic>> normalized = [];
            for (final raw in data.cast<Map<String, dynamic>>()) {
              if (!matchesPatient(raw)) continue;
              final when = parseWhen(raw);
              if (when == null) continue;
              if (when.isBefore(DateTime.now())) continue; // only upcoming
              final id = raw['id'] ?? raw['visitId'] ?? raw['scheduledVisitId'];
              if (id != null && seenIds.contains(id)) continue;
              if (id != null) seenIds.add(id);
              final service = raw['serviceType'] ?? raw['service_type'] ?? raw['service'] ?? 'Service';
              normalized.add({'id': id, 'serviceType': service, 'scheduledTime': when.toIso8601String()});
            }
            normalized.sort((a,b)=> DateTime.parse(a['scheduledTime']).compareTo(DateTime.parse(b['scheduledTime'])));
            _upcomingEvvAppointments = normalized;
          }
        }
      } catch (_) {
        _upcomingEvvAppointments = [];
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingEvv = false);
    }
  }

  /// Load recent mood data
  Future<void> _loadRecentMoodData() async {
    try {
      // This would be an API call to get mood data
      // For now, using sample data
      setState(() {
        currentMoodScore = 8;
        currentMoodLabel = 'Good';
        moodTags = ['happy', 'calm', 'comfortable', 'positive'];

        recentCheckIns = [
          CheckIn(
            date: DateTime.now(),
            status: 'Feeling well today',
            emoji: '😊',
          ),
          CheckIn(
            date: DateTime.now().subtract(const Duration(days: 1)),
            status: 'Slight headache',
            emoji: '🙂',
          ),
          CheckIn(
            date: DateTime.now().subtract(const Duration(days: 2)),
            status: 'Medications taken',
            emoji: '😐',
          ),
        ];
      });
    } catch (e) {
      print('Error loading mood data: $e');
    }
  }

  /// Load medication reminders
  Future<void> _loadMedicationReminders() async {
    try {
      // This would be an API call to get medication reminders
      // For now, using sample data
      setState(() {
        upcomingReminder = MedicationReminder(
          medicationName: 'Blood Pressure Medication',
          scheduledTime: DateTime.now().add(const Duration(days: 1, hours: 9)),
          status: 'Scheduled reminder',
        );
      });
    } catch (e) {
      print('Error loading medication reminders: $e');
    }
  }

  /// Load primary care provider
  Future<void> _loadPrimaryCareProvider() async {
    try {
      // This would be an API call to get provider data
      // For now, using sample data
      setState(() {
        primaryCareProvider = {
          'name': 'Dr. Sarah Mitchell, MD',
          'specialty': 'Internal Medicine',
          'organization': 'CareConnect Medical Group',
          'phone': '(555) 123-4567',
          'email': 'sarah.mitchell@careconnect.com',
          'nextAppointment': DateTime.now().add(const Duration(days: 30)),
          'appointmentType': 'Annual Checkup',
        };
      });
    } catch (e) {
      print('Error loading primary care provider: $e');
    }
  }

  /// Check for alerts based on current data
  void _checkForAlerts() {
    activeAlerts.clear();

    // Check mood score
    if (currentMoodScore < 5) {
      activeAlerts.add(
        AlertNotification(
          type: AlertType.important,
          message: 'Mood score below normal range. Consider contacting your healthcare provider.',
        ),
      );
    }

    // Check for missed medications
    // This would check actual medication data
    if (DateTime.now().hour > 10) {
      activeAlerts.add(
        AlertNotification(
          type: AlertType.reminder,
          message: 'You have a missed medication dose. Please take it as soon as possible.',
        ),
      );
    }
  }

  /// Load family members
  Future<void> _loadFamilyMembers() async {
    if (!isLoading) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      final userId = widget.userId ?? user?.id ?? 1;

      final response = await ApiService.getFamilyMembers(userId);

      if (mounted) {
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          setState(() {
            familyMembers = List<Map<String, dynamic>>.from(data);
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading family members: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// Initialize call notifications
  Future<void> _initializeCallNotifications() async {
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      final id = user?.id;

      if (id == null) {
        print('❌ Cannot initialize call notifications - no patient ID');
        return;
      }

      print('🔔 Initializing call notification service for patient: $id');

      await CallNotificationService.initialize(
        userId: id.toString(),
        userRole: 'PATIENT',
        context: context,
      );

      _callNotificationInitialized = true;
      setState(() {});
      print('✅ Patient call notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing patient call notification service: $e');
      _callNotificationInitialized = false;
    }
  }

  /// Handle medication action
  void _handleMedicationAction(bool taken) {
    if (taken) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication marked as taken'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Medication marked as missed'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Would call API to update medication status
    _loadMedicationReminders();
  }

  /// Handle contacting provider
  void _handleContactProvider() {
    // Show contact options
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Contact Provider',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Call'),
              subtitle: Text(primaryCareProvider?['phone'] ?? ''),
              onTap: () {
                Navigator.pop(context);
                final phone = primaryCareProvider?['phone'];
                if (phone != null) {
                  CommunicationService.makePhoneCall(phone, context);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(primaryCareProvider?['email'] ?? ''),
              onTap: () async {
                Navigator.pop(context);
                final email = primaryCareProvider?['email'];
                if (email != null) {
                  final uri = Uri(
                    scheme: 'mailto',
                    path: email,
                    queryParameters: {
                      'subject': 'Patient Inquiry',
                      'body':
                          'Hello Dr. ${primaryCareProvider?['name']?.split(' ')[1]},\n\n',
                    },
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_call),
              title: const Text('Video Call'),
              subtitle: const Text('Schedule a video consultation'),
              onTap: () {
                Navigator.pop(context);
                context.push('/schedule-appointment');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    CallNotificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: DashboardAppHeader(
        userName: user?.name ?? '',
        role: user?.role as String,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(
          Icons.chat_bubble_outline,
          color: theme.colorScheme.onPrimary,
        ),
        onPressed: () {
          final double sheetHeight = MediaQuery.of(context).size.height * 0.75;
          showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            constraints: BoxConstraints(
              maxWidth: isTablet ? 600 : double.infinity,
            ),
            builder: (context) => SizedBox(
              height: sheetHeight,
              child: AIChat(
                role: 'patient', 
                isModal: true,
                patientId: user?.patientId, // Pass the actual patient ID
                userId: user?.id,
              ),
            ),
          );
        },
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Dashboard',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: _loadDashboardData,
                  ),
                ],
              ),
            )
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Responsive layout for tablets
                      if (isTablet) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column
                              Expanded(
                                child: Column(
                                  children: [
                                    // Offline notification
                                    if (_isOffline)
                                      OfflineNotification(
                                        lastSynced: _lastSynced,
                                      ),

                                    // Alert notifications
                                    ...activeAlerts
                                        .where(
                                          (alert) =>
                                              !dismissedAlertIds.contains(
                                                alert.hashCode.toString(),
                                              ),
                                        )
                                        .map(
                                          (alert) => AlertNotification(
                                            type: alert.type,
                                            message: alert.message,
                                            onDismiss: () {
                                              setState(() {
                                                dismissedAlertIds.add(
                                                  alert.hashCode.toString(),
                                                );
                                              });
                                            },
                                          ),
                                        ),

                                    // Current Mood
                                    CurrentMoodWidget(
                                      moodScore: currentMoodScore,
                                      moodLabel: currentMoodLabel,
                                      moodTags: moodTags,
                                      date: DateTime.now(),
                                    ),

                                    // Recent Check-ins
                                    if (recentCheckIns.isNotEmpty)
                                      RecentCheckInsWidget(
                                        checkIns: recentCheckIns,
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Right Column
                              Expanded(
                                child: Column(
                                  children: [
                                    // Medication Reminders
                                    if (upcomingReminder != null)
                                      MedicationRemindersWidget(
                                        reminder: upcomingReminder!,
                                        onMarkTaken: () =>
                                            _handleMedicationAction(true),
                                        onMarkMissed: () =>
                                            _handleMedicationAction(false),
                                      ),

                                    // Upcoming EVV & Past EVV
                                    const SizedBox(height: 12),
                                    _buildUpcomingEvvSection(theme),
                                    const SizedBox(height: 12),
                                    _buildPastEvvSection(theme),

                                    // Primary Care Provider
                                    if (primaryCareProvider != null)
                                      PrimaryCareProviderWidget(
                                        providerName:
                                            primaryCareProvider!['name'],
                                        specialty:
                                            primaryCareProvider!['specialty'],
                                        organization:
                                            primaryCareProvider!['organization'],
                                        phone: primaryCareProvider!['phone'],
                                        email: primaryCareProvider!['email'],
                                        nextAppointment:
                                            primaryCareProvider!['nextAppointment'],
                                        appointmentType:
                                            primaryCareProvider!['appointmentType'],
                                        onContactProvider:
                                            _handleContactProvider,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Mobile layout (single column)
                        // Offline notification
                        if (_isOffline)
                          OfflineNotification(lastSynced: _lastSynced),

                        // Alert notifications
                        ...activeAlerts
                            .where(
                              (alert) => !dismissedAlertIds.contains(
                                alert.hashCode.toString(),
                              ),
                            )
                            .map(
                              (alert) => AlertNotification(
                                type: alert.type,
                                message: alert.message,
                                onDismiss: () {
                                  setState(() {
                                    dismissedAlertIds.add(
                                      alert.hashCode.toString(),
                                    );
                                  });
                                },
                              ),
                            ),

                        // Current Mood Widget
                        CurrentMoodWidget(
                          moodScore: currentMoodScore,
                          moodLabel: currentMoodLabel,
                          moodTags: moodTags,
                          date: DateTime.now(),
                        ),

                        // Recent Check-Ins
                        if (recentCheckIns.isNotEmpty)
                          RecentCheckInsWidget(checkIns: recentCheckIns),

                        // Medication Reminders
                        if (upcomingReminder != null)
                          MedicationRemindersWidget(
                            reminder: upcomingReminder!,
                            onMarkTaken: () => _handleMedicationAction(true),
                            onMarkMissed: () => _handleMedicationAction(false),
                          ),

                        const SizedBox(height: 12),
                        _buildUpcomingEvvSection(theme),
                        const SizedBox(height: 12),
                        _buildPastEvvSection(theme),

                        // Primary Care Provider
                        if (primaryCareProvider != null)
                          PrimaryCareProviderWidget(
                            providerName: primaryCareProvider!['name'],
                            specialty: primaryCareProvider!['specialty'],
                            organization: primaryCareProvider!['organization'],
                            phone: primaryCareProvider!['phone'],
                            email: primaryCareProvider!['email'],
                            nextAppointment:
                                primaryCareProvider!['nextAppointment'],
                            appointmentType:
                                primaryCareProvider!['appointmentType'],
                            onContactProvider: _handleContactProvider,
                          ),
                      ],

                      // Emergency Actions
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            // SOS Emergency Button
                            ElevatedButton.icon(
                              icon: const Icon(Icons.sos),
                              label: const Text('SOS Emergency'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                                foregroundColor: theme.colorScheme.onError,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                CallIntegrationHelper.showSOSDialog(
                                  context: context,
                                  currentPatient: patient,
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            // Send SMS Notification Button
                            OutlinedButton.icon(
                              icon: const Icon(Icons.sms),
                              label: const Text('Send SMS to Caregiver'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                                side: BorderSide(
                                  color: theme.colorScheme.primary,
                                ),
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                final caregiver = caregivers.firstWhere(
                                  (c) =>
                                      c['phone'] != null &&
                                      c['phone'].toString().isNotEmpty,
                                  orElse: () => {},
                                );

                                if (caregiver.isNotEmpty && user != null) {
                                  _showSendMessageDialog(
                                    context,
                                    caregiver,
                                    user,
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'No caregiver with phone number found.',
                                      ),
                                      backgroundColor: theme.colorScheme.error,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100), // Bottom padding for FAB
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final primaryColorLight = theme.primaryColorLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: primaryColorLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SMS Dialog
  void _showSendMessageDialog(
    BuildContext context,
    Map<String, dynamic> caregiver,
    dynamic currentUser,
  ) {
    final TextEditingController messageController = TextEditingController();
    final String name = '${caregiver['firstName']} ${caregiver['lastName']}';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Send message to $name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Write your message here...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                CallIntegrationHelper.sendSMSToCaregiver(
                  currentUser: currentUser,
                  targetCaregiver: caregiver,
                  message: messageController.text,
                );
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('SMS sent to $name')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingEvvSection(ThemeData theme) {
    if (_loadingEvv) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Upcoming EVV Appointments', style: theme.textTheme.titleMedium),
              const Spacer(),
              IconButton(onPressed: _loadEvvSections, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 8),
          if (_upcomingEvvAppointments.isEmpty)
            const Text('No upcoming appointments.')
          else
            ..._upcomingEvvAppointments.take(5).map((v) {
              final when = DateTime.tryParse(v['scheduledTime'] ?? '') ?? DateTime.now();
              final service = v['serviceType'] ?? 'Service';
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(service, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${when.month}/${when.day}/${when.year} • ${when.hour.toString().padLeft(2,'0')}:${when.minute.toString().padLeft(2,'0')}'),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPastEvvSection(ThemeData theme) {
    if (_loadingEvv) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              Text('Past EVV Visits', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          if (_pastEvvVisits.isEmpty)
            const Text('No past visits found.')
          else
            ..._pastEvvVisits.take(10).map((r) {
              final date = r.dateOfService;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.check, color: Colors.white, size: 18),
                ),
                title: Text(r.serviceType, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${date.month}/${date.day}/${date.year}'),
              );
            }),
        ],
      ),
    );
  }
}
