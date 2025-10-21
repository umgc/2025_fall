import 'package:care_connect_app/widgets/app_bar_helper.dart';
import 'package:flutter/material.dart';
import 'package:care_connect_app/pages/patient_check_in.dart';
import 'package:camera/camera.dart';

//TODO: Connect VideoWidget to this class via a button
class PatientVirtualCheckIn extends StatefulWidget {
  const PatientVirtualCheckIn({super.key});

  @override
  State<PatientVirtualCheckIn> createState() => _PatientVirtualCheckInState();
}

class _PatientVirtualCheckInState extends State<PatientVirtualCheckIn> {
  int? selectedMood;
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, dynamic>> moodOptions = [
    {"value": 1, "emoji": "😢", "label": "Very Sad"},
    {"value": 2, "emoji": "😞", "label": "Sad"},
    {"value": 3, "emoji": "😐", "label": "Neutral"},
    {"value": 4, "emoji": "🙂", "label": "Good"},
    {"value": 5, "emoji": "😊", "label": "Great"},
  ];

  Future<CameraDescription> setUpCamera() async
  {
    WidgetsFlutterBinding.ensureInitialized();
    final cameras = await availableCameras();
    return cameras.first;
  }

  @override
  Widget build(BuildContext context) {
    ///I think this is where this goes? Change this to a var
    setUpCamera();
    return Scaffold(
      appBar: AppBarHelper.createAppBar(
        context,
        title: 'Daily Check-In',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    "💙 Daily Check-In",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Share how you're feeling today",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

              // Mood selection card
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "How are you feeling today?",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600]),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 5,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        children: moodOptions.map((mood) {
                          final isSelected = selectedMood == mood["value"];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedMood = mood["value"];
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).cardColor,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    mood["emoji"],
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    mood["label"],
                                    style: const TextStyle(fontSize: 12),
                                    textAlign: TextAlign.center,
                                  )
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Symptoms/notes card
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Any symptoms or notes?",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600]),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText:
                              "Describe any symptoms, feelings, or important notes...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Share any symptoms, medication effects, or general notes about your day",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedMood == null
                      ? null
                      : () {
                          // Mock submit
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Check-in submitted (mock)!")),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue[400],
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: const Text(
                    "Submit Check-In",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (selectedMood == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    "Please select your mood to submit your check-in",
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}