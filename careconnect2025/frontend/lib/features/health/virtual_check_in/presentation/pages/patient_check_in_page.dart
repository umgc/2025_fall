import 'dart:io';

import 'package:care_connect_app/widgets/app_bar_helper.dart';
import 'package:care_connect_app/widgets/default_app_header.dart';
import 'package:care_connect_app/widgets/video_widget.dart';
import 'package:flutter/material.dart';
import 'package:care_connect_app/pages/patient_check_in.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

class PatientVirtualCheckIn extends StatefulWidget {
  const PatientVirtualCheckIn({super.key});

  @override
  State<PatientVirtualCheckIn> createState() => _PatientVirtualCheckInState();
}

class _PatientVirtualCheckInState extends State<PatientVirtualCheckIn> {
  int? selectedMood;
  final TextEditingController _notesController = TextEditingController();
  final String apiURL = "placeholder";
  late Future<VideoWidget> videoWidget;
  late bool showVideoCall = false;
  late bool currentlyRecording = false;
  late bool recordingStarted = false;
  late Future<CameraDescription> targetCamera;
  late CameraController controller;
  final List<Map<String, dynamic>> moodOptions = [
    {"value": 1, "emoji": "😢", "label": "Very Sad"},
    {"value": 2, "emoji": "😞", "label": "Sad"},
    {"value": 3, "emoji": "😐", "label": "Neutral"},
    {"value": 4, "emoji": "🙂", "label": "Good"},
    {"value": 5, "emoji": "😊", "label": "Great"},
  ];

  late bool videoCallActive = false;
  bool isCameraAvailable = false;
  bool isCheckingCamera = true;

  @override
  void initState() {
    super.initState();
    _checkCameraAvailability();
  }

  Future<void> _checkCameraAvailability() async {
    try {
      final cameras = await availableCameras();
      setState(() {
        isCameraAvailable = cameras.isNotEmpty;
        isCheckingCamera = false;
      });
    } catch (e) {
      setState(() {
        isCameraAvailable = false;
        isCheckingCamera = false;
      });
      print('Error checking camera availability: $e');
    }
  }

  Future<CameraDescription> setUpCamera() async
  {
    WidgetsFlutterBinding.ensureInitialized();
    final cameras = await availableCameras();
    return cameras.first;
  }

  void cameraHandler() async
  {
    if(!videoCallActive)
      {
        targetCamera = setUpCamera();
        videoCallActive = true;
        controller = CameraController(await targetCamera, ResolutionPreset.medium);

        // Initialize the camera controller
        await controller.initialize();

        if (mounted) {
          setState(() {
            showVideoCall = true;
          });
        }
      }
  }

  Future<void> startRecording() async
  {
    if(!recordingStarted)
      {
        controller.startVideoRecording();
      }
    else
      {
        controller.resumeVideoRecording();
      }
    recordingStarted = true;
    setState(() {
      currentlyRecording = true;
    });
  }

  Future<void> pauseRecording() async
  {
    controller.pauseVideoRecording();
    setState(() {
      currentlyRecording = false;
    });
  }

  void submitVideo() async {
    // TODO: Implement video submission logic
    // This is where you would upload/save the video recording
    if(!recordingStarted)
      {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cannot submit, no video recorded."),
            backgroundColor: Colors.grey,
          ),
        );
        return;
      }

    XFile video = await controller.stopVideoRecording();
    await http.post(Uri.parse(apiURL)); ///TODO: Add a proper body that includes XFile Video

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Video submitted successfully! (placeholder)"),
        backgroundColor: Colors.green,
      ),
    );

    // Close the video recording
    setState(() {
      currentlyRecording = false;
      showVideoCall = false;
      videoCallActive = false;
    });
  }

  void discardVideo() async {
    // Close the video recording without saving
    setState(() {
      currentlyRecording = false;
      showVideoCall = false;
      videoCallActive = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Video discarded"),
        backgroundColor: Colors.grey,
      ),
    );
  }

  ///Done: Add a pause/start functionality
  ///TODO: Add a preview
  ///Done: Control the camera with code
  ///TODO: Submit video file

  @override
  Widget build(BuildContext context)  {
    return Scaffold(
      appBar: DefaultAppHeader(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isCameraAvailable ? Colors.green : Colors.grey,
        foregroundColor: Colors.white,
        onPressed: (isCheckingCamera || !isCameraAvailable) ? null : () => cameraHandler(),
        tooltip: isCheckingCamera
            ? 'Checking camera...'
            : (isCameraAvailable
                ? 'Start Video Call'
                : 'Camera not available'),
        child: isCheckingCamera
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                isCameraAvailable ? Icons.video_call : Icons.videocam_off,
              ),
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
                  if (!isCheckingCamera && !isCameraAvailable)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Camera not available - Video recording disabled',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),

              // Video call widget
              if(showVideoCall)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const VideoWidget(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: discardVideo,
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Discard'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: submitVideo,
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Submit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            if(!currentlyRecording)
                              Expanded(
                              child: ElevatedButton.icon(
                              label: Text("Start"),
                              onPressed: startRecording,
                              icon: const Icon(Icons.square),
                              style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              ),
                              ),
                            if(currentlyRecording)
                              Expanded(
                                child: ElevatedButton.icon(
                                  label: const Text("Pause"),
                                  onPressed: pauseRecording,
                                  icon: const Icon(Icons.pause),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),],
                        ),
                      ],
                    ),
                  ),
                ),
              if(showVideoCall)
                const SizedBox(height: 16),

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
                ),
            ],
          ),
        ),
      ),
    );
  }
}