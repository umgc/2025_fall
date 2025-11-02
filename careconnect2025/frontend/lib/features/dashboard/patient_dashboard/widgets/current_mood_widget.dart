import 'package:flutter/material.dart';
import 'package:care_connect_app/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:care_connect_app/providers/user_provider.dart';


/// Current Mood Widget
class CurrentMoodWidget extends StatefulWidget {
  final int moodScore;
  final String moodLabel;
  final List<String> moodTags;
  final DateTime? date;

  const CurrentMoodWidget({
    super.key,
    required this.moodScore,
    required this.moodLabel,
    required this.moodTags,
    this.date,
  });

  @override
  State<CurrentMoodWidget> createState() => _CurrentMoodWidgetState();
}

class _CurrentMoodWidgetState extends State<CurrentMoodWidget> {
  late int currentMoodScore;
  late String currentMoodLabel;
  List<Map<String, dynamic>> moodHistory = [];


  @override
  void initState() {
    super.initState();
    currentMoodScore = widget.moodScore;
    currentMoodLabel = widget.moodLabel;
    _loadMoodHistory();
  }

  /// Gets the mood emoji based on the mood score
  String _getMoodEmoji(int score) {
    if (score == 10) return '🤩'; // ecstatic, blissful
    if (score == 9) return '😁';  // big happy grin
    if (score == 8) return '😄';  // joyful
    if (score == 7) return '😊';  // warm, content
    if (score == 6) return '🙂';  // slightly happy
    if (score == 5) return '😐';  // neutral
    if (score == 4) return '😕';  // uncertain, mild discontent
    if (score == 3) return '🙁';  // a bit sad
    if (score == 2) return '☹️'; // clearly sad
    if (score == 1) return '😞';  // disappointed
    return '😔';                  // 0 — deeply sad/depressed
  }

  /// Gets a readable mood label
  String _getMoodLabel(int score) {
    if (score >= 9) return 'Ecstatic';
    if (score >= 7) return 'Happy';
    if (score >= 5) return 'Okay';
    if (score >= 3) return 'Down';
    return 'Sad';
  }

  /// Optional placeholder for alerts — add your real logic here
  void _checkForAlerts() {
    // Implement alert logic if needed
  }

  /// Formats the date into a friendly string
  String _formatDate(DateTime date) {
    final now = DateTime.now().toUtc();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}';
    }
  }



      Future<void> _loadMoodHistory() async {
        final user = Provider.of<UserProvider>(context, listen: false).user;

        try {
          // Fetch moods from backend
          final response = await ApiService.getMoodHistory(user?.id ?? 0);
          setState(() {
            moodHistory = response
                .map<Map<String, dynamic>>((entry) => {
                      'score': entry['score'],
                      'label': entry['label'],
                      'date': DateTime.parse(entry['createdAt']),
                    })
                .toList();
          });
        } catch (e) {
          print('❌ Error loading mood history: $e');
        }
      }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = widget.date == null ? 'Today' : _formatDate(widget.date!);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite_outline,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Current Mood',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                _getMoodEmoji(currentMoodScore),
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$currentMoodScore/10',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    currentMoodLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                dateLabel,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Mood slider and Save button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rate how you feel right now:',
                  style: theme.textTheme.titleMedium,
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbColor: Colors.white,
                    overlayColor: theme.colorScheme.primary.withOpacity(0.2),
                    trackShape: const GradientRectSliderTrackShape(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue,
                          Colors.yellow,
                        ],
                      ),
                    ),
                  ),
                  child: Slider(
                    value: currentMoodScore.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: '$currentMoodScore',
                    onChanged: (double newValue) {
                      setState(() {
                        currentMoodScore = newValue.round();
                        currentMoodLabel = _getMoodLabel(currentMoodScore);
                      });
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Mood'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    
                    onPressed: () async {
                      try {
                        final user = Provider.of<UserProvider>(context, listen: false).user;
                        await ApiService.saveMoodScore(
                          userId: user?.id ?? 0,
                          score: currentMoodScore,
                          label: currentMoodLabel,
                        );

                        setState(() {
                          moodHistory.insert(0, {
                            'score': currentMoodScore,
                            'label': currentMoodLabel,
                            'date': DateTime.now().toUtc(),
                          });
                        });

                        _checkForAlerts();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mood saved successfully'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error saving mood: $e'),
                            backgroundColor: theme.colorScheme.error,
                          ),
                        );
                      }
                    },

                  ),
                ),
              ],
            ),
          ),

          if (moodHistory.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Mood Tracker',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Column(
              children: moodHistory.map((entry) {
                final date = entry['date'] as DateTime;
                final score = entry['score'];
                final label = entry['label'];
                return ListTile(
                  leading: Text(
                    _getMoodEmoji(score),
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text('$score/10  —  $label'),
                  subtitle: Text(_formatDate(date)),
                );
              }).toList(),
            ),
          ],


          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.moodTags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Gradient track for mood slider
class GradientRectSliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  const GradientRectSliderTrackShape({required this.gradient});
  final LinearGradient gradient;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4.0;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackRight = trackLeft + parentBox.size.width;
    final double trackBottom = trackTop + trackHeight;
    final Rect trackRect =
        Rect.fromLTRB(trackLeft, trackTop, trackRight, trackBottom);

    final Paint paint = Paint()
      ..shader = gradient.createShader(trackRect)
      ..style = PaintingStyle.fill;

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, const Radius.circular(3)),
      paint,
    );
  }
}
