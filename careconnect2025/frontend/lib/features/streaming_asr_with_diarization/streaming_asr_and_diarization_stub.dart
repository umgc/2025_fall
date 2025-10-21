import 'package:flutter/material.dart';

import '../../services/enhanced_file_service.dart';

class StreamingAsrAndDiarizationScreen extends StatelessWidget {
  final int? patientId;
  final Function(FileUploadResponse)? onUploadSuccess;
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
