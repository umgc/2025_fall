import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

// Pain level card
import '../widgets/pain_level_card.dart';

// Header
import '../widgets/patient_header_card.dart';

// Info tab pieces
import '../widgets/contact_info_card.dart';
import '../widgets/emergency_contact_card.dart';

// Mood tab
import '../widgets/mood_history_card.dart';

// Health tab
import '../widgets/current_medications_card.dart';

// Recent Activity tab
import '../widgets/recent_activity_tab.dart';

// Virtual Check-in history
// Virtual Check-In domain entities
import 'package:care_connect_app/features/health/virtual_check_in/models/virtual_check_in.dart';
import 'package:care_connect_app/features/health/virtual_check_in/models/virtual_check_in_question.dart';

// Virtual Check-In UI
import 'package:care_connect_app/features/health/virtual_check_in/presentation/widgets/virtual_check_in_config_sheet.dart';
import 'package:care_connect_app/features/health/virtual_check_in/presentation/widgets/virtual_check_in_history_card.dart';

// (If this page calls the APIs, add:)


// 👉 Alias BOTH sides to avoid type clashes
import '../models/symptom_entry.dart' as model;
import '../widgets/recent_symptom_card.dart' as sympt;

// API and models
import '../../../../services/api_service.dart';
import '../../../health/medication-tracker/models/medication-model.dart';
import '../../../../providers/user_provider.dart';

class PatientDetailsPage extends StatefulWidget {
  final String patientId;
  /// NEW: when true, caregiver UI (can configure); when false, patient UI (no configure).
  final bool isCaregiver;

  const PatientDetailsPage({
    super.key,
    required this.patientId,
    this.isCaregiver = false, // default to patient behavior
  });

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  List<Medication> medications = [];
  bool _isLoadingMedications = false;
  String? _medicationError;
  
  @override
  void initState() {
    super.initState();
    _fetchMedications();
  }

