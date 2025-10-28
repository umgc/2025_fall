import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UpcomingCheckins extends StatelessWidget {
  const UpcomingCheckins({super.key});

  @override
  Widget build(BuildContext context) {
    final patients = [
      {'name': 'Sarah Johnson', 'date': '12/28/2024 at 10:00 AM'},
      {'name': 'Robert Chen', 'date': '12/28/2024 at 2:30 PM'},
      {'name': 'Maria Rodriguez', 'date': '12/29/2024 at 9:15 AM'},
      {'name': 'David Thompson', 'date': '12/29/2024 at 11:45 AM'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Upcoming Check-Ins',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...patients.map(
            (patient) => _PatientCheckInItem(
              name: patient['name']!,
              date: patient['date']!,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            
            child: TextButton(
             onPressed: () => context.push('/tasks'),
              child: const Text(
                'View All Patients',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () => context.push('/evv/select-patient'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Start EV Session',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientCheckInItem extends StatelessWidget {
  final String name;
  final String date;

  const _PatientCheckInItem({required this.name, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('View')),
        ],
      ),
    );
  }
}
