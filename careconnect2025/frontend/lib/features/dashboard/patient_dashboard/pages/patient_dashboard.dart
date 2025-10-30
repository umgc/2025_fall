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
import 'package:care_connect_app/services/checkin_service.dart';
import 'package:care_connect_app/services/call_notification_service.dart';
import 'package:care_connect_app/services/communication_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _initializeCallNotifications();
    _checkConnectivity();
    _loadRecentMoodData();
    _loadMedicationReminders();
    _loadPrimaryCareProvider();
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

  /// Load recent mood data
  Future<void> _loadRecentMoodData() async {
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user == null) return;

      // Fetch mood data dynamically from backend
      final response = await ApiService.getMoodData(user.id);

      if (response != null) {
        setState(() {
          final scoreValue = response['score'];
          currentMoodScore = (scoreValue is int) ? scoreValue : 0;

          final labelValue = response['label'];
          currentMoodLabel = (labelValue is String && labelValue.isNotEmpty)
              ? labelValue
              : _getMoodLabel(currentMoodScore);

          final tagsValue = response['tags'];
          moodTags = (tagsValue is List)
              ? List<String>.from(tagsValue.whereType<String>())
              : [];

          final checkinsValue = response['checkins'];
          recentCheckIns = (checkinsValue is List)
              ? checkinsValue
                  .whereType<Map<String, dynamic>>()
                  .map((c) => CheckIn.fromJson(c))
                  .toList()
              : [];
        });

      }
    } catch (e) {
      print('Error loading mood data: $e');
    }
  }


  /// Load medication reminders (dynamic)
    Future<void> _loadMedicationReminders() async {
      try {
        final user = Provider.of<UserProvider>(context, listen: false).user;
        final reminders = await ApiService.getTodaysMedications(user?.id ?? 0);

        if (reminders.isNotEmpty) {
          setState(() {
            final first = reminders.first;
            upcomingReminder = MedicationReminder(
              medicationName: first['medicationName'],
              scheduledTime: DateTime.parse(first['scheduledTime']),
              status: first['taken'] ? 'Taken' : 'Scheduled',
            );
          });
        } else {
          setState(() {
            upcomingReminder = null;
          });
        }
      } catch (e) {
        print('❌ Error loading medication reminders: $e');
      }
    }


  /// Load primary care provider dynamically
  Future<void> _loadPrimaryCareProvider() async {
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      final data = await ApiService.getPrimaryCareProvider(user?.id ?? 0);

      if (data.isNotEmpty) {
        setState(() {
          primaryCareProvider = data;
        });
      } else {
        setState(() {
          primaryCareProvider = {};
        });
      }
    } catch (e) {
      print('❌ Error loading primary care provider: $e');
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


  String _getMoodLabel(int score) {
    if (score >= 8) return 'Excellent';
    if (score >= 6) return 'Good';
    if (score >= 4) return 'Neutral';
    if (score >= 2) return 'Low';
    return 'Depressed';
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

                                    // Current Mood (interactive)
                                    CurrentMoodWidget(
                                      moodScore: currentMoodScore,
                                      moodLabel: currentMoodLabel,
                                      moodTags: moodTags,
                                      date: DateTime.now(),
                                    ),

                                    
                                    


                                    // Recent Check-ins
                                    if (recentCheckIns.isNotEmpty)
                                      // Recent Check-ins (auto-average + dynamic)
                                      FutureBuilder<Map<String, dynamic>?>(
                                        future: ApiService.getDailyMoodAverage(user?.id ?? 0),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return const Center(child: CircularProgressIndicator());
                                          }

                                          final data = snapshot.data!;
                                          final avgMood = data['average'] ?? 0;
                                          final todayCheckIns = (data['checkins'] as List<dynamic>?)
                                                  ?.map((c) => CheckIn.fromJson(c))
                                                  .toList() ??
                                              [];

                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                child: Text(
                                                  'Today’s Average Mood: ${avgMood.toStringAsFixed(1)}/10',
                                                  style: theme.textTheme.titleMedium,
                                                ),
                                              ),
                                              RecentCheckInsWidget(checkIns: todayCheckIns),
                                            ],
                                          );
                                        },
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
                                          onMarkTaken: () => _handleMedicationAction(true),
                                          onMarkMissed: () => _handleMedicationAction(false),
                                        )
                                      else
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          child: Text(
                                            'No medication reminders for today.',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontSize: 24,
                                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
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
                          // Recent Check-ins (auto-average + dynamic)
                          FutureBuilder<Map<String, dynamic>?>(
                            future: ApiService.getDailyMoodAverage(user?.id ?? 0),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              final data = snapshot.data!;
                              final avgMood = data['average'] ?? 0;
                              final todayCheckIns = (data['checkins'] as List<dynamic>?)
                                      ?.map((c) => CheckIn.fromJson(c))
                                      .toList() ??
                                  [];

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Text(
                                      'Today’s Average Mood: ${avgMood.toStringAsFixed(1)}/10',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ),
                                  RecentCheckInsWidget(checkIns: todayCheckIns),
                                ],
                              );
                            },
                          ),


                        // Medication Reminders
                        if (upcomingReminder != null)
                          MedicationRemindersWidget(
                            reminder: upcomingReminder!,
                            onMarkTaken: () => _handleMedicationAction(true),
                            onMarkMissed: () => _handleMedicationAction(false),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              'No medication reminders for today.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 24,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                              ),
                            ),
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
}


// Custom slider track shape for gradient colors
      class GradientRectSliderTrackShape extends SliderTrackShape {
        const GradientRectSliderTrackShape({required this.gradient});
        final LinearGradient gradient;

        @override
        Rect getPreferredRect({
          required RenderBox parentBox,
          Offset offset = Offset.zero,
          required SliderThemeData sliderTheme,
          bool isEnabled = false,
          bool isDiscrete = false,
        }) {
          final double trackHeight = sliderTheme.trackHeight ?? 4.0;
          final double trackLeft = offset.dx;
          final double trackTop =
              offset.dy + (parentBox.size.height - trackHeight) / 2;
          final double trackWidth = parentBox.size.width;
          return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
        }

        @override
        void paint(
          PaintingContext context,
          Offset offset, {
          required RenderBox parentBox,
          required SliderThemeData sliderTheme,
          required Animation<double> enableAnimation,
          required TextDirection textDirection,
          required Offset thumbCenter,
          Offset? secondaryOffset,
          bool isDiscrete = false,
          bool isEnabled = false,
        }) {
          final Rect trackRect = getPreferredRect(
            parentBox: parentBox,
            offset: offset,
            sliderTheme: sliderTheme,
            isEnabled: isEnabled,
            isDiscrete: isDiscrete,
          );

          final Paint paint = Paint()
            ..shader = gradient.createShader(trackRect);

          context.canvas.drawRRect(
            RRect.fromRectAndRadius(trackRect, const Radius.circular(4)),
            paint,
          );
        }
      }
