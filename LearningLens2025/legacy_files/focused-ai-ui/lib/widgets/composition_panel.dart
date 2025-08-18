// lib/widgets/composition_panel.dart
import 'package:flutter/material.dart';

class CompositionPanel extends StatelessWidget {
  final String submission;

  // Example composition breakdown data
  final List<Map<String, dynamic>> compositionBreakdown;

  const CompositionPanel({
    super.key,
    required this.submission,
    this.compositionBreakdown = const [
      {
        'type': 'human-written',
        'section': 'Introduction',
        'confidence': '95%',
        'details': 'This section is mostly written by the student.',
        'wordCount': 120,
      },
      {
        'type': 'ai-assisted',
        'section': 'Body Paragraph 1',
        'confidence': '80%',
        'details': 'Some AI assistance detected in phrasing.',
        'wordCount': 200,
      },
      {
        'type': 'ai-generated',
        'section': 'Conclusion',
        'confidence': '60%',
        'details': 'Significant AI-generated content detected.',
        'wordCount': 100,
      },
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
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
                  const Icon(Icons.analytics, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Writing Composition Breakdown',
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
                    ? const Center(
                        child: Text(
                          'Composition analysis will appear here once a submission is selected.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2d5a2d).withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Report:',
                                    style: TextStyle(
                                      color: Color(0xFF2d5a2d),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Writing Composition Breakdown:',
                                    style: TextStyle(
                                      color: Color(0xFF2d5a2d),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMetricRow('Student written:', '86%'),
                                  _buildMetricRow('AI generated:', '14%'),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'AI Use Assessment:',
                                    style: TextStyle(
                                      color: Color(0xFF2d5a2d),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'The student appears to have used AI selectively to assist with smoother phrasing or structure. Usage is within acceptable bounds for drafting support.',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...compositionBreakdown.map((item) {
                              Color borderColor;
                              Color bgColor;
                              
                              if (item['type'] == 'human-written') {
                                borderColor = const Color(0xFF28a745);
                                bgColor = const Color(0xFF28a745).withOpacity(0.1);
                              } else if (item['type'] == 'ai-assisted') {
                                borderColor = const Color(0xFFffc107);
                                bgColor = const Color(0xFFffc107).withOpacity(0.1);
                              } else {
                                borderColor = const Color(0xFFdc3545);
                                bgColor = const Color(0xFFdc3545).withOpacity(0.1);
                              }
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border(
                                    left: BorderSide(
                                      color: borderColor,
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item['section'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            item['confidence'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: borderColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['details'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${item['wordCount']} words',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d5a2d),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}