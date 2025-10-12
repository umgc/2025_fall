import 'package:care_connect_app/features/health/symptom-tracker/widgets/allergies_input_form.dart';
import 'package:flutter/material.dart';
import 'allergy_card.dart';

class AllergiesTab extends StatefulWidget {
  const AllergiesTab({super.key});

  @override
  State<AllergiesTab> createState() => _AllergiesTabState();
}

class _AllergiesTabState extends State<AllergiesTab> {
  final List<Map<String, dynamic>> _allergies = [
    {
      'drug': 'Penicillin',
      'severity': 'severe',
      'reaction': 'Severe reaction: Anaphylaxis',
      'note': 'Known allergy',
    },
    {
      'drug': 'Aspirin / NSAIDs',
      'severity': 'moderate',
      'reaction': 'Gastrointestinal bleeding, stomach upset',
      'note': 'Diagnosed 2019',
    },
  ];

  void _addAllergy(Map<String, dynamic> allergyData) {
    setState(() {
      _allergies.insert(0, allergyData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AllergyInputForm(onAllergyAdded: _addAllergy),
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allergies.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final allergy = _allergies[index];
              return AllergyCard(
                drug: allergy['drug'],
                severity: allergy['severity'],
                reaction: allergy['reaction'],
                note: allergy['note'],
              );
            },
          ),
        ],
      ),
    );
  }
}
