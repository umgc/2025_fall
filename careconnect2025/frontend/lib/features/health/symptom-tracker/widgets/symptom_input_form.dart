import 'package:flutter/material.dart';
import 'package:care_connect_app/widgets/ai_chat_modal.dart';

class SymptomInputForm extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSymptomAdded;

  const SymptomInputForm({Key? key, this.onSymptomAdded}) : super(key: key);

  @override
  State<SymptomInputForm> createState() => _SymptomInputFormState();
}

class _SymptomInputFormState extends State<SymptomInputForm> {
  String _selectedSeverity = 'Mild';
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _symptomController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record Mental Health Symptom',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AIChatModal(role: 'patient'),
                    );
                  },
                  icon: const Icon(Icons.smart_toy, size: 16),
                  label: const Text('Use AI Service'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Mental Health Symptom',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _symptomController,
            decoration: InputDecoration(
              hintText: 'e.g., Suicidal thoughts, Manic episode, Anxiety...',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Severity', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedSeverity,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: ['Mild', 'Moderate', 'Severe'].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedSeverity = newValue!;
              });
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Clinical Notes',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Describe the symptom, onset, duration, triggers, and context for healthcare providers...',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_symptomController.text.trim().isNotEmpty) {
                  final symptomData = {
                    'title': _symptomController.text.trim(),
                    'severity': _selectedSeverity.toLowerCase(),
                    'time': 'Just now',
                    'description': _notesController.text.trim().isNotEmpty
                        ? _notesController.text.trim()
                        : 'No additional notes provided',
                    'requiresAttention': _selectedSeverity == 'Severe',
                    'caregiverAlert': _selectedSeverity == 'Severe',
                  };

                  widget.onSymptomAdded?.call(symptomData);

                  _symptomController.clear();
                  _notesController.clear();
                  setState(() {
                    _selectedSeverity = 'Mild';
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Symptom recorded successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Record Symptom'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _symptomController.dispose();
    super.dispose();
  }
}
