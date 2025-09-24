import 'package:care_connect_app/features/health/symptom-tracker/widgets/allergies_input_form.dart';
import 'package:flutter/material.dart';
import 'allergy_card.dart';

class AllergiesTab extends StatelessWidget {
  const AllergiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AllergyInputForm(),
          const SizedBox(height: 24),
          Text(
            'Known Drug Allergies',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          const AllergyCard(
            drug: 'Penicillin',
            severity: 'severe',
            reaction: 'Severe reaction: Anaphylaxis',
            note: 'Known allergy',
          ),
          const SizedBox(height: 12),
          const AllergyCard(
            drug: 'Aspirin / NSAIDs',
            severity: 'moderate',
            reaction: 'Gastrointestinal bleeding, stomach upset',
            note: 'Diagnosed 2019',
          ),
        ],
      ),
    );
  }
}
