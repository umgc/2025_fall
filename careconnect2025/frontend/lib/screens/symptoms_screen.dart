import 'package:flutter/material.dart';
import '../config/theme/careconnect_theme.dart';
import '../widgets/careconnect_card.dart';
import '../widgets/careconnect_button.dart';

class SymptomsScreen extends StatefulWidget {
  const SymptomsScreen({super.key});

  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  final List<String> _selectedSymptoms = [];
  final List<String> _availableSymptoms = [
    'Headache',
    'Fever',
    'Cough',
    'Shortness of breath',
    'Chest pain',
    'Nausea',
    'Dizziness',
    'Fatigue',
    'Muscle aches',
    'Joint pain',
    'Rash',
    'Swelling',
    'Numbness',
    'Tingling',
    'Vision changes',
    'Hearing changes',
    'Memory problems',
    'Confusion',
    'Mood changes',
    'Sleep problems',
  ];

  String _severity = 'Mild';
  String _duration = 'Less than 1 hour';
  String _notes = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareConnectTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Report Symptoms'),
        backgroundColor: CareConnectTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(CareConnectTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Report Your Symptoms',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: CareConnectTheme.primaryColor,
              ),
            ),
            const SizedBox(height: CareConnectTheme.spacingS),
            Text(
              'Select the symptoms you are experiencing and provide additional details.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: CareConnectTheme.textSecondary,
              ),
            ),
            
            const SizedBox(height: CareConnectTheme.spacingXL),
            
            // Symptoms selection
            CareConnectCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Symptoms',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: CareConnectTheme.spacingM),
                  Wrap(
                    spacing: CareConnectTheme.spacingS,
                    runSpacing: CareConnectTheme.spacingS,
                    children: _availableSymptoms.map((symptom) {
                      final isSelected = _selectedSymptoms.contains(symptom);
                      return FilterChip(
                        label: Text(symptom),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSymptoms.add(symptom);
                            } else {
                              _selectedSymptoms.remove(symptom);
                            }
                          });
                        },
                        selectedColor: CareConnectTheme.primaryColor.withValues(alpha:0.2),
                        checkmarkColor: CareConnectTheme.primaryColor,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: CareConnectTheme.spacingL),
            
            // Severity
            CareConnectCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Severity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: CareConnectTheme.spacingM),
                  DropdownButtonFormField<String>(
                    value: _severity,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: ['Mild', 'Moderate', 'Severe', 'Very Severe']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _severity = newValue!;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: CareConnectTheme.spacingL),
            
            // Duration
            CareConnectCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Duration',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: CareConnectTheme.spacingM),
                  DropdownButtonFormField<String>(
                    value: _duration,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'Less than 1 hour',
                      '1-4 hours',
                      '4-12 hours',
                      '12-24 hours',
                      '1-3 days',
                      'More than 3 days',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _duration = newValue!;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: CareConnectTheme.spacingL),
            
            // Notes
            CareConnectCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: CareConnectTheme.spacingM),
                  TextField(
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Describe your symptoms in more detail...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _notes = value,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: CareConnectTheme.spacingXL),
            
            // Submit button
            CareConnectButton(
              text: 'Submit Symptoms Report',
              onPressed: _canSubmit() ? _submitSymptoms : null,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  bool _canSubmit() {
    return _selectedSymptoms.isNotEmpty;
  }

  void _submitSymptoms() {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Symptoms report submitted successfully!'),
        backgroundColor: CareConnectTheme.successColor,
      ),
    );
    
    // Navigate back to home
    Navigator.of(context).pop();
  }
}
