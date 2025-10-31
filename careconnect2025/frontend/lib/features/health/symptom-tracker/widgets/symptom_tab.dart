import 'package:flutter/material.dart';
import 'symptom_input_form.dart';
import 'symptom_card.dart';

class SymptomTab extends StatefulWidget {
  const SymptomTab({super.key});

  @override
  State<SymptomTab> createState() => _SymptomTabState();
}

class _SymptomTabState extends State<SymptomTab> {
  late List<Map<String, dynamic>> _symptoms;

  @override
  void initState() {
    super.initState();
    _symptoms = [
      {
        'title': 'Suicidal thoughts',
        'severity': 'severe',
        'time': 'Today at 2:15 PM',
        'description':
            'Patient expressing thoughts of self-harm. Immediate intervention required.',
        'requiresAttention': true,
        'caregiverAlert': true,
      },
      {
        'title': 'Anxiety',
        'severity': 'moderate',
        'time': 'Yesterday at 6:30 PM',
        'description': 'Increased worry about upcoming medical appointment',
        'requiresAttention': false,
        'caregiverAlert': false,
      },
      {
        'title': 'Depression',
        'severity': 'moderate',
        'time': '2 days ago at 10:45 AM',
        'description': 'Persistent feelings of sadness and hopelessness',
        'requiresAttention': true,
        'caregiverAlert': false,
      },
      {
        'title': 'Sleep disturbance',
        'severity': 'mild',
        'time': '3 days ago at 11:30 PM',
        'description': 'Difficulty falling asleep, frequent nightmares',
        'requiresAttention': false,
        'caregiverAlert': false,
      },
      {
        'title': 'Panic attack',
        'severity': 'severe',
        'time': '4 days ago at 3:20 PM',
        'description': 'Sudden onset of intense fear with physical symptoms',
        'requiresAttention': true,
        'caregiverAlert': true,
      },
    ];
  }

  void _addSymptom(Map<String, dynamic> symptomData) {
    setState(() {
      _symptoms.insert(0, symptomData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SymptomInputForm(onSymptomAdded: _addSymptom),
          const SizedBox(height: 24),
          Text(
            'Recent Mental Health Symptoms',
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
            itemCount: _symptoms.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final symptom = _symptoms[index];
              return SymptomCard(
                title: symptom['title'],
                severity: symptom['severity'],
                time: symptom['time'],
                description: symptom['description'],
                requiresAttention: symptom['requiresAttention'],
                caregiverAlert: symptom['caregiverAlert'],
              );
            },
          ),
        ],
      ),
    );
  }
}
