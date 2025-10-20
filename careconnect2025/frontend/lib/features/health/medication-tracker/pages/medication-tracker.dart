import 'package:care_connect_app/features/health/medication-tracker/models/medication-model.dart';
import 'package:care_connect_app/features/health/medication-tracker/widgets/medication-add-input-form.dart';
import 'package:care_connect_app/features/health/medication-tracker/widgets/medication-card.dart';
import 'package:care_connect_app/features/health/medication-tracker/widgets/medication-header.dart';
import 'package:flutter/material.dart';

/// Medication tracker page
class MedicationsTrackerPage extends StatefulWidget {
  const MedicationsTrackerPage({super.key});

  @override
  State<MedicationsTrackerPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsTrackerPage> {
  /// TODO - this should be removed when backend is ready
  /// Mocked medication list
  List<Medication> medications = [
    Medication(
      name: 'Blood Pressure Medication',
      dosage: '10mg',
      frequency: '2x daily',
      status: MedicationStatus.upcoming,
      nextDose: '9:00 AM',
      deliveryMethod: 'Take with food, swallow whole',
    ),
    Medication(
      name: 'Vitamin D3',
      dosage: '1000 IU',
      frequency: '1x daily',
      status: MedicationStatus.taken,
      nextDose: '6:00 PM',
      deliveryMethod: 'Take with meal for better absorption',
    ),
    Medication(
      name: 'Pain Relief Medication',
      dosage: '20mg',
      frequency: '3x daily',
      status: MedicationStatus.missed,
      nextDose: '2:00 PM',
      deliveryMethod: 'Take on empty stomach, 1 hour before meals',
    ),
  ];

  /// Method for showing the add medication modal
  /// TODO - update this to use backend. Currently it's just using mocked list
  void _showAddMedicationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMedicationModal(
        onMedicationAdded: (medication) {
          setState(() {
            medications.add(medication);
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
                      color: Theme.of(context).shadowColor.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
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
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage your medication schedule and reminders',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: medications.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return MedicationCard(
                            medication: medications[index],
                            onStatusChanged: (newStatus) {
                              setState(() {
                                medications[index] = medications[index]
                                    .copyWith(status: newStatus);
                              });
                            },
                          );
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
}
