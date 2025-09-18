import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme/careconnect_theme.dart';
import '../widgets/careconnect_card.dart';
import '../widgets/careconnect_button.dart';
import '../providers/app_state_provider.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  double _moodRating = 5.0;
  double _painRating = 1.0;
  double _energyRating = 5.0;
  double _sleepRating = 5.0;
  String _notes = '';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _moodEmojis = [
    {'emoji': '😢', 'label': 'Terrible', 'value': 1.0},
    {'emoji': '😔', 'label': 'Poor', 'value': 2.0},
    {'emoji': '😐', 'label': 'Fair', 'value': 3.0},
    {'emoji': '😊', 'label': 'Good', 'value': 4.0},
    {'emoji': '😄', 'label': 'Excellent', 'value': 5.0},
  ];

  final List<Map<String, dynamic>> _painEmojis = [
    {'emoji': '😌', 'label': 'No Pain', 'value': 1.0},
    {'emoji': '😕', 'label': 'Mild', 'value': 2.0},
    {'emoji': '😣', 'label': 'Moderate', 'value': 3.0},
    {'emoji': '😖', 'label': 'Severe', 'value': 4.0},
    {'emoji': '😫', 'label': 'Very Severe', 'value': 5.0},
  ];

  final List<Map<String, dynamic>> _energyEmojis = [
    {'emoji': '😴', 'label': 'Very Low', 'value': 1.0},
    {'emoji': '😑', 'label': 'Low', 'value': 2.0},
    {'emoji': '😐', 'label': 'Moderate', 'value': 3.0},
    {'emoji': '😊', 'label': 'High', 'value': 4.0},
    {'emoji': '⚡', 'label': 'Very High', 'value': 5.0},
  ];

  final List<Map<String, dynamic>> _sleepEmojis = [
    {'emoji': '😵', 'label': 'Very Poor', 'value': 1.0},
    {'emoji': '😴', 'label': 'Poor', 'value': 2.0},
    {'emoji': '😑', 'label': 'Fair', 'value': 3.0},
    {'emoji': '😊', 'label': 'Good', 'value': 4.0},
    {'emoji': '😴', 'label': 'Excellent', 'value': 5.0},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareConnectTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Daily Check-in'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<AppStateProvider>().setCurrentTab('home');
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CareConnectTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              
              const SizedBox(height: CareConnectTheme.spacingXL),
              
              // Mood Slider
              _buildEmojiSlider(
                'How is your mood today?',
                _moodEmojis,
                _moodRating,
                (value) => setState(() => _moodRating = value),
              ),
              
              const SizedBox(height: CareConnectTheme.spacingXL),
              
              // Pain Level Slider
              _buildEmojiSlider(
                'What is your pain level?',
                _painEmojis,
                _painRating,
                (value) => setState(() => _painRating = value),
              ),
              
              const SizedBox(height: CareConnectTheme.spacingXL),
              
              // Energy Level Slider
              _buildEmojiSlider(
                'How is your energy level?',
                _energyEmojis,
                _energyRating,
                (value) => setState(() => _energyRating = value),
              ),
              
              const SizedBox(height: CareConnectTheme.spacingXL),
              
              // Sleep Quality Slider
              _buildEmojiSlider(
                'How was your sleep last night?',
                _sleepEmojis,
                _sleepRating,
                (value) => setState(() => _sleepRating = value),
              ),
              
              const SizedBox(height: CareConnectTheme.spacingXL),
              
              // Notes
              _buildNotesSection(),
              
              const SizedBox(height: CareConnectTheme.spacingXL),
              
              // Submit button
              _buildSubmitButton(),
              
              const SizedBox(height: CareConnectTheme.spacingXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are you feeling today?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: CareConnectTheme.primaryColor,
          ),
        ),
        const SizedBox(height: CareConnectTheme.spacingS),
        Text(
          'Your daily check-in helps us track your health and provide better care.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: CareConnectTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiSlider(
    String question,
    List<Map<String, dynamic>> emojis,
    double currentValue,
    Function(double) onChanged,
  ) {
    return CareConnectCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: CareConnectTheme.spacingL),
          
          // Current emoji display
          Center(
            child: Container(
              padding: const EdgeInsets.all(CareConnectTheme.spacingL),
              decoration: BoxDecoration(
                color: CareConnectTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                _getCurrentEmoji(emojis, currentValue),
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ),
          
          const SizedBox(height: CareConnectTheme.spacingM),
          
          // Current label
          Center(
            child: Text(
              _getCurrentLabel(emojis, currentValue),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: CareConnectTheme.primaryColor,
              ),
            ),
          ),
          
          const SizedBox(height: CareConnectTheme.spacingL),
          
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: CareConnectTheme.primaryColor,
              inactiveTrackColor: CareConnectTheme.primaryColor.withOpacity(0.2),
              thumbColor: CareConnectTheme.primaryColor,
              overlayColor: CareConnectTheme.primaryColor.withOpacity(0.2),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: currentValue,
              min: 1.0,
              max: 5.0,
              divisions: 4,
              onChanged: onChanged,
            ),
          ),
          
          const SizedBox(height: CareConnectTheme.spacingM),
          
          // Emoji labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: emojis.map((emoji) => Column(
              children: [
                Text(
                  emoji['emoji'],
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  emoji['label'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: CareConnectTheme.textSecondary,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return CareConnectCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Notes (Optional)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: CareConnectTheme.spacingM),
          TextField(
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Share any additional thoughts or concerns...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _notes = value,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitCheckIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: CareConnectTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: CareConnectTheme.spacingL),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Submit Check-in',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  String _getCurrentEmoji(List<Map<String, dynamic>> emojis, double value) {
    final index = (value - 1).round();
    return emojis[index]['emoji'];
  }

  String _getCurrentLabel(List<Map<String, dynamic>> emojis, double value) {
    final index = (value - 1).round();
    return emojis[index]['label'];
  }

  Future<void> _submitCheckIn() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in submitted successfully!'),
          backgroundColor: CareConnectTheme.successColor,
        ),
      );
      
      // Navigate back to home
      context.read<AppStateProvider>().setCurrentTab('home');
    }
  }
}
