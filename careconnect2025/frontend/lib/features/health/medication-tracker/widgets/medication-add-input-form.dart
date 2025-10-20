import 'package:care_connect_app/features/health/medication-tracker/models/medication-model.dart';
import 'package:care_connect_app/widgets/ai_chat_modal.dart';
import 'package:flutter/material.dart';

/// Modal for adding a new medication
class AddMedicationModal extends StatefulWidget {
  final Function(Medication) onMedicationAdded;

  const AddMedicationModal({super.key, required this.onMedicationAdded});

  @override
  State<AddMedicationModal> createState() => _AddMedicationModalState();
}

class _AddMedicationModalState extends State<AddMedicationModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _deliveryMethodController = TextEditingController();
  final _nextDoseController = TextEditingController();

  String _selectedFrequency = '1x daily';
  final _customFrequencyController = TextEditingController();
  bool _showCustomFrequency = false;
  final List<String> _frequencyOptions = [
    '1x daily',
    '2x daily',
    '3x daily',
    '4x daily',
    'As needed',
    'Custom',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Add New Medication',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Medication Name',
                      hintText: 'e.g., Aspirin, Lisinopril, Metformin',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter medication name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _dosageController,
                      label: 'Dosage',
                      hintText: 'e.g., 10mg, 500mg, 1000 IU',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter dosage';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Frequency',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedFrequency,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items: _frequencyOptions.map((String frequency) {
                        return DropdownMenuItem<String>(
                          value: frequency,
                          child: Text(frequency),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedFrequency = newValue!;
                          _showCustomFrequency = newValue == 'Custom';
                          if (!_showCustomFrequency) {
                            _customFrequencyController.clear();
                          }
                        });
                      },
                    ),
                    if (_showCustomFrequency) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _customFrequencyController,
                        label: 'Custom Frequency',
                        hintText: 'e.g., Every 8 hours, Twice weekly, etc.',
                        validator: (value) {
                          if (_selectedFrequency == 'Custom' &&
                              (value == null || value.isEmpty)) {
                            return 'Please enter custom frequency';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nextDoseController,
                      label: 'Next Dose Time',
                      hintText: 'e.g., 9:00 AM, 6:30 PM',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter next dose time';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _deliveryMethodController,
                      label: 'Method of Delivery',
                      hintText: 'e.g., Take with food, On empty stomach',
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter delivery method';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addMedication,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Add Medication',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  void _addMedication() {
    if (_formKey.currentState!.validate()) {
      final frequency = _selectedFrequency == 'Custom'
          ? _customFrequencyController.text
          : _selectedFrequency;

      final medication = Medication(
        name: _nameController.text,
        dosage: _dosageController.text,
        frequency: frequency,
        status: MedicationStatus.upcoming,
        nextDose: _nextDoseController.text,
        deliveryMethod: _deliveryMethodController.text,
      );

      widget.onMedicationAdded(medication);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _deliveryMethodController.dispose();
    _nextDoseController.dispose();
    _customFrequencyController.dispose();
    super.dispose();
  }
}
