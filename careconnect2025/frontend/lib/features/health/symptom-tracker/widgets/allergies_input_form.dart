import 'package:flutter/material.dart';
import 'package:care_connect_app/widgets/ai_chat_modal.dart';

class AllergyInputForm extends StatefulWidget {
  final Function(Map<String, dynamic>)? onAllergyAdded;

  const AllergyInputForm({super.key, this.onAllergyAdded});

  @override
  State<AllergyInputForm> createState() => _AllergyInputFormState();
}

class _AllergyInputFormState extends State<AllergyInputForm> {
  String _selectedSeverity = 'Mild (Minor symptoms)';
  final TextEditingController _reactionController = TextEditingController();
  final TextEditingController _drugController = TextEditingController();

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
                'Add Drug Allergy',
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
            'Drug/Medication',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _drugController,
            decoration: InputDecoration(
              hintText: 'e.g., Penicillin, Aspirin, Codeine, Sulfa drugs...',
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
          const Text(
            'Allergic Reaction',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reactionController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText:
                  'Describe the allergic reaction (anaphylaxis, hives, swelling, breathing difficulties...)',
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
            items:
                [
                  'Mild (Minor symptoms)',
                  'Moderate (Noticeable symptoms)',
                  'Severe (Life-threatening)',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedSeverity = newValue!;
              });
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_drugController.text.trim().isNotEmpty &&
                    _reactionController.text.trim().isNotEmpty) {
                  final allergyData = {
                    'drug': _drugController.text.trim(),
                    'reaction': _reactionController.text.trim(),
                    'severity': _selectedSeverity.split(' ')[0].toLowerCase(),
                    'note': 'Added ${DateTime.now().toString().split(' ')[0]}',
                  };

                  widget.onAllergyAdded?.call(allergyData);

                  _drugController.clear();
                  _reactionController.clear();
                  setState(() {
                    _selectedSeverity = 'Mild (Minor symptoms)';
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Drug allergy added successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Drug Allergy'),
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
    _reactionController.dispose();
    _drugController.dispose();
    super.dispose();
  }
}
