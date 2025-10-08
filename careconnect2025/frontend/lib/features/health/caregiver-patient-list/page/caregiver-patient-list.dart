import 'package:care_connect_app/features/health/caregiver-patient-list/models/patient-info.dart';
import 'package:care_connect_app/features/health/caregiver-patient-list/widgets/patient-info-card.dart';
import 'package:care_connect_app/widgets/default_app_header.dart';
import 'package:care_connect_app/features/health/caregiver-patient-list/page/patient_details_page.dart';
import 'package:flutter/material.dart';

/// Main screen for caregivers to view and manage their patient list.
///
/// This widget provides a comprehensive interface for caregivers to:
/// - View statistics of urgent and normal cases
/// - Search through their patient list
/// - View patient cards with essential health information
/// - Navigate to individual patient details
///
/// The screen includes pull-to-refresh functionality and real-time search filtering.
class CaregiverPatientList extends StatefulWidget {
  const CaregiverPatientList({super.key});

  @override
  State<CaregiverPatientList> createState() => _CaregiverPatientList();
}

class _CaregiverPatientList extends State<CaregiverPatientList> {
  /// Complete list of all patients assigned to this caregiver
  List<Patient> _allPatients = [];

  /// Filtered list of patients based on search query
  List<Patient> _filteredPatients = [];

  /// Controller for the search text field
  final TextEditingController _searchController = TextEditingController();

  /// Loading state indicator for async operations
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Loads patient data from the server.
  ///
  /// Currently uses mock data with simulated network delay.
  Future<void> _loadPatients() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    // Simulate API call with delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final patients = _generateMockPatients();

    if (!mounted) return;
    setState(() {
      _allPatients = patients;
      _filteredPatients = patients;
      _isLoading = false;
    });
  }

  /// Generates mock patient data for testing and development.
  List<Patient> _generateMockPatients() {
    return [
      Patient(
        id: '1',
        firstName: 'Sarah',
        lastName: 'Johnson',
        lastUpdated: DateTime(2024, 12, 25),
        statusMessage: 'Severe symptoms reported',
        nextCheckIn: DateTime(2024, 12, 28),
        mood: 'Poor',
        moodEmoji: '😟',
        isUrgent: true,
        messageCount: 2,
      ),
      Patient(
        id: '2',
        firstName: 'Robert',
        lastName: 'Chen',
        lastUpdated: DateTime(2024, 12, 24),
        statusMessage: 'Missed medication dose',
        nextCheckIn: DateTime(2024, 12, 28),
        mood: 'Concerned',
        moodEmoji: '😐',
        isUrgent: true,
        messageCount: 1,
      ),
      Patient(
        id: '3',
        firstName: 'James',
        lastName: 'Wilson',
        lastUpdated: DateTime(2024, 12, 23),
        statusMessage: 'Routine checkup scheduled',
        nextCheckIn: DateTime(2024, 12, 30),
        mood: 'Good',
        moodEmoji: '😊',
        isUrgent: false,
        messageCount: 1,
      ),
      Patient(
        id: '4',
        firstName: 'Emily',
        lastName: 'Davis',
        lastUpdated: DateTime(2024, 12, 22),
        statusMessage: 'Recovery progressing well',
        nextCheckIn: DateTime(2024, 12, 29),
        mood: 'Great',
        moodEmoji: '😄',
        isUrgent: false,
        messageCount: 0,
      ),
      Patient(
        id: '5',
        firstName: 'Michael',
        lastName: 'Brown',
        lastUpdated: DateTime(2024, 12, 21),
        statusMessage: 'Blood pressure elevated',
        nextCheckIn: DateTime(2024, 12, 27),
        mood: 'Worried',
        moodEmoji: '😰',
        isUrgent: true,
        messageCount: 1,
      ),
      Patient(
        id: '6',
        firstName: 'Lisa',
        lastName: 'Anderson',
        lastUpdated: DateTime(2024, 12, 20),
        statusMessage: 'Feeling much better',
        nextCheckIn: DateTime(2024, 12, 31),
        mood: 'Excellent',
        moodEmoji: '🥰',
        isUrgent: false,
        messageCount: 0,
      ),
    ];
  }

  /// Handles search text changes and filters the patient list.
  void _onSearchChanged() {
    if (!mounted) return;

    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _filteredPatients = _allPatients;
      });
      return;
    }

    final results = _allPatients.where((patient) {
      final fullName = patient.fullName.toLowerCase();
      final firstName = patient.firstName.toLowerCase();
      final lastName = patient.lastName.toLowerCase();

      return fullName.contains(query) ||
          firstName.startsWith(query) ||
          lastName.startsWith(query) ||
          _fuzzyMatch(query, fullName);
    }).toList();

    if (!mounted) return;
    setState(() {
      _filteredPatients = results;
    });
  }

  /// Performs a simple fuzzy match for typo tolerance.
  bool _fuzzyMatch(String query, String target) {
    if (query.length <= 2) return false;

    final allowedDifferences = query.length <= 4 ? 1 : 2;
    var differences = 0;

    for (var i = 0; i < query.length && i < target.length; i++) {
      if (query[i] != target[i]) {
        differences++;
        if (differences > allowedDifferences) {
          return false;
        }
      }
    }

    return differences <= allowedDifferences;
  }

  int get urgentCasesCount => _allPatients.where((p) => p.isUrgent).length;
  int get normalCasesCount => _allPatients.where((p) => !p.isUrgent).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: DefaultAppHeader(),
      body: RefreshIndicator(
        onRefresh: () async {
          if (!mounted) return;
          await _loadPatients();
        },
        child: Column(
          children: [
            // Stats Cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      urgentCasesCount.toString(),
                      'Urgent Cases',
                      Colors.red,
                      theme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      normalCasesCount.toString(),
                      'Normal Status',
                      Colors.green,
                      theme,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Enter patient name...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                          },
                          icon: Icon(
                            Icons.clear,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      : Icon(
                          Icons.tune,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  // If you are not on Flutter 3.22+ replace with .withOpacity
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Patient List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : _filteredPatients.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No patients found',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredPatients.length,
                          itemBuilder: (context, index) {
                            final patient = _filteredPatients[index];
                            return PatientCard(
                              patient: patient,
                              onTap: () {
                                if (!mounted) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PatientDetailsPage(
                                      patientId: patient.id,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a statistics card widget.
  Widget _buildStatCard(
    String count,
    String label,
    Color color,
    ThemeData theme,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
