import 'dart:convert';

import 'package:care_connect_app/features/health/medication-tracker/models/medication-model.dart';
import 'package:care_connect_app/features/health/medication-tracker/widgets/medication-add-input-form.dart';
import 'package:care_connect_app/features/health/medication-tracker/widgets/medication-card.dart';
import 'package:care_connect_app/features/health/medication-tracker/widgets/medication-header.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;



/// Medication tracker page
class MedicationsTrackerPage extends StatefulWidget {
  const MedicationsTrackerPage({super.key});

  @override
  State<MedicationsTrackerPage> createState() => _MedicationsPageState();

}

class _MedicationsPageState extends State<MedicationsTrackerPage> {
  /// Mocked medication list
  List<Medication> medications = [];

  /// Method for showing the add medication modal
  Future<void> _showAddMedicationModal() async {
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
    ///TODO: Get the proper URL for the patient
    List<Medication> allMedications = await parseMedication('insertURL');
    medications.addAll(allMedications);
  }


  ///TODO: Get the correct endpoint
  Future<List<Medication>> parseMedication(String targetURL)
  async {
      final response = await http.get(Uri.parse(targetURL));

      if(response.statusCode == 200)
        {
          return (json.decode(response.body) as List).map((data) => Medication.fromJson(data)).toList();
        }
      else
        {
          throw Exception('Failed to load medication data');
        }
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
