import 'package:care_connect_app/features/health/medication-tracker/models/medication-model.dart';
import 'package:care_connect_app/features/health/medication-tracker/widgets/medication-add-input-form.dart';
import 'package:care_connect_app/features/health/medication-tracker/widgets/medication-card.dart';
import 'package:care_connect_app/features/health/medication-tracker/widgets/medication-header.dart';
import 'package:flutter/material.dart';

// API client to pull activeMedications from /profile/enhanced
import 'package:care_connect_app/features/health/medication-tracker/data/medications_api.dart';

/// Medication tracker page
class MedicationsTrackerPage extends StatefulWidget {
  const MedicationsTrackerPage({super.key});

  @override
  State<MedicationsTrackerPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsTrackerPage> {
  final String baseUrl = 'http://10.0.2.2:8080'; // Android emulator -> host's localhost:8080
  final int patientId = 1;                        // Get via GET /v1/api/patients/me
  final String jwt = '<JWT>';                     // Inject your real token

  late Future<List<Medication>> _future;
  final List<Medication> _localAdds = []; // Add-modal items (local only; no POST yet)

  @override
  void initState() {
    super.initState();
    _future = fetchMedicationsFromEnhancedProfile(
      baseUrl: baseUrl,
      patientId: patientId,
      jwtToken: jwt,
    );
  }

  // Method for showing the add medication modal
  void _showAddMedicationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMedicationModal(
        onMedicationAdded: (medication) {
          setState(() {
            _localAdds.add(medication);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MedicationAppHeader(onAddPressed: _showAddMedicationModal),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Medications',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage your medication schedule and reminders',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    //  Replace hardcoded list with  backend meds
                    Expanded(
                      child: FutureBuilder<List<Medication>>(
                        future: _future,
                        builder: (context, snap) {
                          if (snap.connectionState != ConnectionState.done) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snap.hasError) {
                            final meds = [..._localAdds];
                            return meds.isEmpty
                                ? Center(child: Text('Error: ${snap.error}'))
                                : _medList(meds);
                          }

                          final backendMeds = snap.data ?? <Medication>[];
                          final meds = [...backendMeds, ..._localAdds];

                          if (meds.isEmpty) {
                            return const Center(child: Text('No medications found.'));
                          }

                          return _medList(meds);
                        },
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Re-usable list builder
  Widget _medList(List<Medication> meds) => ListView.separated(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    itemCount: meds.length,
    separatorBuilder: (context, index) => const SizedBox(height: 16),
    itemBuilder: (context, index) {
      return MedicationCard(
        medication: meds[index],
        onStatusChanged: (newStatus) {
          setState(() {
            meds[index] = meds[index].copyWith(status: newStatus);
          });
        },
      );
    },
  );
}
