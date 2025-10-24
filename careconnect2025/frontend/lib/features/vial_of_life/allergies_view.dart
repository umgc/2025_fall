import 'package:flutter/material.dart';
import 'tracker.dart';

class AllergiesView extends StatelessWidget {
  final List<String> critical;
  final List<String> caution;
  const AllergiesView({super.key, required this.critical, required this.caution, required List<String> items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Allergies'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Critical', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...critical.map((a) => _chip(a, const Color(0xFFFFEDED))),
          const SizedBox(height: 16),
          const Text('Caution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...caution.map((a) => _chip(a, const Color(0xFFFFF4E5))),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Recent activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (Tracker.allergies.isEmpty) const Text('No recent entries'),
          ...Tracker.allergies.map((r) => ListTile(leading: const Icon(Icons.history), title: Text(r))),
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg) => Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}
