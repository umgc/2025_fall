import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// ⚠️ This version of AIFileService is currently set up to use OpenAI GPT API.
/// To switch back to HuggingFace, revert model name and API key env var in each method.
class AIFileService {
  /// Extracts plain text from an in-memory PDF (bytes).
  static Future<String> extractTextFromPDF(Uint8List fileBytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: fileBytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      // Rethrow so caller can show an error/snackbar
      rethrow;
    }
  }
}
