import 'package:flutter/material.dart';
import '../config/theme/careconnect_theme.dart';
import '../widgets/careconnect_card.dart';
import '../widgets/careconnect_button.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final List<Map<String, dynamic>> _medications = [
    {
      'name': 'Metformin',
      'dosage': '500mg',
      'frequency': '2 times daily',
      'times': ['8:00 AM', '8:00 PM'],
      'taken': [false, false],
    },
    {
      'name': 'Lisinopril',
      'dosage': '10mg',
      'frequency': 'Once daily',
      'times': ['8:00 AM'],
      'taken': [false],
    },
    {
      'name': 'Vitamin D',
      'dosage': '1000 IU',
      'frequency': 'Once daily',
      'times': ['9:00 AM'],
      'taken': [false],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareConnectTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Medications'),
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
              'Medication Tracker',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: CareConnectTheme.primaryColor,
              ),
            ),
            const SizedBox(height: CareConnectTheme.spacingS),
            Text(
              'Track your medications and mark them as taken.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: CareConnectTheme.textSecondary,
              ),
            ),
            
            const SizedBox(height: CareConnectTheme.spacingXL),
            
            // Today's medications
            Text(
              'Today\'s Medications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: CareConnectTheme.primaryColor,
              ),
            ),
            const SizedBox(height: CareConnectTheme.spacingM),
            
            // Medications list
            ..._medications.map((medication) => _buildMedicationCard(medication)).toList(),
            
            const SizedBox(height: CareConnectTheme.spacingXL),
            
            // Add medication button
            CareConnectButton(
              text: 'Add New Medication',
              onPressed: _addMedication,
              type: CareConnectButtonType.outline,
              isFullWidth: true,
            ),
            
            const SizedBox(height: CareConnectTheme.spacingL),
            
            // Medication history
            CareConnectCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Medication History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: CareConnectTheme.spacingM),
                  _buildHistoryItem('Metformin - 8:00 AM', 'Taken 2 hours ago', true),
                  _buildHistoryItem('Lisinopril - 8:00 AM', 'Taken 2 hours ago', true),
                  _buildHistoryItem('Vitamin D - 9:00 AM', 'Taken 1 hour ago', true),
                  _buildHistoryItem('Metformin - 8:00 PM', 'Missed', false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication) {
    return CareConnectCard(
      margin: const EdgeInsets.only(bottom: CareConnectTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CareConnectTheme.primaryColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medication,
                  color: CareConnectTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: CareConnectTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication['name'],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${medication['dosage']} - ${medication['frequency']}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: CareConnectTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: CareConnectTheme.spacingM),
          
          // Dosage times
          ...medication['times'].asMap().entries.map((entry) {
            final index = entry.key;
            final time = entry.value;
            final isTaken = medication['taken'][index];
            
            return Padding(
              padding: const EdgeInsets.only(bottom: CareConnectTheme.spacingS),
              child: Row(
                children: [
                  Checkbox(
                    value: isTaken,
                    onChanged: (value) {
                      setState(() {
                        medication['taken'][index] = value!;
                      });
                    },
                    activeColor: CareConnectTheme.primaryColor,
                  ),
                  const SizedBox(width: CareConnectTheme.spacingS),
                  Text(
                    time,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (isTaken)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CareConnectTheme.spacingS,
                        vertical: CareConnectTheme.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: CareConnectTheme.successColor.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Taken',
                        style: TextStyle(
                          color: CareConnectTheme.successColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String medication, String time, bool taken) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CareConnectTheme.spacingS),
      child: Row(
        children: [
          Icon(
            taken ? Icons.check_circle : Icons.cancel,
            color: taken ? CareConnectTheme.successColor : CareConnectTheme.errorColor,
            size: 20,
          ),
          const SizedBox(width: CareConnectTheme.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: CareConnectTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addMedication() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Medication'),
        content: const Text('This feature will be available in the full version.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
