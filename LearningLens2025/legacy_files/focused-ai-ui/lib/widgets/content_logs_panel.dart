// lib/widgets/logs_panel.dart
import 'package:flutter/material.dart';

class LogsPanel extends StatelessWidget {
  final String submission;

  // Sample logs for demonstration purposes
  static List<Map<String, dynamic>> get _sampleLogs => [
    {
      'timestamp': '2024-06-01 10:15',
      'type': 'student',
      'content': 'I started my essay by outlining the main points.',
      'matched': false,
      'similarity': null,
    },
    {
      'timestamp': '2024-06-01 10:17',
      'type': 'ai',
      'content': 'Consider rephrasing this section for clarity.',
      'matched': false,
      'similarity': '85%',
    },
    {
      'timestamp': '2024-06-01 10:20',
      'type': 'student',
      'content': 'I revised the introduction as suggested.',
      'matched': true,
      'similarity': '92%',
    },
  ];

  const LogsPanel({super.key, required this.submission});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                const Icon(Icons.chat, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'AI Chat Logs & Analysis',
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
                        'AI chat logs will appear here once a submission is selected.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  '📊 Analysis Summary',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildMetric('86%', 'Student Written'),
                                    _buildMetric('14%', 'AI Generated'),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Assessment: The student appears to have used AI selectively for phrasing and structure assistance. Usage is within acceptable bounds for drafting support.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._sampleLogs.map((log) {
                            Color borderColor;
                            Color bgColor;
                            
                            if (log['matched'] == true) {
                              borderColor = const Color(0xFFFFC107);
                              bgColor = const Color(0xFFFFC107).withOpacity(0.1);
                            } else if (log['type'] == 'ai') {
                              borderColor = const Color(0xFF4A90E2);
                              bgColor = const Color(0xFF4A90E2).withOpacity(0.1);
                            } else {
                              borderColor = const Color(0xFF2d5a2d);
                              bgColor = const Color(0xFF2d5a2d).withOpacity(0.05);
                            }
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
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
                                    children: [
                                      Text(
                                        log['timestamp'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      if (log['similarity'] != null)
                                        Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F5E8),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${log['similarity']} match',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF2d5a2d),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    log['content'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
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
    );
  }

  Widget _buildMetric(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2d5a2d),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}