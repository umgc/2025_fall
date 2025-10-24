import 'package:flutter/material.dart';
import 'tracker.dart';

class MedicationsView extends StatelessWidget {
  final List<String> items;
  const MedicationsView({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medications'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Current Medications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...items.map(_pill),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Recent activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (Tracker.meds.isEmpty) const Text('No recent entries'),
          ...Tracker.meds.map((r) => ListTile(leading: const Icon(Icons.history), title: Text(r))),
        ],
      ),
    );
  }

  Widget _pill(String text) => Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFFAFBFF), borderRadius: BorderRadius.circular(12)),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}
