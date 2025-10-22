import 'package:flutter/material.dart';

import '../../services/enhanced_file_service.dart';
import '../notetaker/models/patient_note_model.dart';

class StreamingAsrAndDiarizationScreen extends StatelessWidget {
  final String? patientId;
  final Function(PatientNote)? onUploadSuccess;
  final Function(String)? onUploadError;

  const StreamingAsrAndDiarizationScreen({
    super.key,
    this.patientId,
    this.onUploadSuccess,
    this.onUploadError,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Speech-to-Text with Diarization is not available on Web.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
