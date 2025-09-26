import 'package:care_connect_app/features/health/caregiver-patient-list/models/patient-info.dart';
import 'package:care_connect_app/features/health/caregiver-patient-list/widgets/patient-info-card.dart';
import 'package:care_connect_app/widgets/default_app_header.dart';
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
  /// Creates a CaregiverPatientList widget.
  const CaregiverPatientList({super.key});

  @override
  State<CaregiverPatientList> createState() => _CaregiverPatientList();
}

/// Private state class for CaregiverPatientList.
///
/// Manages patient data loading, filtering, and search functionality.
class _CaregiverPatientList extends State<CaregiverPatientList> {
  /// Complete list of all patients assigned to this caregiver
  List<Patient> _allPatients = [];

  /// Filtered list of patients based on search query
  List<Patient> _filteredPatients = [];

  /// Controller for the search text field
  final TextEditingController _searchController = TextEditingController();

  /// Loading state indicator for async operations
  bool _isLoading = false;

  /// Initializes the widget state.
  ///
  /// Sets up the search controller listener and loads initial patient data.
  @override
  void initState() {
    super.initState();
    _loadPatients();
    _searchController.addListener(_onSearchChanged);
  }

  /// Cleans up resources when the widget is disposed.
  ///
  /// Removes the search controller listener and disposes of the controller.
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Loads patient data from the server.
  ///
  /// Currently uses mock data with simulated network delay.
  /// In production, this would make an actual API call to fetch
  /// the caregiver's assigned patients.
  ///
  /// Returns:
  /// * Future<void> - Completes when patient data is loaded
  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call with delay
    await Future.delayed(const Duration(seconds: 1));

    final patients = _generateMockPatients();
    setState(() {
      _allPatients = patients;
      _filteredPatients = patients;
      _isLoading = false;
    });
  }

  /// Generates mock patient data for testing and development.
  ///
  /// Creates a list of sample patients with varying health statuses,
  /// mood indicators, and urgency levels to demonstrate the UI.
  ///
  /// Returns:
  /// * List<Patient> - A list of mock patient objects
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
  ///
  /// Filters patients based on the search query using multiple matching strategies:
  /// - Exact substring matching in full name
  /// - Prefix matching on first and last names
  /// - Fuzzy matching for typo tolerance
  ///
  /// Updates the filtered patient list and triggers a rebuild.
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _filteredPatients = _allPatients;
      });
    } else {
      final results = _allPatients.where((patient) {
        final fullName = patient.fullName.toLowerCase();
        final firstName = patient.firstName.toLowerCase();
        final lastName = patient.lastName.toLowerCase();

        // Check if query matches any part of the name
        return fullName.contains(query) ||
            firstName.startsWith(query) ||
            lastName.startsWith(query) ||
            _fuzzyMatch(query, fullName);
      }).toList();

      setState(() {
        _filteredPatients = results;
      });
    }
  }

  /// Performs fuzzy matching to handle search typos.
  ///
  /// Compares characters position by position and allows for a limited
  /// number of differences based on the query length. Shorter queries
  /// allow fewer differences to maintain search relevance.
  ///
  /// Parameters:
  /// * [query] - The search query string (lowercase)
  /// * [target] - The target string to match against (lowercase)
  ///
  /// Returns:
  /// * bool - True if the strings match within the allowed difference threshold
  bool _fuzzyMatch(String query, String target) {
    if (query.length <= 2) return false;

    // Allow for 1-2 character differences depending on length
    int allowedDifferences = query.length <= 4 ? 1 : 2;
    int differences = 0;

    for (int i = 0; i < query.length && i < target.length; i++) {
      if (query[i] != target[i]) {
        differences++;
        if (differences > allowedDifferences) {
          return false;
        }
      }
    }

    return differences <= allowedDifferences;
  }

  /// Returns the count of patients requiring urgent attention.
  ///
  /// Counts patients where the isUrgent flag is true.
  ///
  /// Returns:
  /// * int - Number of urgent cases
  int get urgentCasesCount => _allPatients.where((p) => p.isUrgent).length;

  /// Returns the count of patients with normal status.
  ///
  /// Counts patients where the isUrgent flag is false.
  ///
  /// Returns:
  /// * int - Number of normal status cases
  int get normalCasesCount => _allPatients.where((p) => !p.isUrgent).length;

  /// Builds the main UI for the caregiver patient list screen.
  ///
  /// Creates a scaffold with:
  /// - App header
  /// - Statistics cards showing urgent and normal cases
  /// - Search bar with filter options
  /// - Patient list with pull-to-refresh functionality
  /// - Loading states and empty state handling
  ///
  /// Parameters:
  /// * [context] - The build context
  ///
  /// Returns:
  /// * Widget - The complete patient list screen UI
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: DefaultAppHeader(),
      body: RefreshIndicator(
        onRefresh: _loadPatients,
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
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
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
                            // Navigate to patient details
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Tapped on ${patient.fullName}'),
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
  ///
  /// Creates a card displaying a count and label with appropriate styling.
  /// Used for showing urgent cases and normal status counts.
  ///
  /// Parameters:
  /// * [count] - The numerical value to display
  /// * [label] - The descriptive label for the statistic
  /// * [color] - The color to use for the count text
  /// * [theme] - The app theme data for consistent styling
  ///
  /// Returns:
  /// * Widget - A styled card containing the statistic
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
