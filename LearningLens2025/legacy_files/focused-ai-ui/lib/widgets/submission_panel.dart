// lib/widgets/submission_panel.dart
import 'package:flutter/material.dart';

class SubmissionPanel extends StatelessWidget {
  final String submission;

  const SubmissionPanel({super.key, required this.submission});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2d5a2d), Color(0xFF3d6a3d)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Student Submission',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: submission.isEmpty
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Select a submission to view content',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Use the navigation panel to select a course, assignment, and submission to begin the comparison analysis.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              height: 1.6,
                            ),
                            children: [
                              const TextSpan(
                                text: 'The Ethics of Artificial Intelligence in Education\n\n',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed at nisl nec libero luctus cursus. Nullam vehicula magna non purus suscipit, in viverra ipsum elementum. ',
                              ),
                              TextSpan(
                                text: 'Morbi et tincidunt ligula. Sed vestibulum ex vitae urna posuere, vitae feugiat turpis malesuada.',
                                style: const TextStyle(
                                  backgroundColor: Color(0xFFFFEB3B),
                                ),
                              ),
                              const TextSpan(
                                text: ' Suspendisse potenti.\n\n',
                              ),
                              TextSpan(
                                text: 'Aliquam erat volutpat. ',
                              ),
                              TextSpan(
                                text: 'Aenean fringilla nulla nec velit sagittis, sed posuere sem pharetra. Praesent blandit velit vitae velit dictum dapibus.',
                                style: const TextStyle(
                                  backgroundColor: Color(0xFFFFEB3B),
                                ),
                              ),
                              const TextSpan(
                                text: ' Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Proin eget libero ac justo laoreet varius.\n\n',
                              ),
                              TextSpan(
                                text: 'Integer vel orci risus. Duis et risus vel neque fermentum facilisis. Quisque tristique feugiat lectus, ut mattis ex vehicula ac. ',
                              ),
                              TextSpan(
                                text: 'Vestibulum eget viverra elit. Curabitur a justo tempor, ultrices lorem nec, congue velit. Aenean volutpat vitae arcu sed varius.',
                                style: const TextStyle(
                                  backgroundColor: Color(0xFFFFEB3B),
                                ),
                              ),
                              const TextSpan(
                                text: '\n\nIn conclusion, the integration of AI in educational settings presents both opportunities and challenges that must be carefully considered. The ethical implications of using AI tools for learning assistance require ongoing dialogue between educators, students, and technology developers.',
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}