  /// Fetch medications from the backend API
  Future<void> _fetchMedications() async {
    setState(() {
      _isLoadingMedications = true;
      _medicationError = null;
    });

    try {
      // Parse patientId from String to int
      final patientIdInt = int.tryParse(widget.patientId);

      if (patientIdInt == null) {
        setState(() {
          _isLoadingMedications = false;
          _medicationError = 'Invalid patient ID';
        });
        return;
      }

      final http.Response resp =
          await ApiService.getPatientMedicationsForPatient(patientIdInt);

      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);

        setState(() {
          medications = data.map((json) => Medication.fromJson(json)).toList();
          _isLoadingMedications = false;
        });
      } else {
        setState(() {
          _isLoadingMedications = false;
          _medicationError = 'Failed to load medications: ${resp.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMedications = false;
        _medicationError = 'Error loading medications: $e';
      });
    }
  }

  /// Build the medications section with loading/error handling
  Widget _buildMedicationsSection() {
    if (_isLoadingMedications) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (_medicationError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _medicationError!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchMedications,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Get caregiverId from user provider
    final caregiverId = Provider.of<UserProvider>(
      context,
      listen: false,
    ).user?.caregiverId;

    return CurrentMedicationsSection(
      entries: medications,
      onMedicationUpdated: _fetchMedications,
      // Refresh medications after delete/approve
      caregiverId: caregiverId,
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Fetch from your store/service using patientId.
    // For now, demo data mirrors your mockups (Sarah Johnson).
    const patientName = 'Sarah Johnson';
    const mrn = 'MRN-2024-0156';

    // --- Mood demo data ---
    final moodEntries = <MoodHistoryEntry>[
      MoodHistoryEntry(
        date: DateTime(2024, 12, 27),
        label: 'Poor',
        score5: 2,
        emoji: '😟',
        note: 'Feeling exhausted and overwhelmed',
      ),
      MoodHistoryEntry(
        date: DateTime(2024, 12, 26),
        label: 'Fair',
        score5: 3,
        emoji: '😐',
        note: 'Better after medication adjustment',
      ),
      MoodHistoryEntry(
        date: DateTime(2024, 12, 25),
        label: 'Poor',
        score5: 2,
        emoji: '😟',
        note: 'Holiday stress affecting mood',
      ),
      MoodHistoryEntry(
        date: DateTime(2024, 12, 24),
        label: 'Good',
        score5: 4,
        emoji: '🙂',
        note: 'Family visit lifted spirits',
      ),
      MoodHistoryEntry(
        date: DateTime(2024, 12, 23),
        label: 'Fair',
        score5: 3,
        emoji: '😐',
      ),
    ];

    // MODEL entries
    final modelSymptomEntries = <model.SymptomEntry>[
      model.SymptomEntry(
        id: 's4',
        date: DateTime(2024, 12, 27),
        name: 'Fatigue, Headache, Joint pain',
        severity: 'Moderate',
        note: 'Symptoms worsened during holiday stress',
      ),
      model.SymptomEntry(
        id: 's3',
        date: DateTime(2024, 12, 25),
        name: 'Fatigue, Nausea',
        severity: 'Severe',
        note: 'Emergency contact needed due to severe symptoms',
      ),
      model.SymptomEntry(
        id: 's2',
        date: DateTime(2024, 12, 23),
        name: 'Mild headache',
        severity: 'Mild',
        note: null, // demo of nullable
      ),
      model.SymptomEntry(
        id: 's1',
        date: DateTime(2024, 12, 21),
        name: 'No symptoms reported',
        severity: 'Mild',
        note: 'Feeling much better, no symptoms reported',
      ),
    ];

    // Convert to the WIDGET type
    final uiSymptomEntries = <sympt.SymptomEntry>[
      for (final s in modelSymptomEntries)
        sympt.SymptomEntry(
          id: s.id,
          date: s.date,
          name: s.name,
          severity: s.severity,
          note: s.note ?? '', // <-- fix: ensure non-null String
        ),
    ];

    final activityList = const [
      ActivityEntry(
        title: 'Took medication: Lisinopril 10mg',
        when: '2 hours ago',
      ),
      ActivityEntry(title: 'Video call completed', when: '4 hours ago'),
      ActivityEntry(title: 'Reported pain level: 3/10', when: '6 hours ago'),
      ActivityEntry(
        title: 'Appointment with Dr. Smith scheduled',
        when: 'Yesterday',
      ),
    ];

    // --- Virtual Check-In demo data ---
    final virtualCheckIns = <VirtualCheckIn>[
      VirtualCheckIn(
        id: 'vc1',
        type: CheckInType.routine,
        clinicianName: 'Dr. Sarah Johnson',
        startedAt: DateTime(2024, 12, 4, 10, 30),
        durationMinutes: 15,
        status: CheckInStatus.completed,
        moodLabel: 'Good',
        nextCheckIn: DateTime(2024, 12, 11, 10, 30),
        summary: 'Reviewed medication plan; patient stable and adherent.',
      ),
      VirtualCheckIn(
        id: 'vc2',
        type: CheckInType.followUp,
        clinicianName: 'Nurse Williams',
        startedAt: DateTime(2024, 12, 1, 14, 0),
        durationMinutes: 20,
        status: CheckInStatus.completed,
        moodLabel: 'Fair',
        nextCheckIn: DateTime(2024, 12, 8, 14, 0),
        summary: 'Follow-up on home BP readings; stable overall.',
      ),
      VirtualCheckIn(
        id: 'vc3',
        type: CheckInType.urgent,
        clinicianName: 'Dr. Smith',
        startedAt: DateTime(2024, 11, 28, 9, 0),
        durationMinutes: 10,
        status: CheckInStatus.completed,
        moodLabel: 'Poor',
        nextCheckIn: DateTime(2024, 12, 5, 9, 0),
        summary: 'Urgent check-in for severe headache; symptoms improved.',
      ),
    ];

    // --- Virtual Check-In configuration (popup) ---
    final initialQuestions = <VirtualCheckInQuestion>[
      VirtualCheckInQuestion(
        id: 'q1',
        type: CheckInQuestionType.numerical,
        required: true,
        text: 'Rate your pain level (1–10)',
      ),
      VirtualCheckInQuestion(
        id: 'q2',
        type: CheckInQuestionType.yesNo,
        required: true,
        text: 'Did you take your morning medications?',
      ),
      VirtualCheckInQuestion(
        id: 'q3',
        type: CheckInQuestionType.textInput,
        required: false,
        text: 'Any additional symptoms or concerns?',
      ),
    ];

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: _DetailsAppBar(
          title: patientName,
          subtitle: 'Patient Details • $mrn',
        ),
        body: Column(
          children: [
            PatientHeaderCard(
              fullName: patientName,
              mrn: mrn,
              age: 49,
              sex: 'Female',
              currentMoodLabel: 'Poor',
              currentMoodEmoji: '😟',
              diagnoses: const [
                'Type 2 Diabetes',
                'Hypertension',
                'Chronic Fatigue Syndrome',
              ],
              allergies: const ['Penicillin', 'Shellfish'],
              /*heartRateBpm: 72,
              bpSystolic: 120,
              bpDiastolic: 80,
              oxygenPercent: 98,
              temperatureF: 98.0,*/
              emergencyPhones: const ['+15559876543', '+15552227788'],
            ),

            // Tab bar row (like your mock)
            const _TabsStrip(),

            // Tab views
            Expanded(
              child: TabBarView(
                children: [
                  // Info
                  ListView(
                    padding: const EdgeInsets.only(top: 12, bottom: 16),
                    children: [
                      ContactInfoCard(
                        phone: '(555) 123-4567',
                        email: 'sarah.johnson@email.com',
                        dateOfBirth: DateTime(1975, 3, 15),
                        addressLine1: '123 Main St',
                        addressLine2: 'Apt 4B',
                        city: 'Springfield',
                        state: 'IL',
                        postalCode: '62701',
                      ),
                      const EmergencyContactCard(
                        contactName: 'Michael Johnson',
                        relationship: 'Spouse',
                        phone: '(555) 987-6543',
                      ),
                    ],
                  ),

                  // Mood
                  ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [MoodHistorySection(entries: moodEntries)],
                  ),

                  // Health
                  ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      const PainLevelCard(
                        lastReportedText: '6 hours ago',
                        currentPain: 4,
                        location: 'Lower back',
                        dizziness: 2,
                        fatigue: 7,
                      ),
                      // Recent Symptoms (UI-typed list)
                      sympt.RecentSymptomsSection(entries: uiSymptomEntries),
                      const SizedBox(height: 8),
                      _buildMedicationsSection(),
                    ],
                  ),

                  // ---- Virtual Check-In tab ----
                  // ---- Virtual Check-In tab ----
                  ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      VirtualCheckInHistoryCard(
                        entries: virtualCheckIns,
                        showConfigure: widget.isCaregiver, // caregivers only
                        onConfigure: widget.isCaregiver ? () async {
                          // Seed with your current config if you have it:
                          final initialQuestions = <VirtualCheckInQuestion>[];
                          // TODO: replace with your real ID source:
                          final checkInId = 1; // TODO: replace with real patient id


                          final updated = await showModalBottomSheet<List<VirtualCheckInQuestion>?>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (_) => VirtualCheckInConfigSheet(
                              checkInId: checkInId,          // ✅ required
                              initial: initialQuestions,
                            ),
                          );

                          if (!context.mounted) return;
                          if (updated != null) {
                            // TODO: persist `updated` to backend and refresh UI
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Virtual check-in configuration saved')),
                            );
                          }
                        } : null, // patients: no button
                      ),
                    ],
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
/// shows back arrow + name + MRN line
class _DetailsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DetailsAppBar({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      elevation: 0,
      backgroundColor: cs.surface,
      iconTheme: IconThemeData(color: cs.onSurface),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// The tab buttons row (Info • Mood • Health • Virtual Check-In)
class _TabsStrip extends StatelessWidget {
  const _TabsStrip();     // <-- add const + super.key

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: TabBar(
          isScrollable: false,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurface.withOpacity(.7),
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: cs.primary, width: 3),
          ),
          tabs: const [
            Tab(text: 'Info', icon: Icon(Icons.info_outline, size: 18)),
            Tab(text: 'Mood', icon: Icon(Icons.favorite_border, size: 18)),
            Tab(text: 'Health', icon: Icon(Icons.health_and_safety_outlined, size: 18)),
            Tab(text: 'Virtual Check-In', icon: Icon(Icons.video_call_outlined, size: 18)),
          ],
        ),
      ),
    );
  }
}
