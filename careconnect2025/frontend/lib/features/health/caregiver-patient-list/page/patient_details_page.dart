import 'package:flutter/material.dart';

// Header
import '../widgets/patient_header_card.dart';

// Info tab pieces
import '../widgets/contact_info_card.dart';
import '../widgets/emergency_contact_card.dart';

// Mood tab
import '../widgets/mood_history_card.dart'; // exposes MoodHistoryEntry + MoodHistorySection

// Health tab
import '../models/symptom_entry.dart';
import '../widgets/recent_symptom_card.dart';
import '../models/medication_entry.dart';
import '../widgets/current_medications_card.dart';

// Notes tab
import '../models/care_note.dart';
import '../widgets/add_care_notes_card.dart';
import '../widgets/care_notes_history_card.dart';

class PatientDetailsPage extends StatelessWidget {
  final String patientId;

  const PatientDetailsPage({super.key, required this.patientId});

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

    // --- Health demo data ---
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

    // --- Notes demo data (NotesTab is stateful; this is initial state) ---
    final initialNotes = <CareNote>[
      CareNote(
        id: 'n1',
        type: 'urgent',
        author: 'Dr. Smith',
        role: 'MD',
        createdAt: DateTime(2024, 12, 27, 14, 30),
        body:
        'Patient reporting severe symptoms. Recommended emergency contact. Adjusting medication schedule and monitoring closely.',
      ),
      CareNote(
        id: 'n2',
        type: 'assessment',
        author: 'Nurse Williams',
        role: 'RN',
        createdAt: DateTime(2024, 12, 26, 10, 15),
        body:
        'Patient mood improving after medication adjustment. Blood pressure stable. Continue current treatment plan.',
      ),
      CareNote(
        id: 'n3',
        type: 'medication',
        author: 'Dr. Smith',
        role: 'MD',
        createdAt: DateTime(2024, 12, 25, 16, 45),
        body:
        'Adjusted Metformin dosage due to gastrointestinal side effects. Patient tolerating change well.',
      ),
      CareNote(
        id: 'n4',
        type: 'general',
        author: 'Care Coordinator',
        role: null,
        createdAt: DateTime(2024, 12, 24, 11, 30),
        body:
        'Family support system is strong. Patient expressing gratitude for care team. Continue encouragement.',
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
            _TabsStrip(),

            // Tab views
            Expanded(
              child: TabBarView(
                children: [
                  // ---- Info ----
                  ListView(
                    padding: const EdgeInsets.only(top: 12, bottom: 16),
                    children:  [
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
                      EmergencyContactCard(
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

                  // ---- Notes ----
                  _NotesTab(initialNotes: initialNotes),
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
  const _DetailsAppBar({required this.title, required this.subtitle});
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
      foregroundColor: cs.onSurface,
      leading: const BackButton(),            // ← back arrow
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,                             // e.g. "Sarah Johnson"
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Text(
            subtitle,                          // e.g. "Patient Details • MRN-2024-0156"
            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}


/// The tab buttons row (Info • Mood • Health • Notes) styled like your mock.
class _TabsStrip extends StatelessWidget {
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
            Tab(text: 'Notes', icon: Icon(Icons.notes_outlined, size: 18)),
          ],
        ),
      ),
    );
  }
}

/// Notes tab: keeps local state so newly added notes show immediately.
class _NotesTab extends StatefulWidget {
  final List<CareNote> initialNotes;
  const _NotesTab({required this.initialNotes});

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  late List<CareNote> _notes;

  @override
  void initState() {
    super.initState();
    _notes = List<CareNote>.from(widget.initialNotes);
  }

  void _handleAdd(String type, String body) {
    final note = CareNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      author: 'You',
      role: 'Caregiver',
      createdAt: DateTime.now(),
      body: body,
    );
    setState(() => _notes.insert(0, note));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      children: [
        AddCareNoteCard(onAdd: _handleAdd),
        CareNotesHistoryCard(notes: _notes),
      ],
    );
  }
}

