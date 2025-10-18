import 'package:care_connect_app/features/ai/presentation/pages/voice_command_ai.dart';
import 'package:flutter/material.dart';
import 'package:care_connect_app/services/api_service.dart';
import 'package:care_connect_app/features/health/shared/data/health_api.dart';
import 'package:care_connect_app/services/deepseek_service.dart';


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

  // Will be set after we fetch the JWT
  late HealthApi _api;
  bool _apiReady = false;

  int? _patientId;
  bool _loadingId = true;

  bool _usingAi = false;

  @override
  void initState() {
    super.initState();
    _initApi(); // fetch JWT, build HealthApi, then load patient id
  }

  Future<void> _initApi() async {
    try {
      final jwt = await ApiService.getJwtToken();
      if (jwt.isEmpty) {
        throw Exception('No JWT available');
      }
      _api = HealthApi(jwt);
      setState(() => _apiReady = true);
      await _loadMyPatientId();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _apiReady = false;
        _loadingId = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auth not ready: $e')),
      );
    }
  }

  // Get patientId for the logged-in user
  Future<void> _loadMyPatientId() async {
    try {
      final id = await _api.getMyPatientId();
      if (!mounted) return;
      setState(() {
        _patientId = id;
        _loadingId = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingId = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to prepare form: $e')),
      );
    }
  }

  void _applyAiResult(Map<String, dynamic> ai) {
    final allergen = (ai['allergen'] ?? '').toString().trim();
    final reaction = (ai['reaction'] ?? '').toString().trim();
    final sevRaw   = (ai['severity'] ?? '').toString().toUpperCase();

    String dropdownLabel = 'Mild (Minor symptoms)';
    switch (sevRaw) {
      case 'MODERATE':
        dropdownLabel = 'Moderate (Noticeable symptoms)';
        break;
      case 'SEVERE':
        dropdownLabel = 'Severe (Life-threatening)';
        break;
      case 'MILD':
      default:
        dropdownLabel = 'Mild (Minor symptoms)';
    }

    setState(() {
      if (allergen.isNotEmpty) _drugController.text = allergen;
      if (reaction.isNotEmpty) _reactionController.text = reaction;
      _selectedSeverity = dropdownLabel;
    });
  }

  Future<void> _submitAllergy() async {
    final allergen = _drugController.text.trim();        // send as allergen
    final reaction = _reactionController.text.trim();
    final sevUi = _selectedSeverity.split(' ').first.toLowerCase(); // mild|moderate|severe

    if (!_apiReady || _loadingId || _patientId == null || allergen.isEmpty || reaction.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    // map UI -> enum string
    String severityEnum;
    switch (sevUi) {
      case 'moderate':
        severityEnum = 'MODERATE';
        break;
      case 'severe':
        severityEnum = 'SEVERE';
        break;
      default:
        severityEnum = 'MILD';
    }

    try {
      await _api.createAllergy(
        patientId: _patientId!,
        allergen: allergen,
        allergyType: 'DRUG',     // only drugs for now
        severity: severityEnum,  // enum string
        reaction: reaction,
        isActive: true,
      );

      widget.onAllergyAdded?.call({
        'allergen': allergen,
        'reaction': reaction,
        'severity': severityEnum,
        'allergyType': 'DRUG',
        'note': 'Added ${DateTime.now().toString().split(' ').first}',
      });

      _drugController.clear();
      _reactionController.clear();
      setState(() => _selectedSeverity = 'Mild (Minor symptoms)');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Drug allergy added successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to add allergy: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _loadingId || _patientId == null;

    // static list for dropdown
    final severities = const <String>[
      'Mild (Minor symptoms)',
      'Moderate (Noticeable symptoms)',
      'Severe (Life-threatening)',
    ];

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
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);

                    // Patient ID is loaded before using AI
                    if (_patientId == null) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Please wait, loading your profile...')),
                      );
                      return;
                    }

                    // Record voice to text
                    final transcript = await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                        builder: (_) => const VoiceCommandAI(singleShot: true),
                        fullscreenDialog: true,
                      ),
                    );

                    if (!mounted) return;
                    if (transcript == null || transcript.trim().isEmpty) return;

                    // Fill reaction as fallback
                    setState(() {
                      _reactionController.text = transcript.trim();
                    });

                    // Send to DeepSeek AI
                    try {
                      setState(() => _usingAi = true);

                      final ai = await DeepseekService.extractAllergy(
                        patientId: _patientId!,
                        transcript: transcript.trim(),
                        allergen: _drugController.text.trim().isEmpty
                            ? null
                            : _drugController.text.trim(),
                        severity: null,
                        reaction: _reactionController.text.trim().isNotEmpty
                            ? _reactionController.text.trim()
                            : null,
                      );

                      _applyAiResult(ai);

                      messenger.showSnackBar(
                        const SnackBar(content: Text('✅ AI filled the fields')),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('⚠️ AI could not parse. You can edit manually. ($e)')),
                      );
                    } finally {
                      if (mounted) setState(() => _usingAi = false);
                    }
                  },
                  icon: const Icon(Icons.mic, size: 16),
                  label: _usingAi ? const Text('Analyzing...') : const Text('Use AI Voice'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),

          if (disabled)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: const [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Preparing…'),
              ],
            ),
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
              onPressed: disabled ? null : _submitAllergy,
              icon: const Icon(Icons.add),
              label: const Text('Add Drug Allergy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
