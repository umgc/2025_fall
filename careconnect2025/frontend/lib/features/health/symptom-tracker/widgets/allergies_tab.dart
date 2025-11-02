import 'package:care_connect_app/features/health/symptom-tracker/widgets/allergies_input_form.dart';
import 'package:flutter/material.dart';
import 'allergies_card.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class AllergiesTab extends StatefulWidget {
  const AllergiesTab({super.key});

  @override
  State<AllergiesTab> createState() => _AllergiesTabState();
}

final String baseUrl = 'https://localhost:8080/v1/api/allergies';


class _AllergiesTabState extends State<AllergiesTab> {
  
  @override
  void initState() {
    super.initState();
    _fetchAllergies();
  }

  // fetch from backend
  Future<void> _fetchAllergies() async {
    try {
      final patientId = 1; // 🔸 Replace with actual logged-in patient ID
      final response = await http.get(Uri.parse('$baseUrl/patient/$patientId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['data'] ?? [];
        setState(() {
          _allergies.clear();
          _allergies.addAll(list.map((a) => {
                'id': a['id'],
                'drug': a['allergen'],
                'severity': a['severity'] ?? 'Unknown',
                'reaction': a['reaction'] ?? '',
                'note': a['notes'] ?? '',
              }));
        });
      } else {
        print('Failed to fetch allergies: ${response.body}');
      }
    } catch (e) {
      print('Error fetching allergies: $e');
    }
  }

  final List<Map<String, dynamic>> _allergies = []; // dynamically managed list

  Future<void> _addAllergy(Map<String, dynamic> allergyData) async {
    try {
      final patientId = 1; // 🔸 Replace with actual logged-in patient ID
      final body = jsonEncode({
        'patientId': patientId,
        'allergen': allergyData['drug'],
        'severity': allergyData['severity'],
        'reaction': allergyData['reaction'],
        'notes': allergyData['note'],
        'isActive': true
      });

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          _allergies.insert(0, {
            'id': data['id'],
            'drug': data['allergen'],
            'severity': data['severity'] ?? 'Unknown',
            'reaction': data['reaction'] ?? '',
            'note': data['notes'] ?? '',
          });
        });
      } else {
        print('Failed to add allergy: ${response.body}');
      }
    } catch (e) {
      print('Error adding allergy: $e');
    }
  }
  

  Future<void> _removeAllergy(int index) async {
    final allergy = _allergies[index];
    final id = allergy['id'];

    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      if (response.statusCode == 200) {
        setState(() {
          _allergies.removeAt(index);
        });
      } else {
        print('Failed to delete allergy: ${response.body}');
      }
    } catch (e) {
      print('Error deleting allergy: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AllergyInputForm(onAllergyAdded: _addAllergy),
          const SizedBox(height: 24),
          Text(
            'Known Drug Allergies',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allergies.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final allergy = _allergies[index];
              return AllergyCard(
                drug: allergy['drug'],
                severity: allergy['severity'],
                reaction: allergy['reaction'],
                note: allergy['note'],
                onDelete: () => _removeAllergy(index), // ✅ delete on X
              );
            },
          ),
        ],
      ),
    );
  }
}
