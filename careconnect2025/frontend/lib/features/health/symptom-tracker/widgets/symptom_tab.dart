import 'package:flutter/material.dart';
import 'symptom_input_form.dart';
import 'symptom_card.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class SymptomTab extends StatefulWidget {
  const SymptomTab({Key? key}) : super(key: key);

  @override
  State<SymptomTab> createState() => _SymptomTabState();
}

class _SymptomTabState extends State<SymptomTab> {

  final String baseUrl = 'https://localhost:8080/v1/api/symptoms';

  late List<Map<String, dynamic>> _symptoms;

  @override
  void initState() {
    super.initState();
    _symptoms = []; // pulls from wherever your backend or input provides it
    _fetchSymptoms();
  }

  // Function to add symptoms
  Future<void> _addSymptom(Map<String, dynamic> symptomData) async {
    try {
      final patientId = 1; // 🔸 Replace with logged-in patient ID
      final body = jsonEncode({
        'patientId': patientId,
        'symptomKey': symptomData['title'],
        'symptomValue': symptomData['description'],
        'severity': symptomData['severity'],
      });

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          _symptoms.insert(0, {
            'id': data['id'],
            'title': data['symptomKey'] ?? '',
            'severity': data['severity'] ?? 'Unknown',
            'time': data['takenAt'] ?? '',
            'description': data['symptomValue'] ?? '',
            'requiresAttention': false,
            'caregiverAlert': false,
          });
        });
      } else {
        print('Failed to add symptom: ${response.body}');
      }
    } catch (e) {
      print('Error adding symptom: $e');
    }
  }


  // Function to remove a symptom at a given index
  Future<void> _removeSymptom(int index) async {
    final symptom = _symptoms[index];
    final id = symptom['id'];

    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      if (response.statusCode == 200) {
        setState(() {
          _symptoms.removeAt(index);
        });
      } else {
        print('Failed to delete symptom: ${response.body}');
      }
    } catch (e) {
      print('Error deleting symptom: $e');
    }
  }



  // Fetch all symptoms for this patient
  Future<void> _fetchSymptoms() async {
    try {
      final patientId = 1; // 🔸 Replace with logged-in patient ID
      final response = await http.get(Uri.parse('$baseUrl/patient/$patientId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['data'] ?? [];
        setState(() {
          _symptoms.clear();
          _symptoms.addAll(list.map((s) => {
                'id': s['id'],
                'title': s['symptomKey'] ?? '',
                'severity': s['severity'] ?? 'Unknown',
                'time': s['takenAt'] ?? '',
                'description': s['symptomValue'] ?? '',
                'requiresAttention': false,
                'caregiverAlert': false,
              }));
        });
      } else {
        print('Failed to fetch symptoms: ${response.body}');
      }
    } catch (e) {
      print('Error fetching symptoms: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input form to add new symptoms
          SymptomInputForm(onSymptomAdded: _addSymptom),
          const SizedBox(height: 24),
          // Title for the recent symptoms section
          Text(
            'Recent Mental Health Symptoms',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          // Display list of symptoms with delete option
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _symptoms.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final symptom = _symptoms[index];
              return SymptomCard(
                title: symptom['title'],
                severity: symptom['severity'],
                time: symptom['time'],
                description: symptom['description'],
                requiresAttention: symptom['requiresAttention'],
                caregiverAlert: symptom['caregiverAlert'],
                // Pass the delete callback to the SymptomCard
                onDelete: () => _removeSymptom(index),
              );
            },
          ),
        ],
      ),
    );
  }
}
