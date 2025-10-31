import 'dart:io';

import 'package:care_connect_app/features/health/symptom-tracker/widgets/allergies_tab.dart';
import 'package:care_connect_app/widgets/default_app_header.dart';
import 'package:care_connect_app/features/health/symptom-tracker/widgets/symptom_tab.dart';
import 'package:flutter/material.dart';

class SymptomsAllergiesPage extends StatefulWidget {
  const SymptomsAllergiesPage({super.key});

  @override
  State<SymptomsAllergiesPage> createState() => _SymptomsAllergiesPageState();
}

class _SymptomsAllergiesPageState extends State<SymptomsAllergiesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const DefaultAppHeader(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).shadowColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.medical_information_outlined,
                            color: Theme.of(context).primaryColor,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Symptoms & Allergies',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Track your health symptoms and medication allergies',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicator: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey[600],
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              tabs: const [
                                Tab(text: 'Mental Health\nSymptoms'),
                                Tab(text: 'Drug Allergies'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: const [SymptomTab(), AllergiesTab()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SymptomEntry {
  final String symptom;
  final double severity;
  final DateTime timestamp;
  final File? image;

  SymptomEntry({
    required this.symptom,
    required this.severity,
    required this.timestamp,
    this.image,
  });
}
