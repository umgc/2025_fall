import 'package:flutter/material.dart';

// Header
import '../widgets/patient_header_card.dart';

// Info tab pieces
import '../widgets/contact_info_card.dart';
import '../widgets/emergency_contact_card.dart';

// Mood tab
import '../widgets/mood_history_card.dart';

// Health tab
import '../models/symptom_entry.dart';
import '../widgets/recent_symptom_card.dart';
import '../models/medication_entry.dart';
import '../widgets/current_medications_card.dart';

// Virtual Check-in history
// Virtual Check-In domain entities
import 'package:care_connect_app/features/health/virtual_check_in/models/virtual_check_in.dart';
import 'package:care_connect_app/features/health/virtual_check_in/models/virtual_check_in_question.dart';

// Virtual Check-In UI
import 'package:care_connect_app/features/health/virtual_check_in/presentation/widgets/virtual_check_in_config_sheet.dart';
import 'package:care_connect_app/features/health/virtual_check_in/presentation/widgets/virtual_check_in_history_card.dart';

// (If this page calls the APIs, add:)


class PatientDetailsPage extends StatelessWidget {
  final String patientId;
  /// NEW: when true, caregiver UI (can configure); when false, patient UI (no configure).
  final bool isCaregiver;

  const PatientDetailsPage({
    super.key,
    required this.patientId,
    this.isCaregiver = false, // default to patient behavior
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Fetch from your store/service using patientId.
    // For now, demo models mirrors your mockups (Sarah Johnson).
    const patientName = 'Sarah Johnson';
    const mrn = 'MRN-2024-0156';

    // --- Mood demo models ---
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

    // --- Health demo models ---
    final symptomEntries = <SymptomEntry>[
      SymptomEntry(
        id: 's4',
        date: DateTime(2024, 12, 27),
        name: 'Fatigue, Headache, Joint pain',
        severity: 'Moderate',
        note: 'Symptoms worsened during holiday stress',
      ),
      SymptomEntry(
        id: 's3',
        date: DateTime(2024, 12, 25),
        name: 'Fatigue, Nausea',
        severity: 'Severe',
        note: 'Emergency contact needed due to severe symptoms',
      ),
      SymptomEntry(
        id: 's2',
        date: DateTime(2024, 12, 23),
        name: 'Mild headache',
        severity: 'Mild',
        note: '',
      ),
      SymptomEntry(
        id: 's1',
        date: DateTime(2024, 12, 21),
        name: 'No symptoms reported',
        severity: 'Mild',
        note: 'Feeling much better, no symptoms reported',
      ),
    ];

    final medicationEntries = <MedicationEntry>[
      MedicationEntry(
        id: 'm1',
        name: 'Metformin',
        dosage: '500mg',
        frequency: 'Twice daily',
        startedOn: DateTime(2024, 1, 15),
        lastTakenAt: DateTime(2024, 12, 27, 8, 0),
        compliancePct: 95,
        status: MedicationStatus.active,
      ),
      MedicationEntry(
        id: 'm2',
        name: 'Lisinopril',
        dosage: '10mg',
        frequency: 'Once daily',
        startedOn: DateTime(2024, 3, 10),
        lastTakenAt: DateTime(2024, 12, 27, 8, 0),
        compliancePct: 92,
        status: MedicationStatus.active,
      ),
      MedicationEntry(
        id: 'm3',
        name: 'Vitamin D3',
        dosage: '2000 IU',
        frequency: 'Once daily',
        startedOn: DateTime(2024, 2, 1),
        lastTakenAt: DateTime(2024, 12, 26, 8, 0),
        compliancePct: 87,
        status: MedicationStatus.active,
      ),
    ];

    // --- Virtual Check-In demo models ---
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
      length: 4,
      child: Scaffold(
        appBar: _DetailsAppBar(title: patientName, subtitle: 'Patient Details • $mrn'),
        body: Column(
          children: [
            // Header card always visible above the tabs
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
            ),

            // Tab bar row (like your mock)
            const _TabsStrip(),

            // Tab views
            Expanded(
              child: TabBarView(
                children: [
                  // ---- Info ----
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


                  // ---- Mood ----
                  ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      MoodHistorySection(entries: moodEntries),
                    ],
                  ),

                  // ---- Health ----
                  ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      RecentSymptomsSection(entries: symptomEntries),
                      const SizedBox(height: 8),
                      CurrentMedicationsSection(entries: medicationEntries),
                    ],
                  ),

                  // ---- Virtual Check-In tab ----
                  ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      VirtualCheckInHistoryCard(
                        entries: virtualCheckIns,
                        showConfigure: isCaregiver, // caregivers only
                        onConfigure: isCaregiver
                            ? () async {
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
                        }
                            : null, // patients: no button
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
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
          unselectedLabelColor: cs.onSurface.withValues(alpha: .7),
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
