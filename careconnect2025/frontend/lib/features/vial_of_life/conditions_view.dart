import 'package:flutter/material.dart';
import 'tracker.dart';

class ConditionsView extends StatelessWidget {
  final List<String> items;
  const ConditionsView({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medical Conditions'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Conditions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: items.map(_tag).toList(),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Recent activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (Tracker.conditions.isEmpty) const Text('No recent entries'),
          ...Tracker.conditions.map((r) => ListTile(leading: const Icon(Icons.history), title: Text(r))),
        ],
      ),
    );
  }

  Widget _tag(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: const Color(0xFFEAF0FF), borderRadius: BorderRadius.circular(12)),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2E5AAC))),
  );
}
